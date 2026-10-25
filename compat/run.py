import argparse
import json
import math
from pathlib import Path
import sys

from runner import compare_reports, run_corpus, write_json


def main(argv=None):
    parser = argparse.ArgumentParser(description="Run unchanged AHK v2 fixtures against one engine.")
    parser.add_argument("--engine", required=True, choices=("ahk", "keysharp"))
    parser.add_argument("--executable", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--baseline", type=Path)
    parser.add_argument("--timeout", type=float, default=20)
    parser.add_argument("--case", action="append", dest="selected")
    parser.add_argument("--corpus", type=Path, default=Path(__file__).parent / "corpus")
    parser.add_argument("--dotnet", default="dotnet", help="Host for a Keysharp .dll")
    parser.add_argument("--engine-version", help="Optional version label; executable SHA256 is always recorded")
    args = parser.parse_args(argv)
    if not math.isfinite(args.timeout) or args.timeout <= 0:
        parser.error("--timeout must be finite and positive")
    executable = args.executable.resolve()
    if not executable.is_file():
        parser.error("--executable must name an existing file")
    try:
        report = run_corpus(args.corpus.resolve(), args.engine, executable, args.timeout,
                            args.selected, args.dotnet, args.engine_version)
        if args.baseline:
            report["comparison"] = compare_reports(
                json.loads(args.baseline.read_text(encoding="utf-8")), report)
        write_json(args.output, report)
    except (OSError, ValueError, KeyError, TypeError) as error:
        parser.error(str(error))
    summary = ", ".join(f"{key}={value}" for key, value in report["summary"].items())
    print(f"{args.engine}: {summary}; report={args.output}")
    if "comparison" in report:
        print(f"baseline: {len(report['comparison']['differences'])} difference(s)")
    return int(any(case["status"] != "pass" for case in report["cases"])
               or not report.get("comparison", {"equal": True})["equal"])


if __name__ == "__main__":
    sys.exit(main())
