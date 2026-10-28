import argparse
import ctypes
import json
import math
import os
from pathlib import Path
import platform
import subprocess
import sys
import tempfile
import time

DIRECTORY = Path(__file__).resolve().parent
sys.path.insert(0, str(DIRECTORY.parent))
sys.path.insert(0, str(DIRECTORY.parent / "phase15-runtime"))
from runner import build_command, executable_identity, execute, normalize_output, sha256, write_json
from run_processes import compare_reports, validate_report


def process_alive(pid):
    if os.name != "nt":
        try:
            os.kill(pid, 0)
            return True
        except ProcessLookupError:
            return False
    from ctypes import wintypes
    api = ctypes.WinDLL("kernel32", use_last_error=True)
    api.OpenProcess.argtypes = [wintypes.DWORD, wintypes.BOOL, wintypes.DWORD]
    api.OpenProcess.restype = wintypes.HANDLE
    api.WaitForSingleObject.argtypes = [wintypes.HANDLE, wintypes.DWORD]
    api.WaitForSingleObject.restype = wintypes.DWORD
    api.CloseHandle.argtypes = [wintypes.HANDLE]
    api.CloseHandle.restype = wintypes.BOOL
    handle = api.OpenProcess(0x100000, False, pid)
    if not handle:
        if ctypes.get_last_error() == 5:
            raise PermissionError("Cannot inspect replacement process")
        return False
    try:
        status = api.WaitForSingleObject(handle, 0)
        if status not in (0, 0x102):
            raise OSError("Cannot inspect replacement process state")
        return status == 0x102
    finally:
        api.CloseHandle(handle)


def failure_diagnostics(process, directory=Path('.')):
    details = [f'Initial worker status: {process.poll()}']
    try:
        stdout, stderr = process.communicate(timeout=0.2)
    except subprocess.TimeoutExpired as error:
        stdout, stderr = error.output or b'', error.stderr or b''
    except OSError as error:
        stdout, stderr = b'', str(error).encode('utf-8')
    for name, data in [('worker stdout', stdout), ('worker stderr', stderr)]:
        if data:
            details.append(name + ':\n' + normalize_output(data))
    for name in ('trace.txt', 'predecessor.txt', 'done.txt', 'failed.txt'):
        path = directory / name
        if path.is_file():
            details.append(name + ':\n' + normalize_output(path.read_bytes()))
    return '\n'.join(details)


def controller(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument("--engine", required=True, choices=("ahk", "keysharp"))
    parser.add_argument("--executable", required=True, type=Path)
    parser.add_argument("--script", required=True, type=Path)
    parser.add_argument("--timeout", required=True, type=float)
    parser.add_argument("--dotnet", default="dotnet")
    args = parser.parse_args(argv)
    process = subprocess.Popen(build_command(args.engine, args.executable, args.script, args.dotnet),
                               stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                               creationflags=0x08000000 if os.name == "nt" else 0)
    deadline = time.monotonic() + args.timeout
    final_pid = None
    try:
        while time.monotonic() < deadline:
            if Path("failed.txt").exists():
                raise RuntimeError("Reload worker error: " + Path("failed.txt").read_text(encoding="utf-8"))
            if Path("done.txt").exists():
                try:
                    final_pid = int(Path("done.txt").read_text(encoding="utf-8"))
                except ValueError:
                    pass
                if final_pid and final_pid > 0:
                    break
            if process.poll() not in (None, 0):
                stdout, stderr = process.communicate(timeout=1)
                raise RuntimeError("Initial worker failed: " + normalize_output(stdout + stderr))
            time.sleep(0.02)
        if not final_pid:
            raise TimeoutError("Reload completion marker missing")
        while process_alive(final_pid) and time.monotonic() < deadline:
            time.sleep(0.02)
        if process_alive(final_pid):
            raise TimeoutError("Replacement process did not exit")
        stdout, stderr = process.communicate(timeout=max(0.1, deadline - time.monotonic()))
        if process.returncode != 0 or stdout or stderr:
            raise RuntimeError("Unexpected worker process result: " + normalize_output(stdout + stderr))
        sys.stdout.buffer.write(Path("trace.txt").read_bytes())
        return 0
    except (OSError, RuntimeError, ValueError, subprocess.TimeoutExpired) as error:
        print(str(error), file=sys.stderr, flush=True)
        print(failure_diagnostics(process), file=sys.stderr, flush=True)
        return 1
    finally:
        if process.poll() is None:
            process.terminate()
        try:
            process.wait(timeout=2)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=2)
        process.stdout.close()
        process.stderr.close()


def main():
    parser = argparse.ArgumentParser(description="Contained self-Reload process and timer lifecycle gate.")
    parser.add_argument("--engine", required=True, choices=("ahk", "keysharp"))
    parser.add_argument("--executable", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--baseline", type=Path)
    parser.add_argument("--timeout", type=float, default=30)
    parser.add_argument("--dotnet", default="dotnet")
    args = parser.parse_args()
    if not math.isfinite(args.timeout) or args.timeout <= 0:
        parser.error("--timeout must be finite and positive")
    if args.baseline and args.output.resolve() == args.baseline.resolve():
        parser.error("--output must differ from --baseline")
    executable = args.executable.resolve()
    if not executable.is_file():
        parser.error("--executable must exist")
    if args.engine == "ahk" and platform.system() != "Windows":
        parser.error("official AutoHotkey requires Windows")
    baseline = None
    if args.baseline:
        try:
            baseline = json.loads(args.baseline.read_text(encoding="utf-8"))
            validate_report(baseline)
        except (OSError, ValueError, TypeError) as error:
            parser.error(str(error))
    source = (DIRECTORY / "reload-timer.ahk").read_bytes()
    expected = {"stdout": (DIRECTORY / "golden/reload-timer.txt").read_text(encoding="utf-8"), "stderr": "", "exit_code": 0}
    temporary = tempfile.TemporaryDirectory(prefix="ahk-reload-")
    try:
        cwd = Path(temporary.name)
        script = cwd / "reload-timer.ahk"
        script.write_bytes(source)
        command = [sys.executable, str(Path(__file__).resolve()), "--controller", "--engine", args.engine,
                   "--executable", str(executable), "--script", str(script), "--dotnet", args.dotnet,
                   "--timeout", str(max(0.1, args.timeout - 3))]
        actual = execute(command, cwd, args.timeout)
    finally:
        for attempt in range(30):
            try:
                temporary.cleanup()
                break
            except OSError:
                if attempt == 29:
                    raise
                time.sleep(0.05)
    success = not actual["timed_out"] and not actual["encoding_errors"] and all(actual[key] == value for key, value in expected.items())
    case = {"id": "reload-timer", "source_sha256": sha256(source), "expected": expected,
            "actual": actual, "status": "pass" if success else "fail"}
    report = {"schema_version": 1, "scope": "Isolated self-Reload, OnExit and timer replacement; no macOS claim",
              "host": {"os": platform.system(), "architecture": platform.machine()},
              "engine": {"name": args.engine, "executable": str(executable), **executable_identity(executable)},
              "timeout_seconds": args.timeout, "cases": [case], "summary": {"pass": int(success), "fail": int(not success)}}
    if baseline is not None:
        report["baseline_equal"] = compare_reports(baseline, report)
    write_json(args.output, report)
    print(f"{args.engine}: {report['summary']}; report={args.output}")
    return int(not success or not report.get("baseline_equal", True))


if __name__ == "__main__":
    sys.exit(controller(sys.argv[2:]) if len(sys.argv) > 1 and sys.argv[1] == "--controller" else main())
