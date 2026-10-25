# macOS development commands

Local compatibility gates: `bash scripts/macos/verify-local.sh --baseline-dir /path/to/official`. Requires the transferred Windows AHK 2.0.31 reports; no GitHub repository is used. The command returns nonzero for any incompatibility, including known architecture and regex gaps. See `compat/README.md`.

Requires macOS 15 or newer, Git and the .NET 10 SDK. Run from the repository root:

```bash
bash scripts/macos/bootstrap.sh
bash scripts/macos/build.sh
bash scripts/macos/ahk validate path/to/script.ahk
bash scripts/macos/ahk run path/to/script.ahk "argument with spaces"
bash scripts/macos/ahk doctor
```

`bootstrap.sh` fetches the Keysharp Eto fork at commit
`0fb601a1ab078211d68ccbec86b7ff16ab3b21ad` (branch `Keysharp`) into `.deps/Eto`
and initializes recursive submodules. Existing dirty checkouts are refused.
It does not install system dependencies.

`build.sh` defaults to `Debug` and the host architecture. For an Intel target or
a framework-dependent publish tree:

```bash
bash scripts/macos/build.sh --configuration Release --rid osx-x64
bash scripts/macos/build.sh --configuration Release --rid osx-arm64 --publish
```

Published output is `dist/publish/<rid>/Keysharp/`. This command does not create
an installer, signing certificate or notarized release. Both commands accept
`--eto-root PATH`; the `EtoRoot` environment variable provides the same override.
The dependency revision remains pinned. These builds disable ReadyToRun and its
optional PGO download feed.

The launcher searches the host RID's publish tree, Release/Debug build trees,
the repository root, `~/Applications` and `/Applications`. Set
`KEYSHARP_EXECUTABLE="/absolute/path/Keysharp.app/Contents/MacOS/Keysharp"`
to choose a specific build. Arguments and exit codes pass through unchanged;
`validate` adds `--errorstdout --validate` and never runs the script.

The launcher preserves script source and the caller's current directory. The
script path is made absolute to avoid interpreting a filename as a runtime
switch. This tooling does not establish complete AutoHotkey v2 compatibility.
