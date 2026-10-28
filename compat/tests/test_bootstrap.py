import json
import os
from pathlib import Path
import shutil
import sys
import tempfile
import textwrap
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "compat"))
from runner import execute
BASH = (r"C:\Program Files\Git\bin\bash.exe" if os.name == "nt" else shutil.which("bash"))
if BASH and not Path(BASH).is_file():
    BASH = None

MOCK_GIT = r'''
import json
import os
from pathlib import Path
import sys
state_file = Path(os.environ['BOOTSTRAP_STATE'])
state = json.loads(state_file.read_text())
args = sys.argv[1:]
if args[0] == 'init':
    Path(args[-1], '.git').mkdir()
    sys.exit(0)
args = args[2:]
command = args[0]
if command == 'status':
    print(' M sentinel.txt' if state.get('dirty') else '', end='')
elif command == 'rev-parse':
    if state.get('head'):
        print(state['head'])
    else:
        sys.exit(1)
elif command in ('fetch', 'submodule'):
    state[command] = state.get(command, 0) + 1
    state_file.write_text(json.dumps(state))
    if state[command] <= state.get(command + '_failures', 0):
        print('SSL connection timeout', file=sys.stderr)
        sys.exit(128)
elif command == 'checkout':
    state['head'] = args[-1]
    state_file.write_text(json.dumps(state))
'''


@unittest.skipUnless(BASH, "Bash is required to exercise the bootstrap script")
class BootstrapTests(unittest.TestCase):
    def run_bootstrap(self, **initial):
        with tempfile.TemporaryDirectory(prefix="ks-bootstrap-") as directory:
            root = Path(directory)
            commands = root / "commands"
            commands.mkdir()
            handler = root / "git_mock.py"
            handler.write_text(textwrap.dedent(MOCK_GIT), encoding="utf-8")
            state = root / "state.json"
            state.write_text(json.dumps(initial), encoding="utf-8")
            wrappers = {
                "git": '#!/bin/sh\nexec "$BOOTSTRAP_PYTHON" "$BOOTSTRAP_HANDLER" "$@"\n',
                "sleep": "#!/bin/sh\nexit 0\n",
            }
            for name, content in wrappers.items():
                script = commands / name
                script.write_text(content, encoding="utf-8", newline="\n")
                script.chmod(0o755)
            env = dict(os.environ, PATH=str(commands) + os.pathsep + os.environ['PATH'],
                       BOOTSTRAP_PYTHON=Path(sys.executable).as_posix(),
                       BOOTSTRAP_HANDLER=handler.as_posix(), BOOTSTRAP_STATE=str(state))
            def bash_path(path):
                value = path.as_posix()
                return '/' + value[0].lower() + value[2:] if os.name == 'nt' else value

            command = [BASH, "-c", 'PATH="$1:$PATH"; source "$2" --eto-root "$3"',
                       "bootstrap-test", bash_path(commands),
                       bash_path(ROOT / "scripts/macos/bootstrap.sh"), bash_path(root / "Eto")]
            with patch.dict(os.environ, env):
                result = execute(command, ROOT, 20)
            return result, json.loads(state.read_text())

    def test_fetch_recovers_and_checks_out_the_pin(self):
        result, state = self.run_bootstrap(fetch_failures=2)
        self.assertEqual(result['exit_code'], 0, result['stderr'])
        self.assertEqual(state['fetch'], 3)
        pin = json.loads((ROOT / 'UPSTREAM.lock.json').read_text(encoding='utf-8-sig'))['eto']['commit']
        self.assertEqual(state['head'], pin)

    def test_failed_fetch_stops_without_checkout(self):
        result, state = self.run_bootstrap(fetch_failures=99)
        self.assertEqual(result['exit_code'], 128, result['stderr'])
        self.assertEqual(state['fetch'], 3)
        self.assertNotIn('head', state)
        self.assertNotIn('submodule', state)

    def test_submodules_retry_separately(self):
        result, state = self.run_bootstrap(submodule_failures=2)
        self.assertEqual(result['exit_code'], 0, result['stderr'])
        self.assertEqual(state['fetch'], 1)
        self.assertEqual(state['submodule'], 3)

    def test_dirty_tree_is_not_fetched_or_overwritten(self):
        result, state = self.run_bootstrap(dirty=True)
        self.assertNotEqual(result['exit_code'], 0)
        self.assertIn('local changes', result['stderr'])
        self.assertNotIn('fetch', state)
        self.assertNotIn('head', state)
