import argparse
import json
import math
from pathlib import Path
import subprocess
import sys

from runner import compare_reports, run_corpus, write_json


CORPORA = ("corpus", "phase15-symbols", "phase15-map-conversions", "phase15-enumerators", "phase15-stdlib", "phase15-regex-edge", "phase15-native-windows",
           "phase15-runtime", "phase15-architecture")


def main():
    parser = argparse.ArgumentParser(description="Run all local phase 1–5 conformance gates sequentially.")
    parser.add_argument("--engine", required=True, choices=("ahk", "keysharp"))
    parser.add_argument("--executable", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument("--baseline-dir", type=Path)
    parser.add_argument("--timeout", type=float, default=60)
    parser.add_argument("--dotnet", default="dotnet")
    parser.add_argument("--engine-version")
    args = parser.parse_args()
    if not math.isfinite(args.timeout) or args.timeout <= 0:
        parser.error("--timeout must be finite and positive")
    executable = args.executable.resolve()
    if not executable.is_file():
        parser.error("--executable must name an existing file")
    args.output_dir = args.output_dir.resolve()
    if args.baseline_dir:
        args.baseline_dir = args.baseline_dir.resolve()
        if args.output_dir == args.baseline_dir:
            parser.error("reference and output directories must differ")
    directory = Path(__file__).resolve().parent
    args.output_dir.mkdir(parents=True, exist_ok=True)
    summary = []
    for name in CORPORA:
        try:
            report = run_corpus(directory / name, args.engine, executable, args.timeout,
                                host=args.dotnet, engine_version=args.engine_version)
            if args.baseline_dir:
                baseline = json.loads((args.baseline_dir / (name + ".json")).read_text(encoding="utf-8"))
                report["comparison"] = compare_reports(baseline, report)
            write_json(args.output_dir / (name + ".json"), report)
            success = all(case["status"] == "pass" for case in report["cases"]) and report.get("comparison", {"equal": True})["equal"]
            summary.append({"corpus": name, "passed": success, "results": report["summary"]})
            print(f"{name}: {report['summary']}", flush=True)
        except (OSError, ValueError, KeyError, TypeError) as error:
            summary.append({"corpus": name, "passed": False, "error": str(error)})
            print(f"{name}: {error}", file=sys.stderr, flush=True)
    for name, script in (("processes", "phase15-runtime/run_processes.py"),
                         ("reload", "phase15-reload/run_reload.py")):
        command = [sys.executable, str(directory / script), "--engine", args.engine,
                   "--executable", str(executable), "--dotnet", args.dotnet,
                   "--timeout", str(args.timeout), "--output", str(args.output_dir / (name + ".json"))]
        if args.baseline_dir:
            command += ["--baseline", str(args.baseline_dir / (name + ".json"))]
        process = subprocess.run(command, check=False)
        summary.append({"corpus": name, "passed": process.returncode == 0, "exit_code": process.returncode})
    passed = all(result["passed"] for result in summary)
    write_json(args.output_dir / "suite.json", {"schema_version": 1, "passed": passed, "gates": summary})
    return int(not passed)


if __name__ == "__main__":
    sys.exit(main())
