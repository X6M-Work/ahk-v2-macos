"""Dependency-free, noninteractive AHK v2 corpus runner."""

from __future__ import annotations

import ctypes
import hashlib
import json
import math
import os
from pathlib import Path
import platform
import signal
import subprocess
import sys
import tempfile
import time


SCHEMA_VERSION = 1
STATUSES = {"pass", "fail", "timeout", "unsupported"}


def executable_identity(executable: Path) -> dict:
    root = executable.parent
    if root.name == "MacOS" and root.parent.name == "Contents":
        root = root.parent
    assemblies = {path.relative_to(root).as_posix(): sha256(path.read_bytes())
                  for path in sorted(root.rglob("Keysharp*.dll")) if path.is_file()}
    return {"executable_sha256": sha256(executable.read_bytes()),
            "managed_assemblies_sha256": assemblies}


def normalize_output(value: bytes) -> str:
    return value.decode("utf-8", errors="backslashreplace").replace("\r\n", "\n")


def valid_utf8(value: bytes) -> bool:
    try:
        value.decode("utf-8")
        return True
    except UnicodeDecodeError:
        return False


class WindowsJob:
    """Assign the suspended child before resuming so descendants cannot escape."""

    def __init__(self):
        from ctypes import wintypes

        class BasicLimit(ctypes.Structure):
            _fields_ = [("PerProcessUserTimeLimit", ctypes.c_int64),
                        ("PerJobUserTimeLimit", ctypes.c_int64),
                        ("LimitFlags", wintypes.DWORD),
                        ("MinimumWorkingSetSize", ctypes.c_size_t),
                        ("MaximumWorkingSetSize", ctypes.c_size_t),
                        ("ActiveProcessLimit", wintypes.DWORD),
                        ("Affinity", ctypes.c_size_t),
                        ("PriorityClass", wintypes.DWORD),
                        ("SchedulingClass", wintypes.DWORD)]

        class IoCounters(ctypes.Structure):
            _fields_ = [(name, ctypes.c_uint64) for name in
                        ("ReadOperationCount", "WriteOperationCount", "OtherOperationCount",
                         "ReadTransferCount", "WriteTransferCount", "OtherTransferCount")]

        class ExtendedLimit(ctypes.Structure):
            _fields_ = [("BasicLimitInformation", BasicLimit), ("IoInfo", IoCounters),
                        ("ProcessMemoryLimit", ctypes.c_size_t),
                        ("JobMemoryLimit", ctypes.c_size_t),
                        ("PeakProcessMemoryUsed", ctypes.c_size_t),
                        ("PeakJobMemoryUsed", ctypes.c_size_t)]

        self.api = ctypes.WinDLL("kernel32", use_last_error=True)
        self.api.CreateJobObjectW.argtypes = [ctypes.c_void_p, wintypes.LPCWSTR]
        self.api.CreateJobObjectW.restype = wintypes.HANDLE
        self.api.SetInformationJobObject.argtypes = [wintypes.HANDLE, ctypes.c_int,
                                                    ctypes.c_void_p, wintypes.DWORD]
        self.api.SetInformationJobObject.restype = wintypes.BOOL
        self.api.AssignProcessToJobObject.argtypes = [wintypes.HANDLE, wintypes.HANDLE]
        self.api.AssignProcessToJobObject.restype = wintypes.BOOL
        self.api.CloseHandle.argtypes = [wintypes.HANDLE]
        self.api.CloseHandle.restype = wintypes.BOOL
        self.handle = self.api.CreateJobObjectW(None, None)
        if not self.handle:
            raise ctypes.WinError(ctypes.get_last_error())
        limits = ExtendedLimit()
        limits.BasicLimitInformation.LimitFlags = 0x2000  # JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
        if not self.api.SetInformationJobObject(self.handle, 9, ctypes.byref(limits),
                                                ctypes.sizeof(limits)):
            error = ctypes.get_last_error()
            self.close()
            raise ctypes.WinError(error)

    def assign_and_resume(self, process):
        from ctypes import wintypes

        if not self.api.AssignProcessToJobObject(self.handle, int(process._handle)):
            raise ctypes.WinError(ctypes.get_last_error())

        class ThreadEntry(ctypes.Structure):
            _fields_ = [("dwSize", wintypes.DWORD), ("cntUsage", wintypes.DWORD),
                        ("th32ThreadID", wintypes.DWORD), ("th32OwnerProcessID", wintypes.DWORD),
                        ("tpBasePri", wintypes.LONG), ("tpDeltaPri", wintypes.LONG),
                        ("dwFlags", wintypes.DWORD)]

        self.api.CreateToolhelp32Snapshot.argtypes = [wintypes.DWORD, wintypes.DWORD]
        self.api.CreateToolhelp32Snapshot.restype = wintypes.HANDLE
        self.api.Thread32First.argtypes = [wintypes.HANDLE, ctypes.POINTER(ThreadEntry)]
        self.api.Thread32First.restype = wintypes.BOOL
        self.api.Thread32Next.argtypes = [wintypes.HANDLE, ctypes.POINTER(ThreadEntry)]
        self.api.Thread32Next.restype = wintypes.BOOL
        self.api.OpenThread.argtypes = [wintypes.DWORD, wintypes.BOOL, wintypes.DWORD]
        self.api.OpenThread.restype = wintypes.HANDLE
        self.api.ResumeThread.argtypes = [wintypes.HANDLE]
        self.api.ResumeThread.restype = wintypes.DWORD
        snapshot = self.api.CreateToolhelp32Snapshot(4, 0)
        if snapshot == ctypes.c_void_p(-1).value:
            raise ctypes.WinError(ctypes.get_last_error())
        try:
            entry = ThreadEntry()
            entry.dwSize = ctypes.sizeof(entry)
            found = self.api.Thread32First(snapshot, ctypes.byref(entry))
            while found:
                if entry.th32OwnerProcessID == process.pid:
                    thread = self.api.OpenThread(2, False, entry.th32ThreadID)
                    if not thread:
                        raise ctypes.WinError(ctypes.get_last_error())
                    try:
                        if self.api.ResumeThread(thread) == 0xFFFFFFFF:
                            raise ctypes.WinError(ctypes.get_last_error())
                        return
                    finally:
                        self.api.CloseHandle(thread)
                found = self.api.Thread32Next(snapshot, ctypes.byref(entry))
            raise OSError("Suspended child thread was not found")
        finally:
            self.api.CloseHandle(snapshot)

    def close(self):
        if self.handle:
            self.api.CloseHandle(self.handle)
            self.handle = None


def execute(command: list[str], cwd: Path, timeout: float) -> dict:
    if not math.isfinite(timeout) or timeout <= 0:
        raise ValueError("timeout must be finite and positive")
    started = time.monotonic()
    job = None
    process = None
    timed_out = False
    env = dict(os.environ, KEYSHARP_DAEMON="0")
    try:
        if os.name == "nt":
            job = WindowsJob()
            process = subprocess.Popen(command, cwd=cwd, env=env, stdin=subprocess.DEVNULL,
                                       stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                       creationflags=0x00000004 | 0x08000000)
            job.assign_and_resume(process)
        else:
            process = subprocess.Popen(command, cwd=cwd, env=env, stdin=subprocess.DEVNULL,
                                       stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                       start_new_session=True)
        try:
            stdout, stderr = process.communicate(timeout=timeout)
        except subprocess.TimeoutExpired:
            timed_out = True
            if job:
                job.close()
            else:
                os.killpg(process.pid, signal.SIGKILL)
            stdout, stderr = process.communicate(timeout=5)
        return {"stdout": normalize_output(stdout), "stderr": normalize_output(stderr),
                "exit_code": process.returncode, "timed_out": timed_out,
                "encoding_errors": not (valid_utf8(stdout) and valid_utf8(stderr)),
                "duration_ms": round((time.monotonic() - started) * 1000)}
    finally:
        if job:
            job.close()
        if process:
            if os.name != "nt":
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
            if process.poll() is None:
                process.kill()
            process.wait()


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def load_corpus(directory: Path) -> tuple[list[dict], str]:
    manifest_path = directory / "manifest.json"
    manifest_bytes = manifest_path.read_bytes()
    manifest = json.loads(manifest_bytes)
    if not isinstance(manifest, dict) or manifest.get("schema_version") != SCHEMA_VERSION:
        raise ValueError("unsupported corpus schema_version")
    cases = manifest.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("corpus must contain at least one case")
    ids = set()
    loaded = []
    for case in cases:
        case = dict(case)
        case_id = case.get("id")
        if not isinstance(case_id, str) or not case_id or case_id in ids:
            raise ValueError("case ids must be nonempty and unique")
        ids.add(case_id)
        for name in ("script", "expected_stdout"):
            path = (directory / case[name]).resolve()
            if not path.is_relative_to(directory.resolve()):
                raise ValueError(f"{case_id}: {name} escapes corpus")
            case[name + "_bytes"] = path.read_bytes()
        source = case["script_bytes"].decode("utf-8")
        directives = {line.strip().casefold() for line in source.splitlines()}
        if not {"#errorstdout", "#warn all, stdout", "#requires autohotkey v2.0"} <= directives:
            raise ValueError(f"{case_id}: required safety/version directives are missing")
        case["source_sha256"] = sha256(case["script_bytes"])
        case["expected_sha256"] = sha256(case["expected_stdout_bytes"])
        loaded.append(case)
    loaded.sort(key=lambda case: case["id"])
    fingerprint = {"manifest": sha256(manifest_bytes), "cases": [
        [case["id"], case["source_sha256"], case["expected_sha256"]] for case in loaded]}
    return loaded, sha256(json.dumps(fingerprint, sort_keys=True).encode("utf-8"))


def build_command(engine: str, executable: Path, script: Path, host: str = "dotnet") -> list[str]:
    command = [str(executable)]
    if executable.suffix.casefold() == ".dll":
        command.insert(0, host)
    if engine == "ahk":
        command += ["/ErrorStdOut=UTF-8", "/CP65001"]
    elif engine == "keysharp":
        command += ["--errorstdout=UTF-8"]
    else:
        raise ValueError(f"unknown engine: {engine}")
    return command + [str(script)]


def classify(result: dict, expected: str) -> tuple[str, list[str]]:
    if result["timed_out"]:
        return "timeout", ["process_timeout"]
    reasons = []
    if result["exit_code"] != 0:
        reasons.append("nonzero_exit")
    if result["stderr"]:
        reasons.append("stderr_not_empty")
    if result.get("encoding_errors"):
        reasons.append("invalid_utf8_output")
    if result["stdout"] != expected:
        reasons.append("stdout_mismatch")
    return ("fail", reasons) if reasons else ("pass", [])


def run_corpus(directory: Path, engine: str, executable: Path, timeout: float,
               selected: list[str] | None = None, host: str = "dotnet",
               engine_version: str | None = None) -> dict:
    cases, corpus_sha256 = load_corpus(directory)
    if selected:
        missing = set(selected) - {case["id"] for case in cases}
        if missing:
            raise ValueError("unknown cases: " + ", ".join(sorted(missing)))
        cases = [case for case in cases if case["id"] in selected]
    results = []
    system = platform.system()
    for case in cases:
        expected = normalize_output(case["expected_stdout_bytes"])
        result = {"id": case["id"], "category": case["category"], "script": case["script"],
                  "source_sha256": case["source_sha256"],
                  "expected_sha256": case["expected_sha256"], "expected_stdout": expected}
        unsupported = (engine == "ahk" and system != "Windows") or (
            "platforms" in case and system not in case["platforms"])
        if unsupported:
            result.update(status="unsupported", reasons=["platform_not_supported"],
                          stdout="", stderr="", exit_code=None, duration_ms=0)
        else:
            try:
                with tempfile.TemporaryDirectory(prefix="ahk-conformance-") as temporary:
                    cwd = Path(temporary)
                    script = cwd / Path(case["script"]).name
                    script.write_bytes(case["script_bytes"])
                    execution = execute(build_command(engine, executable, script, host), cwd, timeout)
                status, reasons = classify(execution, expected)
                execution.pop("timed_out")
                result.update(execution, status=status, reasons=reasons)
            except OSError as error:
                result.update(status="fail", reasons=["process_launch_error"], stdout="",
                              stderr=str(error), exit_code=None, duration_ms=0)
        results.append(result)
    return {"schema_version": SCHEMA_VERSION, "corpus_sha256": corpus_sha256,
            "normalization": "UTF-8 with invalid bytes escaped; CRLF to LF only",
            "scope": "Only the selected corpus; no claim of general AHK compatibility",
            "engine": {"name": engine, "executable": str(executable),
                       **executable_identity(executable),
                       "version": engine_version},
            "host": {"os": system, "release": platform.release(),
                     "architecture": platform.machine(), "python": platform.python_version()},
            "timeout_seconds": timeout, "cases": results,
            "summary": {status: sum(case["status"] == status for case in results)
                        for status in sorted(STATUSES)}}


def validate_report(report: dict) -> dict[str, dict]:
    if not isinstance(report, dict) or report.get("schema_version") != SCHEMA_VERSION:
        raise ValueError("unsupported report schema_version")
    if not isinstance(report.get("corpus_sha256"), str) or not report["corpus_sha256"]:
        raise ValueError("report requires corpus_sha256")
    if not isinstance(report.get("cases"), list) or not report["cases"]:
        raise ValueError("report must contain at least one case")
    cases = {}
    for case in report["cases"]:
        if not isinstance(case, dict):
            raise ValueError("report cases must be objects")
        case_id = case.get("id")
        if not isinstance(case_id, str) or not case_id or case_id in cases:
            raise ValueError("report case ids must be nonempty and unique")
        if case.get("status") not in STATUSES:
            raise ValueError(f"{case_id}: invalid status")
        for key in ("stdout", "stderr", "expected_stdout", "source_sha256", "expected_sha256"):
            if not isinstance(case.get(key), str):
                raise ValueError(f"{case_id}: missing or invalid {key}")
        cases[case_id] = case
    return cases


def compare_reports(baseline: dict, candidate: dict) -> dict:
    left, right = validate_report(baseline), validate_report(candidate)
    differences = []
    if baseline["corpus_sha256"] != candidate["corpus_sha256"]:
        differences.append({"kind": "corpus_changed"})
    for case_id in sorted(left.keys() | right.keys()):
        if case_id not in left or case_id not in right:
            differences.append({"id": case_id, "kind": "missing_from_baseline" if case_id not in left
                                else "missing_from_candidate"})
            continue
        a, b = left[case_id], right[case_id]
        for key in ("source_sha256", "expected_sha256", "expected_stdout", "stdout", "stderr", "status"):
            if a[key] != b[key]:
                differences.append({"id": case_id, "kind": key + "_mismatch",
                                    "baseline": a[key], "candidate": b[key]})
        for label, value in (("baseline", a), ("candidate", b)):
            if (value["status"] != "pass" or value.get("exit_code") != 0
                    or value["stdout"] != value["expected_stdout"] or value["stderr"]):
                differences.append({"id": case_id, "kind": label + "_not_passing"})
    return {"equal": not differences, "compared_cases": len(left.keys() & right.keys()),
            "differences": differences}


def write_json(path: Path, value: dict):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
                    encoding="utf-8", newline="\n")
