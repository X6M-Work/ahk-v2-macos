import argparse
import json
from pathlib import Path
import sys

from runner import compare_reports, write_json


def main(argv=None):
    parser = argparse.ArgumentParser(description="Compare complete conformance reports.")
    parser.add_argument("baseline", type=Path)
    parser.add_argument("candidate", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args(argv)
    try:
        result = compare_reports(json.loads(args.baseline.read_text(encoding="utf-8")),
                                 json.loads(args.candidate.read_text(encoding="utf-8")))
        if args.output:
            write_json(args.output, result)
    except (OSError, ValueError, KeyError, TypeError) as error:
        parser.error(str(error))
    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    return int(not result["equal"])


if __name__ == "__main__":
    sys.exit(main())
