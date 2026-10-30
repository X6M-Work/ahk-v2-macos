# Keysharp test conventions

Tests exercise the highest stable boundary that can deterministically prove the behavior.

## Script-visible behavior

AHK syntax, built-ins, classes, directives, and runtime behavior belong in `Code/*.ahk`. A small NUnit method should invoke the script through `TestScript(...)`. This path covers lexing, parsing, lowering, compilation, dynamic dispatch, and runtime behavior together.

New test scripts must include both directives below so failures cannot open a modal dialog:

```ahk
#ErrorStdOut
#Warn All, StdOut
```

### Assertions

A script is silent while it succeeds and writes a single `pass` once it reaches its end. The runner accepts
nothing else: a non-zero exit code, empty output, a `fail` tag, or an error trace all fail the test, and so does
a run that stopped partway and never reached the final `pass`.

```ahk
#Include <assert>

AssertEq(arr[1], 10, A_LineNumber)               ; writes "fail line 12 (got <11> want <10>)"
Assert(x > 0 && y < 10, A_LineNumber)            ; writes "fail line 13"
Throws(() => arr[99], A_LineNumber)              ; writes "fail line 14 (no throw)"
Throws(() => Foo(), A_LineNumber, TypeError)     ; ... and names the wrong class when one is given
...
FileAppend "pass", "*"                           ; last thing the script runs
```

Reach for `AssertEq` whenever the check is an equality: it names both values, so a failure needs no second
run to find out what was actually produced. `Assert` is for everything else — compound conditions, `is`
tests, inequalities — where there is no single pair of values to show. `AssertEq` compares with `==`, so a
check that genuinely depends on `=`'s case-insensitive string match must stay an `Assert`.

`A_LineNumber` folds to a literal at compile time, so the tag costs nothing and can never go stale. Omit it and
the failure is tagged with the assertion's ordinal instead. For "this must not throw", use a plain `try`/`catch`
with `Assert(false, A_LineNumber)` in the catch.

Put the final `pass` where the script really ends — ahead of a top-level `ExitApp`, or ahead of the first
`#Module` block — not merely on the last line. A script that another one `#include`s never writes its own.

Keep the branch structure when the branch structure is what is under test (`flow-if.ahk`): record which branch
ran in a variable and assert on that afterwards, rather than collapsing the construct into one `Assert`.

Use `RunScript(...)` directly only when a test needs generated source, separate compilations, diagnostic text, an exit code, or another result that `TestScript(...)` cannot expose.

## Internal contracts

A direct C# test is appropriate when the behavior cannot be tested safely or deterministically from a script. Examples include compiler diagnostics, protocol framing, injected clocks, concurrent state machines, native event construction, and platform adapters that would otherwise need hardware or permissions.

Mark implementation-facing contracts or their fixture with `Category("Internal")`; public compiler and command-line boundary tests do not need that label. Add `Category("Curated")` only when the entire selected scope is deterministic, non-interactive, and safe on every platform where it compiles.

Do not assert token sequences, AST printer output, generated C# text, reflected field layout, or private helper behavior when an executable script can prove the same contract. Keep a representation-level assertion only when that representation is itself the boundary between components.

## Names and coverage

- Name tests after the feature or compact scenario, such as `PowerPrecedence`, `NamedArgErrors`, or `RetryLimit`.
- Put detailed inputs and expectations in the test body, assertion message, or `[TestCase]` data rather than encoding a sentence in the method name.
- Prefer one behavior script with related checks over many one-assertion C# methods.
- Add a check to the existing script that owns its topic, such as `class-props.ahk` or `func-opt-params.ahk`, rather than creating a script to collect one change's checks. Create a new script only when there is a strong reason, such as a test that fits none of the existing ones. First look for an existing check that already covers the behavior.
- A script run with `TestScript(name, true)` is also compiled wrapped in a function, where a class cannot be declared, so a check added to one builds the objects it needs with `DefineProp`.
- Before keeping an internal test, check whether an existing behavior script already covers its observable result. Remove redundant coverage.
- When fixing a regression, add the script-level test first. Add an internal test only when it contributes deterministic coverage the script cannot provide.

## Execution safety

Test fixtures and assets are resolved from the checkout containing `Keysharp.sln` and `Keysharp.Tests/Code/Lib/assert.ahk`, walking up from the test assembly. The output directory may include a runtime identifier such as `osx-arm64` or `win-x64`. A missing script fixture fails with its file path before compilation; it must not be parsed as inline source.

Scripts that read shared test data include `<testpaths>` and use `_TestFixturePath(...)`. The helper resolves against its included file, so it also works when the main script is compiled from text inside a function wrapper. Relative scratch destinations remain under the test working directory.

`RunScript` returns stdout and preserves stderr for tests that intercept expected errors. Failed `TestScript` assertions include the captured stderr diagnostic. A test that changes `CurrentCompatibilityVersion` must restore it in `finally`; it is thread-local state shared across test instances.

`Code/Gui/guitest.ks` is interactive and skips operations the compositor reports as unsupported. Run native tray checks in a separate, self-terminating process; the test host does not publish icons.

For nested Wayland tests, point both Keysharp and keysharp-desktop at the nested display. Verify with `keysharp-desktop probe`, then restore the outer desktop's service afterwards.

The full suite includes interactive and permission-sensitive fixtures. Run the curated filter from the repository `AGENTS.md`, a narrower category, or a specific test. Never add `[Parallelizable]`; the suite shares `Script.TheScript` state.

### Timer scheduling and loop cleanup

`TimerSchedulerTests` and `FlowTests.LoopCleanupAfterDisposeFailure` are included in the curated selection. The timer fixture checks blocked admission, overdue callback coalescing, nested callbacks during `Sleep`, callback periods, notifications during a pump, and visible-menu scheduling. Loop cleanup checks that a failing enumerator `Dispose` still restores the outer loop. The tests do not require keyboard hooks, user input, or screen access.

Run this scope locally, without starting a GitHub workflow:

```powershell
dotnet test Keysharp.Tests/Keysharp.Tests.csproj -c Release -p:PublishReadyToRun=false --no-build --no-restore --nologo --filter 'FullyQualifiedName~TimerSchedulerTests|FullyQualifiedName~FlowTests.LoopCleanupAfterDisposeFailure' --logger 'trx;LogFileName=timer-loop-cleanup.trx' --blame-hang --blame-hang-timeout 60s -- NUnit.NumberOfTestWorkers=1
```

The filter selects nine cases: seven scheduling/cleanup regressions plus two existing `MenuVisible` cases. `LongTimerCoalescing` first uses the queued test transport and explicit overdue deadlines to check one queued callback, no reentry during a callback, preservation of an overdue deadline at completion, one subsequent callback and no accumulated catch-up queue. Its script then completes four callbacks whose 140 ms waits exceed the 80 ms timer period, disables the timer from the fourth callback and checks completion, serialization and callback duration. A five-second watchdog detects missing progress; there is no fixed callback count within a wall-clock sleep or maximum inter-callback latency assertion. `Sleep` may return late while native messages dispatch callbacks, so those bounds cannot establish coalescing. The other real-time timer scripts retain bounded waits; elapsed-time checks do not guarantee real-time scheduling. A Windows result does not establish native macOS behavior; run the same selection locally on each Mac architecture before claiming native validation.

### Processes, launcher, and environment

`RunnerTests`, the three process behavior scripts, and `EnvGet`/`EnvSet`/`EnvUpdate` belong to the curated selection. Ten launcher cases test Windows-only daemon authentication and remain inside `#if WINDOWS`. Their results do not establish macOS daemon behavior. The process scripts launch their own bounded child processes and clean up their scratch files.

On macOS, `ProcessRunWaitClose` needs Xcode Command Line Tools: it compiles `Code/Lib/process-wait.c` with `/usr/bin/clang` into its uniquely named temporary executable. Copying and re-signing `/bin/sleep` is unsuitable for the Apple Silicon fixture. A compiler failure stops setup, and the generated executable still has to pass the exit-code, name-based discovery, timer, multi-process wait and cleanup assertions. Windows and Linux retain their copied sleeper fixtures.

`SysGet` is curated on Windows only. It still needs a graphical session; its macOS/Linux testhost guard and `UI` category remain intact. `ClipboardAll` and `ClipWait` are outside this scope and are not promoted. Environment scripts use process-specific variable names; `EnvSet` removes its test variable in `finally`.

Run the related curated cases locally after building:

```powershell
dotnet test Keysharp.Tests/Keysharp.Tests.csproj -c Release -p:PublishReadyToRun=false --no-build --no-restore --nologo --filter 'Category=Curated&(FullyQualifiedName~RunnerTests|FullyQualifiedName~ProcessTests|FullyQualifiedName~EnvTests.EnvGet|FullyQualifiedName~EnvTests.EnvSet|FullyQualifiedName~EnvTests.EnvUpdate|FullyQualifiedName~EnvTests.SysGet)' --logger 'trx;LogFileName=process-runner-environment.trx' --blame-hang --blame-hang-timeout 60s -- NUnit.NumberOfTestWorkers=1
```

This selection also includes existing curated cases in these fixtures. A Windows run covers 21 newly selected cases: 14 launcher cases, three process cases, and four environment/system cases. Native macOS validation remains a separate step.

### Desktop input, clipboard, monitors, and capture

`Category=Desktop` explicitly selects tests that use native hooks, the session clipboard, monitor enumeration, a graphics backend, GUI windows/dialogs, temporary capture windows, or recycling of generated scratch files. These tests stay outside the default curated filter. The Windows selection contains 72 cases. Pure coordinate/image calculations are curated separately.

The pixel/image screen fixture uses an always-on-top window shown with `NoActivate`. It requires the swatch and background colors to be visible within three seconds, rather than requiring foreground focus or assuming a fixed paint delay. It restores the caller's pixel coordinate mode on success and failure, and destroys its window if setup fails. The fixture still requires an unlocked graphical session with an unobscured capture region; failure to render is a failure, not a skipped assertion or fabricated pass.

The extended macOS compatibility workflow explicitly runs this `screen-pixelsearch.ahk` fixture on Windows, Intel macOS and Apple Silicon through `compat/run_screen.py`. Its `screen-pixelsearch-native.ahk` entry point checks macOS Screen Recording permission without prompting, then includes the original assertions. It launches the native Keysharp executable so AppKit owns the OS main thread, rather than selecting a desktop NUnit test that macOS testhost would skip. The gate requires exit code zero, exactly `pass` on stdout and empty stderr; missing capture permission, an unavailable desktop, incorrect pixels and timeouts fail the gate. Reports, executable/assembly identities and fixture hashes are uploaded under `compat/reports/desktop/`. The standard push workflow keeps its curated selection; choose `extended=true` for this desktop gate. This single script execution does not include NUnit's additional function-wrapped variant or the other Desktop tests.

Clipboard tests capture the original formats before probing and restore them in teardown, including after assertion failures. A compiled script may have disposed its clipboard-owner window; restoration creates a fresh script context when needed. The snapshot stays in memory. The hotstring callback test disables backspacing and feeds simulated events into the installed hook; it does not prove physical keyboard delivery. The F12 script activates its own window and verifies that its local callback actually runs under `#HotIf WinActive("ahk_id " fixture.Hwnd)`.

Run the desktop selection on Windows with an unlocked interactive session:

```powershell
dotnet test Keysharp.Tests/Keysharp.Tests.csproj -c Release -p:PublishReadyToRun=false --no-build --no-restore --nologo --filter 'Category=Desktop' --logger 'trx;LogFileName=desktop.trx' --blame-hang --blame-hang-timeout 60s -- NUnit.NumberOfTestWorkers=1
```

For a combined local run, parenthesize the normal curated filter (including its hook and recycle exclusions), then append `|Category=Desktop`. This explicitly opts into hooks while preserving the ordinary curated filter. Tests remain serialized. Do not add this desktop selection to headless CI: native macOS GUI tests need an AppKit main-thread-capable host and the relevant permissions. Headless skips are not successful native validation.

### Drives, audio, and recycling

The seven read-only `DriveTests` cases are curated. They query the system drive on Windows and `/` off Windows, without assuming the drive letter, filesystem, minimum free space, or a nonzero serial number. `DriveGetList` also checks its type-filtered result.

`Category=Audio` explicitly opts into `SoundBeep`: two short tones, argument validation, and a lower bound on synchronous duration. A successful call does not prove audible output, physical pitch, or a working macOS player. `ToneWav` remains the separate curated, device-free synthesis check.

`FileRecycle` belongs to `Desktop` and only recycles its own uniquely named temporary files and directories. It never empties the session trash. Generated recycled items remain in that trash.

`DriveGetSetLabel` and `FileRecycleEmpty` have `Category=DisposableVolume`. They skip before executing a script unless `KEYSHARP_TEST_VOLUME` identifies an explicitly prepared disposable Windows drive root such as `R:\`. The system drive is rejected. The volume must be labeled `KEYSHARP_TEST` and contain `.keysharp-disposable-test-volume` with the exact content `Keysharp disposable test volume`, without a newline. Use a disposable NTFS virtual disk; do not mark a volume containing personal data. The label test also requires an elevated test host and restores the label in `finally`. The empty test queries the recycled item count before and after its volume-scoped call. It never calls the default global empty operation. Both scripts repeat the guard when launched directly.

Off Windows, the empty test skips: the implementation ignores its volume argument and would empty the user's trash. Native validation requires an isolated OS account. These skips are pending native validation, not passes.

From an elevated Windows PowerShell, `scripts/test-disposable-volume.ps1 -Dotnet <dotnet.exe>` creates its own new 256 MiB VHD, verifies its disk association, size and boot/system flags before partitioning, formats only that image, sets the test marker and runs exactly the two `DisposableVolume` cases. It detaches the image in `finally` and deletes it after successful tests and detach. Logs, a TRX and `result.json` remain under a fresh `Keysharp.Tests/TestResults/disposable-volume-*` directory. Failed images are retained for inspection. `-Preflight` prints the plan without creating or mounting a disk. The script does not request elevation itself and refuses an existing session directory or image.

```powershell
dotnet test Keysharp.Tests/Keysharp.Tests.csproj -c Release -p:PublishReadyToRun=false --no-build --no-restore --nologo --filter 'FullyQualifiedName~Keysharp.Tests.DriveTests.|FullyQualifiedName=Keysharp.Tests.SoundTests.SoundBeep|FullyQualifiedName=Keysharp.Tests.FileAndDirTests.FileRecycle|FullyQualifiedName=Keysharp.Tests.FileAndDirTests.FileRecycleEmpty' --logger 'trx;LogFileName=drives-audio-recycle.trx' --blame-hang --blame-hang-timeout 60s -- NUnit.NumberOfTestWorkers=1
```

For a combined local run, append `|Category=Audio` to the existing curated-or-Desktop filter. Do not include `DisposableVolume` in unattended CI.

### CLR and Windows interop

`ExternalTests.Clr` is curated on all platforms. Its script covers the managed bridge, callbacks, collections, spans and string conversion; a CLR `ManagedInstance` supplies its wrapped `ToString` even in v2.0 mode, while ordinary AHK objects still fail implicit string conversion in that mode.

`Category=WindowsInterop` explicitly selects ten additional Windows-only cases: COM dispatch, synchronous COM events, SAFEARRAY storage/conversion, type libraries, reference ownership on packing failure, and native `OnMessage`. They remain compiled only under `#if WINDOWS`. A missing registered type library remains an explicit skip. `OnMessage` registers a unique message and posts/sends only to the test script's own hidden window, using a bounded wait for asynchronous delivery.

```powershell
dotnet test Keysharp.Tests/Keysharp.Tests.csproj -c Release -p:PublishReadyToRun=false --no-build --no-restore --nologo --filter 'Category=WindowsInterop|FullyQualifiedName=Keysharp.Tests.ExternalTests.Clr' --logger 'trx;LogFileName=interop.trx' --blame-hang --blame-hang-timeout 45s -- NUnit.NumberOfTestWorkers=1
```

Append `|Category=WindowsInterop` to the combined local curated/Desktop/Audio filter to include these cases. Native Windows COM/SAFEARRAY and Win32 message results do not establish macOS COM emulation; validate the CLR correction separately on each Mac architecture.

### GUI selection and bounded dialogs

The four `GuiTests` coordinate/topology cases (`DisplaySelection`, `ExtremeDisplayInput`, `WindowsCaptureScale`, `DenseCaptureScale`) are curated and use synthetic display data. Thirty-eight additional Windows GUI cases belong to `Desktop`: windows, controls, menus, DPI, event dispatch, overlays, themes, native dialogs and WebView. Existing per-platform compilation and AppKit/headless guards remain intact.

The fixture sends unexpected script errors to stderr. `MsgBox` uses a unique title, verifies the owning PID and posts Return messages directly to that dialog. It neither injects global keystrokes nor changes foreground focus in its responder. Numeric and text option inputs remain distinct. A three-second watchdog marks the test as failed if it must intervene; assertions from `Shown` callbacks are returned to NUnit, and responder shutdown has a bounded wait. The separate dialog timeout check remains 0.2 seconds. `NativeInputBox` retains its own typed-value responder and two-second close watchdog.

`gui-webview.ahk` must create a real WebView and run its assertions. Creation errors fail the case; the script never reports pass because a browser engine is missing. The GUI is destroyed in `finally`. This script checks the synchronous control surface, not page rendering, JavaScript execution after document load or browser navigation timing.

A local Windows run checks native API behavior and programmatic assertions. It does not establish visual quality, actual multi-monitor DPI transitions, Linux compositor behavior or native AppKit operation. Run the corresponding cases on each target platform with a suitable desktop runner before claiming native validation.

### Packages and providers

The three offline deployment cases in `ProviderDeploymentTests` are curated: the bundled provider's isolated payload, copying only required providers, and authenticated extraction/repair of an embedded provider. They use owned temporary directories and a generated fake provider; they do not restore third-party packages. The existing inline-name case remains selected through `Directives`.

The 22 cases with `Category=NuGet` remain an explicit opt-in because some require nuget.org, advisory metadata or a populated package cache. They cover batched/imperative restore, version conflicts and rollback, optional/offline requests, warm-cache validation and repair, manifests/deployment, inline C#, `.cks`, `exe`, `exe-min`, lazy transitive loading, RID-specific SQLite assets, target-supplied WebView2 assemblies, restore-lock cancellation and vulnerability diagnostics. `ProviderAudit` requires an actual `NU1901` through `NU1904` advisory for its deliberately vulnerable fixture package; an unavailable audit service (`NU1900`) cannot satisfy it. This old package is a test fixture, not a recommended application dependency.

```powershell
$env:KEYSHARP_DAEMON = '0'
dotnet test Keysharp.Tests/Keysharp.Tests.csproj -c Release -p:PublishReadyToRun=false --no-build --no-restore --nologo --filter 'Category=NuGet|FullyQualifiedName=Keysharp.Tests.ProviderDeploymentTests.BundledNuGetProviderIsAnIsolatedExplicitPayload|FullyQualifiedName=Keysharp.Tests.ProviderDeploymentTests.FullArtifactCopiesOnlyRequiredProviders|FullyQualifiedName=Keysharp.Tests.ProviderDeploymentTests.MinimalArtifactAuthenticatesAndRepairsEmbeddedProvider' --logger 'trx;LogFileName=packages-providers.trx' --blame-hang --blame-hang-timeout 4min -- NUnit.NumberOfTestWorkers=1
```

The filter selects exactly 25 Windows cases. Child launchers inherit daemon disablement and use redirected output with a bounded exit wait. A warm run does not prove a fresh-machine download. Append `|Category=NuGet` to the combined local selection only when deliberately testing package feeds; do not silently add it to the default curated CI filter. Windows SQLite loading and Windows executable deployment do not establish macOS native library resolution, app-host execution, signing or quarantine behavior. Re-run on both Mac architectures locally.

On Windows in a restricted sandbox, run tests through `scripts/test-sandbox.ps1` from the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-sandbox.ps1 -Filter 'FullyQualifiedName~InputHookTests.KeyOpt'
```

The filter is required. The script maps the checkout to a temporary free drive because NUnit scans parent directories of its assembly for extensions, and the normal checkout path can lead outside the sandbox. It runs `dotnet test` with shared compilation disabled, writes test results under `Keysharp.Tests/TestResults`, and removes the drive mapping when the command exits. Use the curated filter from `AGENTS.md` when running the wider safe subset.
