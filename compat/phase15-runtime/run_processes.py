import argparse
import json
import math
from pathlib import Path
import platform
import sys
import tempfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from runner import build_command, executable_identity, execute, sha256, write_json


CASES = (
    ("process-exit-code", "exit:Exit:17\n", "", 17),
    ("process-error-handler", "", "trapped:Error:phase15-error\n", 23),
    ("process-error-continue", "continued:1\n", "", 0),
)


def validate_report(report):
    if not isinstance(report, dict) or report.get("schema_version") != 1:
        raise ValueError("unsupported lifecycle report schema_version")
    values = report.get("cases")
    if not isinstance(values, list) or not values:
        raise ValueError("lifecycle report requires nonempty cases")
    result = {}
    for case in values:
        if not isinstance(case, dict):
            raise ValueError("lifecycle cases must be objects")
        name = case.get("id")
        if not isinstance(name, str) or not name or name in result:
            raise ValueError("lifecycle case ids must be nonempty and unique")
        if case.get("status") not in ("pass", "fail"):
            raise ValueError(f"{name}: invalid lifecycle status")
        fingerprint = case.get("source_sha256")
        if not isinstance(fingerprint, str) or len(fingerprint) != 64 or any(char not in "0123456789abcdef" for char in fingerprint):
            raise ValueError(f"{name}: invalid source_sha256")
        for label in ("expected", "actual"):
            value = case.get(label)
            if not isinstance(value, dict) or not all(isinstance(value.get(key), str) for key in ("stdout", "stderr")) or type(value.get("exit_code")) is not int:
                raise ValueError(f"{name}: invalid {label}")
        if not all(type(case["actual"].get(key)) is bool for key in ("timed_out", "encoding_errors")):
            raise ValueError(f"{name}: missing timeout or encoding state")
        result[name] = case
    return result


def passing(case):
    actual = case["actual"]
    return (case["status"] == "pass" and not actual["timed_out"] and not actual["encoding_errors"]
            and all(actual[key] == case["expected"][key] for key in ("stdout", "stderr", "exit_code")))


def compare_reports(baseline, candidate):
    left, right = validate_report(baseline), validate_report(candidate)
    return bool(left) and set(left) == set(right) and all(
        left[name]["source_sha256"] == right[name]["source_sha256"]
        and left[name]["expected"] == right[name]["expected"]
        and passing(left[name]) and passing(right[name])
        and all(left[name]["actual"][key] == right[name]["actual"][key] for key in ("stdout", "stderr", "exit_code"))
        for name in left)


def main():
    parser = argparse.ArgumentParser(description="Isolated lifecycle probes with expected nonzero exits.")
    parser.add_argument("--engine", required=True, choices=("ahk", "keysharp"))
    parser.add_argument("--executable", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--baseline", type=Path)
    parser.add_argument("--timeout", type=float, default=20)
    parser.add_argument("--dotnet", default="dotnet")
    args = parser.parse_args()
    if not math.isfinite(args.timeout) or args.timeout <= 0:
        parser.error("--timeout must be finite and positive")
    if args.baseline and args.output.resolve() == args.baseline.resolve():
        parser.error("--output must differ from --baseline")
    if args.engine == "ahk" and platform.system() != "Windows":
        parser.error("official AutoHotkey requires Windows")
    executable = args.executable.resolve()
    if not executable.is_file():
        parser.error("--executable must exist")
    baseline = None
    if args.baseline:
        try:
            baseline = json.loads(args.baseline.read_text(encoding="utf-8"))
            validate_report(baseline)
        except (OSError, ValueError, TypeError) as error:
            parser.error(str(error))
    results = []
    for name, stdout, stderr, code in CASES:
        source = Path(__file__).with_name(name + ".ahk").read_bytes()
        with tempfile.TemporaryDirectory(prefix="ahk-lifecycle-") as temporary:
            cwd = Path(temporary)
            script = cwd / (name + ".ahk")
            script.write_bytes(source)
            actual = execute(build_command(args.engine, executable, script, args.dotnet), cwd, args.timeout)
        expected = {"stdout": stdout, "stderr": stderr, "exit_code": code}
        success = not actual["timed_out"] and not actual["encoding_errors"] and all(actual[key] == value for key, value in expected.items())
        results.append({"id": name, "source_sha256": sha256(source), "expected": expected,
                        "actual": actual, "status": "pass" if success else "fail"})
    report = {"schema_version": 1, "scope": "Lifecycle process probes; not a macOS validation",
              "host": {"os": platform.system(), "architecture": platform.machine()},
              "engine": {"name": args.engine, "executable": str(executable), **executable_identity(executable)},
              "cases": results, "summary": {"pass": sum(item["status"] == "pass" for item in results), "fail": sum(item["status"] != "pass" for item in results)}}
    if baseline is not None:
        report["baseline_equal"] = compare_reports(baseline, report)
    write_json(args.output, report)
    print(f"{args.engine}: {report['summary']}; report={args.output}")
    return int(report["summary"]["fail"] > 0 or not report.get("baseline_equal", True))


if __name__ == "__main__":
    sys.exit(main())
