# Local validation record

2026-10-25 — Windows 11 x64, Python 3.13.5, .NET SDK 10.0.402. Reference: official AutoHotkey 2.0.31, provenance in UPSTREAM.lock.json.

| Check | Executed result |
|---|---|
| Debug solution build | Passed, zero warnings/errors |
| Python harness/lifecycle tests | 34 passed |
| Official AHK reference | 61/61 passed |
| Rebuilt Keysharp comparison | 56/61 passed; five failures retained |
| NUnit selected tests | 132 distinct tests verified: 131 passed in the final selection, then NumPutNumGet passed after its version-specific expectations were clarified |
| Native macOS | Not executed; four ABI prototypes remain unsupported on Windows |
| GitHub Actions | Not executed in this local validation snapshot |

| Candidate corpus | Passing cases |
|---|---|
| corpus | 14/14 |
| phase15-symbols | 7/7 |
| phase15-map-conversions | 6/6 |
| phase15-enumerators | 9/9 |
| phase15-stdlib | 6/6 |
| phase15-regex-edge | 1/1 |
| phase15-native-windows | 1/1 |
| phase15-runtime | 8/8 |
| phase15-architecture | 0/5 |
| processes | 3/3 |
| reload | 1/1 |

The five differential failures are alias release, scope release, temporary release, resurrection and automatic file close. The complete suite returns nonzero. The rebuilt assembly hashes match every delivered candidate report. See architecture-phase15.md for the required ownership migration.

The regex edge fixture now passes 28 escape/context observations. Nine enumeration fixtures cover metadata, arity, invalid references, binding and getters. IsTime rejects years before 1601. Native Float return/output widening and self-Reload are verified on Windows. These cases do not establish exhaustive PCRE, ABI or AHK compatibility.

NUnit covers Parser, Collections, Types, String and FileAndDir, plus MiscIs, FlowEnum and NumPutNumGet, excluding RequiresHook. Existing extension expectations remain under explicit v2.1 scopes; strict v2.0 expectations were retained or corrected from the official reference. The last native-memory fixture expected shortest-decimal Float widening and full type-name matching; it now tests exact v2.0 results and retains the old behavior in a v2.1 function. No runtime behavior was relaxed to make a test pass. The unfiltered suite was not run.

The visible AHK dialog was a test error: ObjOwnPropCount(o) replaces o.OwnPropCount. Standalone fixtures install OnError handlers that print stderr and exit. ErrorStdOut alone does not suppress every official AHK runtime dialog. Reload uses a contained Python controller, bounded waits and real process-exit checks; noninteractive Keysharp reload refuses a blocked predecessor without prompting.

String-pointer probes write a NUL terminator. Bytes beyond a cleared string's initial NUL are unspecified; allocator contents are not a portable golden expectation. Logical/native capacity equivalence remains unproven.

Reports are delivered alongside the checkout in ahk-v2-macos-validation/official, windows and upstream. Sources/goldens, outputs, exit codes and managed assembly hashes are recorded. suite.json is the aggregate result. TRX files retain earlier failures and successful targeted reruns. Source-only archives exclude dependencies and ignored reports.

```powershell
python -m unittest discover -s compat/tests -q
dotnet build Keysharp.sln -c Debug -p:PublishReadyToRun=false
python compat/suite.py --engine ahk --executable C:/tools/AutoHotkey64.exe --engine-version 2.0.31 --output-dir compat/reports/official
python compat/suite.py --engine keysharp --executable bin/Debug/net10.0-windows/Keysharp.exe --output-dir compat/reports/windows --baseline-dir compat/reports/official
```

Transfer the official reports to each local Mac, then run:

```sh
bash scripts/macos/bootstrap.sh
bash scripts/macos/verify-local.sh --baseline-dir /path/to/official
```

Intel and Apple Silicon remain untested. The Windows DLL corpus is explicitly unsupported on Mac; four separate Mac ABI prototypes are pending. No permissions, GUI, hotkeys, screen capture, application control, signing or notarization have been validated here. No GitHub repository is required.

Earlier checks: pinned Eto/MonoMac bootstrap, simulated launcher architecture/version/argument/exit behavior, actionlint 1.7.12 on unchanged workflows, and exact FileAppend stdout/stderr encoding regressions. The sibling KeysharpDocs site is absent and still needs corresponding updates.
