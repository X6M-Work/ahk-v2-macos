from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


class SuiteSafetyTests(unittest.TestCase):
    def test_output_alias_cannot_overwrite_reference(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            reference = root / "corpus.json"
            reference.write_bytes(b"reference")
            command = [sys.executable, str(Path(__file__).resolve().parents[1] / "suite.py"),
                       "--engine", "keysharp", "--executable", sys.executable,
                       "--output-dir", str(root / "child" / ".."), "--baseline-dir", str(root)]
            result = subprocess.run(command, capture_output=True, timeout=10)
            self.assertEqual(result.returncode, 2)
            self.assertIn(b"reference and output directories must differ", result.stderr)
            self.assertEqual(reference.read_bytes(), b"reference")
            self.assertEqual(list(root.iterdir()), [reference])
