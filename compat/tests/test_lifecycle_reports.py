import contextlib
import copy
import importlib.util
import io
from pathlib import Path
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("lifecycle_probes", Path(__file__).resolve().parents[1] / "phase15-runtime" / "run_processes.py")
lifecycle = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lifecycle)


def report():
    expected = {"stdout": "exit:Exit:17\n", "stderr": "", "exit_code": 17}
    actual = dict(expected, timed_out=False, encoding_errors=False)
    return {"schema_version": 1, "cases": [{"id": "exit", "source_sha256": "0" * 64,
                                             "status": "pass", "expected": expected, "actual": actual}]}


class LifecycleReportTests(unittest.TestCase):
    def test_matching_success(self):
        self.assertTrue(lifecycle.compare_reports(report(), report()))

    def test_failure_never_matches(self):
        for key, value in (("timed_out", True), ("encoding_errors", True), ("exit_code", 0), ("stdout", ""), ("stderr", "error")):
            candidate = report()
            candidate["cases"][0]["actual"][key] = value
            self.assertFalse(lifecycle.compare_reports(candidate, copy.deepcopy(candidate)), key)

    def test_changed_contract(self):
        candidate = report()
        candidate["cases"][0]["expected"]["exit_code"] = 0
        candidate["cases"][0]["actual"]["exit_code"] = 0
        self.assertFalse(lifecycle.compare_reports(report(), candidate))

    def test_changed_source_and_case_sets(self):
        candidate = report()
        candidate["cases"][0]["source_sha256"] = "1" * 64
        self.assertFalse(lifecycle.compare_reports(report(), candidate))
        candidate = report()
        candidate["cases"][0]["id"] = "other"
        self.assertFalse(lifecycle.compare_reports(report(), candidate))

    def test_malformed_baselines(self):
        duplicate = report()
        duplicate["cases"].append(copy.deepcopy(duplicate["cases"][0]))
        invalid_code = report()
        invalid_code["cases"][0]["actual"]["exit_code"] = True
        for candidate in ({}, {"schema_version": 1, "cases": []}, {"schema_version": 1, "cases": [None]}, duplicate, invalid_code):
            with self.subTest(candidate=candidate), self.assertRaises(ValueError):
                lifecycle.validate_report(candidate)

    def test_invalid_timeout_never_launches(self):
        for timeout in ("nan", "inf", "0", "-1"):
            argv = ["probes", "--engine", "keysharp", "--executable", "unused", "--output", "unused", "--timeout", timeout]
            with self.subTest(timeout=timeout), patch("sys.argv", argv), patch.object(lifecycle, "execute") as execute, contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit) as raised:
                lifecycle.main()
            self.assertEqual(raised.exception.code, 2)
            execute.assert_not_called()

    def test_reference_cannot_be_overwritten(self):
        argv = ["probes", "--engine", "keysharp", "--executable", "unused", "--output", "same.json", "--baseline", "same.json"]
        with patch("sys.argv", argv), patch.object(lifecycle, "execute") as execute, contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit) as raised:
            lifecycle.main()
        self.assertEqual(raised.exception.code, 2)
        execute.assert_not_called()


if __name__ == "__main__":
    unittest.main()
