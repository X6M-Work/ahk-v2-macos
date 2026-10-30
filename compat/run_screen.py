"""Run the real PixelSearch fixture in the native GUI host, outside testhost."""

import argparse
import math
from pathlib import Path
import platform
import sys

from runner import build_command, classify, executable_identity, execute, sha256, write_json


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--executable", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--timeout", type=float, default=120)
    args = parser.parse_args(argv)
    if not math.isfinite(args.timeout) or args.timeout <= 0:
        parser.error("--timeout must be finite and positive")
    executable = args.executable.resolve()
    if not executable.is_file():
        parser.error("--executable must name an existing file")
    code = Path(__file__).resolve().parents[1] / "Keysharp.Tests/Code"
    script = code / "screen-pixelsearch-native.ahk"
    try:
        result = execute(build_command("keysharp", executable, script), code, args.timeout)
        status, reasons = classify(result, "pass")
        result.pop("timed_out")
    except OSError as error:
        status, reasons = "fail", ["process_launch_error"]
        result = {"stdout": "", "stderr": str(error), "exit_code": None}
    report = {
        "schema_version": 1,
        "host": {"os": platform.system(), "architecture": platform.machine()},
        "engine": {"executable": str(executable), **executable_identity(executable)},
        "source_sha256": {str(path.relative_to(code)): sha256(path.read_bytes()) for path in
                          (script, code / "screen-pixelsearch.ahk",
                           code / "Lib/screen-fixture.ahk", code / "Lib/assert.ahk")},
        "timeout_seconds": args.timeout,
        "case": {"id": "PixelSearch", "status": status, "reasons": reasons, **result},
    }
    write_json(args.output, report)
    print(f"PixelSearch: {status}; report={args.output}")
    if status != "pass":
        print(result["stdout"] + result["stderr"], file=sys.stderr)
    return int(status != "pass")


if __name__ == "__main__":
    sys.exit(main())
