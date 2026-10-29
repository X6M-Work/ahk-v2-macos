# Local validation record

2026-10-25 — Windows 11 x64, Python 3.13.5, .NET SDK 10.0.402. Reference: official AutoHotkey 2.0.31, provenance in UPSTREAM.lock.json.

| Check | Executed result |
|---|---|
| Debug solution build | Passed, zero warnings/errors |
| Python harness/lifecycle tests | 34 passed |
| Official AHK reference | 61/61 passed |
| Rebuilt Keysharp comparison | 56/61 passed; five failures retained |
| NUnit selected tests | 132 distinct tests verified: 131 passed in the final selection, then NumPutNumGet passed after its version-specific expectations were clarified |
| Native macOS in this local Windows session | Not executed; four ABI prototypes remain unsupported on Windows |
| GitHub Actions | See the separate CI record below |

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

## GitHub Actions baseline

The [25 October run](https://github.com/X6M-Work/ahk-v2-macos/actions/runs/40222089266) was inspected on 28 October 2026. Native builds succeeded on Apple Silicon and Intel, and the initial differential corpus passed 14/14 on each architecture with zero differences against official AHK. The Windows reference and Python tooling jobs succeeded.

Each Mac NUnit run recorded 610 passed, 287 failed and 20 skipped out of 917. Of the failures, 264 parsed an absolute fixture path as source and reported `1:1: unexpected '/'`. Other failures include missing fixture files, icons and libraries, plus independent conversion and compatibility expectations. The Windows NUnit run also has 13 failures; the 287 Mac failures must not be counted as 287 distinct macOS language incompatibilities.

The test harness must locate the source checkout independently of the runtime-specific output depth. A build in `bin/Release/net10.0/osx-arm64` cannot use the same fixed three-parent traversal as a build without a runtime identifier. Regression checks cover both layouts and missing-fixture diagnostics. These harness changes do not resolve the five object-lifetime differences or validate interactive desktop automation.

## Runtime regression repair, 28 October

The [path-corrected CI run](https://github.com/X6M-Work/ahk-v2-macos/actions/runs/40713719909), commit `5c4cf6dd`, recorded 892 passed, 11 failed and 20 skipped on each Mac, and 834 passed, 13 failed and one skipped on Windows. The original 14-case corpus still passed everywhere. All remaining Mac failures also occurred on Windows.

`Hotkey` options now parse before mutation, accept adjacent options and reject invalid values atomically. The action overrides On/Off options. A new standalone fixture passed on official AHK 2.0.31 and Keysharp Windows without differences. Internal tests inspect priority, buffering, suspension exemption, thread limits, input level and callback preservation without registering input hooks.

Test expectations now distinguish v2.0 strict object conversion, canonical encoding names and exact Float32 widening from v2.1 behavior. Unicode identifiers remain distinct outside ASCII case folding, including modules and named arguments. Failed script assertions include stderr while direct runner calls retain their stdout contract and tests can still intercept expected errors.

Local final regression selection: 53 passed. Python harness: 34 passed. A broader local selection exposed five unrelated executable-generation failures caused by a hard-coded Windows SDK location; these are not macOS results. Native revalidation of the runtime repairs is pending. The sibling KeysharpDocs site is absent.

The [runtime repair CI](https://github.com/X6M-Work/ahk-v2-macos/actions/runs/40722552703), commit `68dd8bd4`, passed on both Mac architectures: 931 passed, zero failed and 20 skipped on each. The 14-case differential corpus passed without differences on Windows and both Macs. Windows NUnit recorded 874 passed, one failed and one skipped; `FlowTryInterrupt` ended with code 2. It passed locally, including 20 Release repetitions, so its intermittent CI failure remains open. The tests have not been removed or relaxed.

Executable generation now shares apphost discovery across Windows, macOS and Linux, including the running runtime root and portable SDK environment variables. Three deterministic tests cover SDK/host-pack selection, numeric versions, major-version filtering, missing templates and installation fallback. Ten targeted host/executable tests passed; the final local curated selection passed 877 tests, excluding the two recycle tests. These apphost changes still require native CI revalidation.

The current complete corpus was rerun on Windows after adding the hotkey-options case: official AHK 2.0.31 passed 62/62; Keysharp Release passed 57/62. The same five lifetime cases failed and the complete suite returned nonzero. Reports are in `compat/reports/current-official` and `current-windows`, copied alongside the checkout under `ahk-v2-macos-validation`.

Manual workflow runs can set `extended=true` to execute this complete suite on Windows and both native Macs, plus the four Mac ABI prototypes. The audit keeps nonzero exits and unsupported Windows-only cases visible. Push runs retain the original 14-case corpus and curated NUnit selection.

Run [40724547192](https://github.com/X6M-Work/ahk-v2-macos/actions/runs/40724547192), commit `2a13f286`, passed Windows NUnit (878 passed, one skipped) and Intel NUnit (934 passed, 20 skipped), with 14 matching differential cases each. Its queued Apple Silicon job was superseded by the extended audit.

The [first extended audit](https://github.com/X6M-Work/ahk-v2-macos/actions/runs/40726271080), commit `c5bc012f`, confirmed the 62/62 official reference and 57/62 Windows comparison in CI. Apple Silicon eventually ran: 934 NUnit tests passed, 20 skipped; the full corpus had 55 passes, six failures (the five lifetime cases and self-Reload) and one unsupported Windows DLL case. Its four native C ABI probes passed. Intel stopped before compilation because fetching Eto failed with `SSL connection timeout`. Bootstrap retries Git fetch and recursive submodule operations at most three times; four mocked-process tests verify recovery, the retry limit, the exact pin and dirty-checkout refusal.

Run [40729614239](https://github.com/X6M-Work/ahk-v2-macos/actions/runs/40729614239), commit `e5a31dff`, confirmed the same native results on Intel: 934 NUnit passes, 20 skipped, four ABI passes, 55/62 corpus passes with the same six failures and one unsupported case. Windows had 876 NUnit passes, one skipped and two failures in `ScreenTests.ConcurrentHide` and `OverlaySerialization`; its full comparison remained 57/62 and Reload passed. The `macos-26` Apple Silicon job remained queued and was cancelled. Further runs use `macos-15`.

The reviewed shutdown repair reissues `Quit()` after macOS nested UI pumps and auto-execute callbacks unwind, including exceptional unwinds, without modifying pinned Eto. SIGTERM registration precedes queued script initialization. POSIX predecessor waits sleep between checks; noninteractive waits are bounded at 15 seconds and report timeout on stderr. The screen concurrency tests use dedicated workers, bounded joins and unconditional release of their blocking backing. Local revalidation: 40 Python tests, nine internal Screen tests, and the Windows self-Reload comparison passed after a Release build with `PublishReadyToRun=false`. NuGet vulnerability metadata was unavailable (NU1900); compilation and execution succeeded. The sibling KeysharpDocs site is absent and needs the corresponding reference update.

Run [40761878577](https://github.com/X6M-Work/ahk-v2-macos/actions/runs/40761878577), commit `afeed022`, validated that repair: 878 Windows NUnit passes (one skipped), and 934 passes (20 skipped) on each Mac architecture. All four native ABI probes passed on each Mac. Self-Reload passed in 2,394 ms on Apple Silicon, 8,877 ms on Intel and 5,274 ms on Windows, with exact expected output and process exits. The extended audit remained red because of the five lifetime failures and the unsupported Windows DLL fixture on Mac.

Scoped-file cleanup subsequently passed the unchanged `file-scope-close` fixture on Windows; the architecture corpus now retains four destructor failures and one pass. The complete 62-case Windows comparison passed 58 cases, retaining only those four failures; timers, processes, native Float and self-Reload passed. `FileAndDirTests.FileLocalLifetime` verifies local aliases, early returns, exceptions, multiple files, loop writes, generated-name collisions, user `finally`, and preservation through returns, Array, Map, properties, globals, closures, VarRef, borrowed arguments and rebound methods. The same source passed official AutoHotkey 2.0.31 and standalone Keysharp with identical `pass` output. No forced collection, sleep or manual close was added to the original architecture fixture. This is a conservative escape-analysis optimization, not general file reference counting. Reassigned aliases, repeated openings in loops, exported ownership and custom destructors remain outside its proof.

The standard-stream checks exposed an independent infinite encoder loop: `Encoder.Convert` could consume and produce zero while reporting incomplete conversion. Empty writes now return directly; flushing stops when no input or output remains, and nonempty conversion with no progress reports failure. The fixture verifies stdout remains usable after a local wrapper. Local selected NUnit regression: 878 passed, excluding the two recycle-bin tests; the final stricter ownership proof and updated fixture also passed their targeted rerun. Native validation of scoped-file cleanup remains pending. A Release compiler daemon created by the broad executable tests was stopped before rebuilding; subsequent local test commands set `KEYSHARP_DAEMON=0`.

## Reference-counting foundation, 28 October

Artifacts of [40774644855](https://github.com/X6M-Work/ahk-v2-macos/actions/runs/40774644855), commit `525684ff`, were downloaded and inspected. `file-scope-close` passed on Windows, Intel and Apple Silicon. Windows NUnit recorded 879 passes, zero failures and one skip; each Mac recorded 935 passes, zero failures and 20 skips. The original four destructor fixtures still failed on all three platforms.

`Any` now carries a reference lifecycle and `Lifetime` supplies `Retain`, `Release` and `Replace`. Named-variable ownership transfers are counted for newly constructed Object-rooted values. Native base classes and unconverted ownership paths retain GC fallback. The integration includes global/static teardown and canonical local cells. Self-assignment preserves the reference, the new slot is published before releasing its old value, and callbacks execute without holding the counter lock. Official AHK 2.0.31 probes establish that a reentrant assignment returns the slot's final value after destruction, rather than the original right operand; `Replace` follows that result and protects the incoming value throughout the callback.

The standalone alias-regression source passed official AHK 2.0.31 and Keysharp with identical output. A 73-test focused selection also passed, covering collections, functions, modules, the include-file boundary and lifecycle contracts. Constructor exports through arrays and closures remain usable. The strict Windows corpus now passes 59/62: only `destructor-scope`, `destructor-temporary` and `destructor-resurrection` fail, with unchanged fixtures/goldens and nonzero audit exit preserved. The resurrection fixture now observes the first call; the intervening `IsObject(saved)` hands it back to GC, so the second call is still missing. Timers, processes, native Float, scoped files and real self-Reload pass. Reports are in `compat/reports/reference-counting`. Final curated and native revalidation are recorded below when available. The sibling KeysharpDocs checkout is absent and needs the matching reference update.

Final local verification on 29 October: Release build succeeded; the complete selected NUnit run passed 885/885, excluding the two recycle-bin tests, with serialized workers and `KEYSHARP_DAEMON=0`. All 40 Python tooling tests passed. The final standalone source, including boxed-variable reentry and case-insensitive lifecycle names, matched official AHK exactly. Six internal tests cover native disposal, callback lock release, exceptions, stale pump entries, clones and uninstrumented/native instances. `ReferenceCountedAttribute` opts new compiler output into ownership; older assemblies and inline-C# classes keep GC behavior. Dynamic reads and unconverted field/property writes abandon explicit ownership. The final strict architecture run retains exactly the three failures above. No pinned Eto, strict fixture or golden was changed. Native CI revalidation of reference counting remains pending.

## Deterministic scope-exit release (`destructor-scope`), 29 October

Callable bodies now retain incoming parameters and receivers on entry (`InitializeParameters`), protect returned values before unwinding (`Lifetime.Return`), escape closure-captured locals at scope exit, and release non-captured parameters and locals in case-insensitive alphabetical order (`StringComparer.OrdinalIgnoreCase`) via `Lifetime.ReleaseScope` after user `finally` blocks run (skipped when `Script.TheScript.hasExited` is set). Boxed local variables (`Lifetime.Box`) reference-count their box handles so local `VarRef` aliases and `ByRef` calls release their stored value at scope exit while exported `VarRef` handles keep the cell alive until the last `VarRef` reference is cleared. `Lifetime.Borrow` and `MethodPropertyHolder` preserve ownership for borrowed reads of owned `Alive` instances and calls to script callables and `Keysharp.Builtins.Types`, and `Flow.Throw` / `ExceptionScope.Dispose` retain and release thrown values across stack unwinding and `catch` blocks.

`compat/phase15-architecture/destructor-scope.ahk` now passes unchanged on Windows (`returned:deleted`). In `compat/phase15-architecture`, 3/5 cases now pass (`destructor-alias`, `destructor-scope`, `file-scope-close`), leaving only `destructor-temporary` and `destructor-resurrection` for the next steps. The new standalone regression fixture `Keysharp.Tests/Code/class-destructor-scopes.ahk` passed both official AutoHotkey 2.0.31 and Keysharp Release with identical `pass` output, and `ReferenceLifetimeTests` (8/8) plus `ClassTests` (`DestructorAliases` and `DestructorScopes`) and all 40 Python unit tests passed.

## Full-expression temporary owners, 29 October

Artifacts from [40803366218](https://github.com/X6M-Work/ahk-v2-macos/actions/runs/40803366218) on b8129217 confirm 889 NUnit passes on Windows and 945 on each Mac (1 / 20 skipped), no NUnit failures. Alias, scope and scoped-file fixtures pass on all three targets; temporary and resurrection still fail in that baseline.

The subsequent expression-owner change passes the unchanged temporary fixture locally on Windows. All three standalone alias/scope/temporary regression sources match official AHK 2.0.31 exactly (`pass`); the focused NUnit run passed 106/106. Build: Release, PublishReadyToRun=false, daemon disabled. Strict architecture: 4/5, with resurrection the only remaining failure. Reports: `compat/reports/temporary-lifetime`; native validation of this change is pending. Variadic arrays and other unconverted containers remain GC-managed. No strict fixture, golden or pinned Eto source was changed. The sibling KeysharpDocs checkout is absent.

## Borrowed resurrection, 29 October

After commit 40a74975 (full-expression temporary owners), Borrow preserves owned Resurrected instances as well as Alive instances. The unchanged resurrection fixture now prints `first:1:1` followed by `second:2`; all five architecture cases pass locally against official AHK 2.0.31. The alias regression now verifies three destruction cycles through predicates, method calls and return transfers; the native-disposal internal test checks that an intervening borrow preserves the resurrected state. The three standalone regression sources match official AHK exactly. Full selected NUnit and extended native revalidation are recorded when available below.

Final local verification: 889/889 selected serialized NUnit tests passed (real recycle-bin tests excluded), 40/40 Python tooling tests passed, and all 62 extended Windows observations passed against the official reference reports: 58 corpus cases, 3 processes and 1 real self-Reload. `suite.json` is passing. Logs: `work/temporary-resurrection-curated.log`, `work/temporary-full-windows.log`, `work/temporary-python-tests.log`; TRX: `Keysharp.Tests/TestResults/temporary-resurrection-curated.trx`. No forced GC, sleep or fixture/golden change was introduced.

### Native CI scheduling block and indexed-storage follow-up

Both runs [40806250026](https://github.com/X6M-Work/ahk-v2-macos/actions/runs/40806250026) and [40806273377](https://github.com/X6M-Work/ahk-v2-macos/actions/runs/40806273377) on a0e5256b were rejected before any job executed. GitHub check annotations report failed recent payments or a spending limit requiring adjustment. Consequently neither run supplies native evidence for the temporary/resurrection changes; the last executed native baseline remains b8129217 / 40803366218.

A subsequent array audit found the optimized indexed setter bypassed the normal setter's Lifetime.Escape guard. Storing a temporary through a positive integer index could therefore leave a released instance in an unconverted array. The optimized path now uses the same guard. New standalone checks cover fast integer and slow string indexes, removal and subsequent retention. Both engines pass all three standalone regressions; final strict architecture remains 5/5. Release build and 7 focused collection/temporary NUnit tests passed after this follow-up. The complete 889-test run and 62 observations above precede this one-line guard correction. Full deterministic array/variadic ownership remains pending; the separate audit probe records missing destruction without hiding it behind GC or sleeps.
