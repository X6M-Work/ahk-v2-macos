import copy
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from runner import (build_command, classify, compare_reports, execute, load_corpus,
                    normalize_output, run_corpus, validate_report, executable_identity)


def report(case_id="example"):
    return {"schema_version": 1, "corpus_sha256": "corpus", "cases": [
        {"id": case_id, "status": "pass", "stdout": "value\n", "stderr": "",
         "expected_stdout": "value\n", "source_sha256": "source", "expected_sha256": "golden",
         "exit_code": 0}]}


class ProcessTests(unittest.TestCase):
    def run_python(self, source, timeout=5):
        with tempfile.TemporaryDirectory() as directory:
            return execute([sys.executable, "-c", source], Path(directory), timeout)

    def test_real_stderr_and_nonzero_are_failures(self):
        result = self.run_python("import sys; print('value'); print('problem', file=sys.stderr); sys.exit(7)")
        self.assertEqual(result["exit_code"], 7)
        status, reasons = classify(result, "value\n")
        self.assertEqual(status, "fail")
        self.assertEqual(reasons, ["nonzero_exit", "stderr_not_empty"])

    def test_stderr_alone_fails(self):
        result = self.run_python("import sys; print('value'); print('warning', file=sys.stderr)")
        self.assertEqual(classify(result, "value\n"), ("fail", ["stderr_not_empty"]))

    def test_output_must_match_exactly(self):
        result = self.run_python("print('value ')")
        self.assertEqual(classify(result, "value\n"), ("fail", ["stdout_mismatch"]))

    def test_real_timeout_preserves_partial_output(self):
        result = self.run_python("import time; print('started', flush=True); time.sleep(60)", .5)
        self.assertTrue(result["timed_out"])
        self.assertEqual(result["stdout"], "started\n")
        self.assertEqual(classify(result, "started\n"), ("timeout", ["process_timeout"]))
        self.assertLess(result["duration_ms"], 6000)

    def test_timeout_kills_descendants(self):
        with tempfile.TemporaryDirectory() as directory:
            cwd = Path(directory)
            marker = cwd / "escaped.txt"
            child = "import pathlib,time; time.sleep(1.3); pathlib.Path('escaped.txt').write_text('alive')"
            parent = ("import subprocess,sys,time; "
                      f"subprocess.Popen([sys.executable,'-c',{child!r}]); "
                      "print('spawned',flush=True); time.sleep(60)")
            result = execute([sys.executable, "-c", parent], cwd, .6)
            self.assertTrue(result["timed_out"])
            self.assertEqual(result["stdout"], "spawned\n")
            time.sleep(1.4)
            self.assertFalse(marker.exists(), "descendant survived the process timeout")

    def test_success_also_cleans_background_descendants(self):
        with tempfile.TemporaryDirectory() as directory:
            cwd = Path(directory)
            marker = cwd / "escaped.txt"
            child = "import pathlib,time; time.sleep(1); pathlib.Path('escaped.txt').write_text('alive')"
            parent = ("import subprocess,sys; "
                      f"subprocess.Popen([sys.executable,'-c',{child!r}],"
                      "stdin=subprocess.DEVNULL,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL); "
                      "print('done')")
            result = execute([sys.executable, "-c", parent], cwd, 5)
            self.assertFalse(result["timed_out"])
            self.assertEqual(result["stdout"], "done\n")
            time.sleep(1.2)
            self.assertFalse(marker.exists())

    def test_isolated_working_directory_and_daemon_disabled(self):
        with tempfile.TemporaryDirectory() as directory:
            result = execute([sys.executable, "-c",
                              "import os,pathlib; print(os.environ['KEYSHARP_DAEMON']); "
                              "pathlib.Path('local.txt').write_text('local')"], Path(directory), 5)
            self.assertEqual(result["stdout"], "0\n")
            self.assertTrue((Path(directory) / "local.txt").exists())

    def test_invalid_utf8_cannot_pass_as_literal_escape(self):
        result = self.run_python("import sys; sys.stdout.buffer.write(bytes([255]))")
        status, reasons = classify(result, "\\xff")
        self.assertEqual(status, "fail")
        self.assertIn("invalid_utf8_output", reasons)

    def test_launch_failure_is_reportable(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(OSError):
                execute([str(Path(directory) / "absent-engine")], Path(directory), 5)

    def test_bad_timeout_rejected(self):
        for value in (0, -1, float("nan"), float("inf")):
            with self.subTest(value=value), self.assertRaises(ValueError):
                self.run_python("pass", value)


class NormalizationTests(unittest.TestCase):
    def test_only_crlf_is_normalized(self):
        self.assertEqual(normalize_output(b"a\r\nb\r \n\n"), "a\nb\r \n\n")
        self.assertEqual(normalize_output(b"\xef\xbb\xbfx\t "), "\ufeffx\t ")

    def test_platform_paths_and_unicode_are_preserved(self):
        value = "C:\\Users\\example\\a.txt /Users/example/a.txt É😀"
        self.assertEqual(normalize_output(value.encode("utf-8")), value)


class ReportTests(unittest.TestCase):
    def test_managed_runtime_change_alters_identity_with_same_apphost(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            executable = root / "Keysharp.exe"
            executable.write_bytes(b"apphost")
            component = root / "components" / "scripting" / "Keysharp.Compiler.dll"
            component.parent.mkdir(parents=True)
            component.write_bytes(b"before")
            before = executable_identity(executable)
            component.write_bytes(b"after")
            after = executable_identity(executable)
            self.assertEqual(before["executable_sha256"], after["executable_sha256"])
            self.assertNotEqual(before["managed_assemblies_sha256"], after["managed_assemblies_sha256"])

    def test_equal_reports_ignore_host_engine_and_duration_metadata(self):
        left, right = report(), report()
        left["host"] = {"os": "Windows"}
        right["host"] = {"os": "Darwin"}
        right["engine"] = {"name": "keysharp"}
        right["cases"][0]["duration_ms"] = 999
        self.assertTrue(compare_reports(left, right)["equal"])

    def test_stdout_mismatch(self):
        left, right = report(), report()
        right["cases"][0]["stdout"] = "different\n"
        differences = compare_reports(left, right)["differences"]
        self.assertIn("stdout_mismatch", [item["kind"] for item in differences])
        self.assertIn("candidate_not_passing", [item["kind"] for item in differences])

    def test_equal_failure_is_not_conformance(self):
        value = report()
        value["cases"][0]["status"] = "fail"
        result = compare_reports(value, copy.deepcopy(value))
        self.assertFalse(result["equal"])
        self.assertEqual([item["kind"] for item in result["differences"]],
                         ["baseline_not_passing", "candidate_not_passing"])

    def test_missing_case_in_either_report(self):
        for reverse in (False, True):
            left, right = report(), report("other")
            if reverse:
                left, right = right, left
            kinds = {item["kind"] for item in compare_reports(left, right)["differences"]}
            self.assertEqual(kinds, {"missing_from_baseline", "missing_from_candidate"})

    def test_changed_corpus_or_source_is_rejected(self):
        left, right = report(), report()
        right["corpus_sha256"] = "changed"
        right["cases"][0]["source_sha256"] = "changed"
        kinds = {item["kind"] for item in compare_reports(left, right)["differences"]}
        self.assertEqual(kinds, {"corpus_changed", "source_sha256_mismatch"})

    def test_empty_and_missing_cases_rejected(self):
        for value in ({"schema_version": 1, "corpus_sha256": "x", "cases": []},
                      {"schema_version": 1, "corpus_sha256": "x"}, [], {}):
            with self.subTest(value=value), self.assertRaises(ValueError):
                validate_report(value)

    def test_duplicate_case_rejected(self):
        value = report()
        value["cases"] *= 2
        with self.assertRaises(ValueError):
            validate_report(value)

    def test_incomplete_case_rejected(self):
        value = report()
        del value["cases"][0]["stdout"]
        with self.assertRaises(ValueError):
            validate_report(value)

    def test_compare_cli_rejects_empty_reports(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "empty.json"
            path.write_text(json.dumps({"schema_version": 1, "corpus_sha256": "x", "cases": []}))
            result = subprocess.run([sys.executable, str(Path(__file__).parents[1] / "compare.py"),
                                     str(path), str(path)], capture_output=True, timeout=5)
            self.assertEqual(result.returncode, 2)


class CorpusTests(unittest.TestCase):
    def test_real_corpus_is_nonempty_unique_and_has_required_directives(self):
        cases, digest = load_corpus(Path(__file__).parents[1] / "corpus")
        self.assertGreaterEqual(len(cases), 12)
        self.assertEqual(len(digest), 64)
        self.assertTrue(all(case["expected_stdout_bytes"] for case in cases))

    def test_engine_commands(self):
        exe, script = Path("engine.exe"), Path("case.ahk")
        self.assertEqual(build_command("ahk", exe, script),
                         ["engine.exe", "/ErrorStdOut=UTF-8", "/CP65001", "case.ahk"])
        self.assertEqual(build_command("keysharp", Path("Keysharp.dll"), script),
                         ["dotnet", "Keysharp.dll", "--errorstdout=UTF-8", "case.ahk"])

    def test_platform_exclusion_is_explicitly_unsupported(self):
        with tempfile.TemporaryDirectory() as directory:
            corpus = Path(directory)
            (corpus / "example.ahk").write_text(
                "#ErrorStdOut\n#Warn All, StdOut\n#Requires AutoHotkey v2.0\n", encoding="utf-8")
            (corpus / "example.txt").write_text("expected\n", encoding="utf-8")
            (corpus / "manifest.json").write_text(json.dumps({"schema_version": 1, "cases": [
                {"id": "example", "category": "platform", "script": "example.ahk",
                 "expected_stdout": "example.txt", "platforms": ["ExcludedTestPlatform"]}]}))
            value = run_corpus(corpus, "keysharp", Path(sys.executable), 5)
            self.assertEqual(value["cases"][0]["status"], "unsupported")
            self.assertEqual(value["cases"][0]["exit_code"], None)
            self.assertEqual(value["summary"]["unsupported"], 1)

    def test_safety_directives_are_enforced(self):
        with tempfile.TemporaryDirectory() as directory:
            corpus = Path(directory)
            (corpus / "example.ahk").write_text('MsgBox("unsafe")', encoding="utf-8")
            (corpus / "example.txt").write_text("expected\n", encoding="utf-8")
            (corpus / "manifest.json").write_text(json.dumps({"schema_version": 1, "cases": [
                {"id": "example", "category": "safety", "script": "example.ahk",
                 "expected_stdout": "example.txt"}]}))
            with self.assertRaisesRegex(ValueError, "directives"):
                load_corpus(corpus)


if __name__ == "__main__":
    unittest.main()
