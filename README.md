# AHK v2 for macOS

Run AutoHotkey v2-style scripts on macOS with the complete [Keysharp](https://github.com/keysharp-org/Keysharp) engine. This source fork adds reproducible dependency pins, macOS tooling, and a compatibility test corpus against official AutoHotkey on Windows.

**Experimental. 100% AutoHotkey compatibility is a goal, not an achieved or guaranteed property.** Windows DLLs, registry APIs, native COM interfaces, and some language behaviors cannot run unchanged. See the [compatibility notes and French quickstart](docs/macos-compatibility.md).

The stable compatibility contract is [AutoHotkey 2.0.31](docs/compatibility-contract.md). The [architecture documentation](docs/architecture-phase15.md) details the deterministic reference-counting lifecycle model implemented across local scopes, expressions, temporaries, arrays, maps, and dynamic properties. The expanded test suite validates regex, enumeration, encodings, native Float values, self-Reload, and over 1,000 unit and integration tests.

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

The [native CI run for `68dd8bd4`](https://github.com/X6M-Work/ahk-v2-macos/actions/runs/40722552703) built and executed on Apple Silicon and Intel: each Mac passed 931 NUnit tests, skipped 20, and matched all 14 initial differential cases. Desktop interaction and permission prompts still require manual validation.

The [validation record](docs/validation.md) documents Windows comparisons, native CI execution, and test conventions.

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

Keysharp builds on IronAHK and other open-source projects. Original authors, copyright notices, and the upstream [license](license.txt) are preserved. See the [detailed reference](docs/reference.md) and [capability matrix](docs/capabilities.md) for detailed runtime behavior. This project is not an official AutoHotkey release.
