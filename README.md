# AHK v2 for macOS

Run AutoHotkey v2-style scripts on macOS with the complete [Keysharp](https://github.com/keysharp-org/Keysharp) engine. This source fork adds reproducible dependency pins, macOS tooling, and a compatibility test corpus against official AutoHotkey on Windows.

**Experimental. 100% AutoHotkey compatibility is a goal, not an achieved or guaranteed property.** Windows DLLs, registry APIs, native COM interfaces, and some language behaviors cannot run unchanged. See the [compatibility notes and French quickstart](docs/macos-compatibility.md).

The stable compatibility contract is [AutoHotkey 2.0.31](docs/compatibility-contract.md). The [architecture gate](docs/architecture-phase15.md) records the unresolved immediate-destruction mismatch. The expanded local test suite keeps architecture failures visible and tests regex, enumeration, encodings, native Float values and self-Reload.

## Run on macOS

Requires macOS 15+, the [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0), Git, and Python 3. Apple Silicon and Intel are supported build targets.

```sh
bash scripts/macos/bootstrap.sh
bash scripts/macos/build.sh --configuration Release
bash scripts/macos/ahk doctor
bash scripts/macos/ahk run examples/macos/hello.ahk
```

The launcher also supports `validate your-script.ahk`. Input automation requires macOS Accessibility and Input Monitoring permissions; screen capture requires Screen Recording permission. More examples: [hotkeys](examples/macos/hotkeys.ahk), [timers](examples/macos/timer.ahk), and [GUI](examples/macos/gui.ahk).

## What is included

- Complete Keysharp parser, compiler, runtime, native macOS backends, and Keyview editor sources.
- Frozen [Keysharp and Eto revisions](UPSTREAM.lock.json); dependency bootstrap checks the exact Eto commit.
- Terminal launcher, environment diagnostics, and build helpers under [`scripts/macos`](scripts/macos).
- [Conformance runner](compat/README.md) comparing the same scripts with official AutoHotkey v2.0.31 on Windows.
- GitHub Actions for native Apple Silicon/Intel builds, selected upstream tests, and compatibility reports.
- A manual packaging workflow producing unsigned `.app` bundles inside `.pkg` and `.dmg` artifacts, with SHA-256 checksums.

Workflows are provided for execution in your repository. Their presence does not establish that macOS builds or interactive automation have been tested. Passing the included corpus demonstrates only those cases.

See [publishing to GitHub](docs/publish-to-github.md) for the commands to publish this source fork.
The [local validation record](docs/validation.md) distinguishes executed Windows checks from pending macOS verification.

For local macOS validation, transfer the Windows reference reports, then run:

```sh
bash scripts/macos/verify-local.sh --baseline-dir /path/to/official-reports
```

This builds the native host target and runs every local conformance gate plus the native ABI prototypes. Known incompatibilities return a failure status. No GitHub repository is required. See [the runner guide](compat/README.md).

## Build and inspect

```sh
bash scripts/macos/build.sh --configuration Release --rid osx-arm64 --publish
python3 -m unittest discover -s compat/tests -v
```

Use `osx-x64` on Intel. Published files go under `dist/publish/<rid>/`. See the [package guide](docs/macos-compatibility.md#packages) and [manual desktop test checklist](docs/macos-manual-tests.md).

## Origin and license

Based on Keysharp commit [`86fa3c5`](https://github.com/keysharp-org/Keysharp/commit/86fa3c5c0e07dd2f66cad55a6b9d4a7eb467736b). Keysharp targets AutoHotkey v2.1-alpha.36; this fork uses v2.0.31 as its initial stable reference for the shared corpus. These are distinct compatibility targets.

Keysharp builds on IronAHK and other open-source projects. Original authors, copyright notices, and the upstream [license](license.txt) are preserved. Read the [original README](docs/UPSTREAM-README.md), [detailed reference](docs/reference.md), and [capability matrix](docs/capabilities.md) for upstream behavior. This project is not an official AutoHotkey release.
