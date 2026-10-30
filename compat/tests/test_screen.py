import contextlib
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import run_screen


class ScreenGateTests(unittest.TestCase):
    def test_gate_rejects_partial_output_errors_skips_and_timeouts(self):
        cases = [("pass", "", 0, False, "pass"),
                 ("fail line 1\npass", "", 0, False, "fail"),
                 ("pass", "permission denied", 0, False, "fail"),
                 ("skip", "", 0, False, "fail"),
                 ("pass", "", 137, False, "fail"),
                 ("pass", "", 0, True, "timeout")]
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "screen.json"
            for stdout, stderr, exit_code, timed_out, status in cases:
                with self.subTest(status=status, stdout=stdout, stderr=stderr, exit_code=exit_code):
                    result = dict(stdout=stdout, stderr=stderr, exit_code=exit_code,
                                  timed_out=timed_out, encoding_errors=False, duration_ms=1)
                    with patch.object(run_screen, "execute", return_value=result), \
                         patch.object(run_screen, "executable_identity", return_value={}), \
                         contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                        code = run_screen.main(["--executable", sys.executable, "--output", str(output)])
                    report = json.loads(output.read_text(encoding="utf-8"))
                    self.assertEqual(code, int(status != "pass"))
                    self.assertEqual(report["case"]["status"], status)
                    self.assertEqual(report["case"]["stdout"], stdout)
                    self.assertEqual(report["case"]["stderr"], stderr)
                    self.assertEqual(len(report["source_sha256"]), 4)

    def test_launch_failure_is_reported(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "screen.json"
            with patch.object(run_screen, "execute", side_effect=OSError("cannot launch")), \
                 patch.object(run_screen, "executable_identity", return_value={}), \
                 contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                code = run_screen.main(["--executable", sys.executable, "--output", str(output)])
            self.assertEqual(code, 1)
            self.assertEqual(json.loads(output.read_text())["case"]["reasons"], ["process_launch_error"])
