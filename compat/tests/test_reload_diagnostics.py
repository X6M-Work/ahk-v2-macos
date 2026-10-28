import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import Mock

spec = importlib.util.spec_from_file_location('reload_probe', Path(__file__).resolve().parents[1] / 'phase15-reload/run_reload.py')
reload_probe = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reload_probe)


class ReloadDiagnosticsTests(unittest.TestCase):
    def test_startup_errors_and_stage_trace_survive_failure(self):
        process = Mock()
        process.poll.return_value = 0
        process.communicate.return_value = (b'', b'replacement startup error\n')
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'trace.txt').write_text('first|loaded\nexit|Reload|0\n', encoding='utf-8')
            (root / 'predecessor.txt').write_text('123', encoding='utf-8')
            diagnostic = reload_probe.failure_diagnostics(process, root)
        self.assertIn('replacement startup error', diagnostic)
        self.assertIn('exit|Reload|0', diagnostic)
        self.assertIn('predecessor.txt:\n123', diagnostic)
        process.communicate.assert_called_once_with(timeout=0.2)

    def test_live_descendant_keeps_partial_output(self):
        process = Mock()
        process.poll.return_value = None
        process.communicate.side_effect = subprocess.TimeoutExpired('worker', 0.2, output=b'partial\n', stderr=b'blocked\n')
        with tempfile.TemporaryDirectory() as directory:
            diagnostic = reload_probe.failure_diagnostics(process, Path(directory))
        self.assertIn('Initial worker status: None', diagnostic)
        self.assertIn('partial', diagnostic)
        self.assertIn('blocked', diagnostic)
