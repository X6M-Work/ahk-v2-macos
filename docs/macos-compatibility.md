# macOS compatibility

This is a source fork of Keysharp, with its actual parser, Roslyn compiler, runtime, and macOS integrations. It does not embed the Windows AutoHotkey executable or emulate Windows.

## Compatibility contract

Keysharp targets AutoHotkey v2.1-alpha.36. The initial differential corpus uses official AutoHotkey v2.0.31 on Windows as a fixed stable reference. Corpus scripts select `#Requires AutoHotkey v2.0`. A passing corpus is evidence for its individual cases, not a percentage of the entire language or API.

| Area | macOS behavior and limits |
| --- | --- |
| Parser and runtime | Implemented by Keysharp. Documented language differences remain. |
| Hotkeys, hotstrings, keyboard/mouse synthesis | Native backend exists; upstream marks support partial. Requires Input Monitoring and Accessibility. |
| Windows/GUI | Eto and native backends; control appearance and behavior differ. Foreign application controls are not Windows controls. |
| Capture, pixels, image search | Native implementation; Screen Recording permission required. Interactive and multiple-display behavior needs hardware testing. |
| `DllCall` | Can call macOS libraries. Windows DLLs and the Win32 ABI are not supplied. |
| Registry and native COM | Unsupported. The Apple Events adapter is not a Windows COM implementation. |
| `SendPlay` | Falls back to Event mode; macOS has no Windows journal-playback equivalent. |
| Object lifetime | Deterministic reference-counting implemented (Phase 15); destructors run immediately on last reference release (scopes, expressions, temporaries, arrays, maps, and properties). Fallback to GC for unmigrated CLR boundaries. |
| Other language details | Unicode identifier case matching, Map float keys, and scoped `#Requires` behavior have documented differences. |

The upstream [capability matrix](capabilities.md) and [differences reference](reference.md#differences) contain finer details. Several macOS entries remain partial or unverified. No claim of full compatibility is made.

## Démarrage rapide en français

Prépare un Mac sous macOS 15 minimum, avec le SDK .NET 10, Git et Python 3. Depuis la racine du dépôt :

```sh
bash scripts/macos/bootstrap.sh
bash scripts/macos/build.sh --configuration Release
bash scripts/macos/ahk doctor
bash scripts/macos/ahk validate examples/macos/hello.ahk
bash scripts/macos/ahk run examples/macos/hello.ahk
```

Le bootstrap récupère le fork Eto à sa révision exacte, avec ses sous-modules. Le moteur Keysharp est déjà présent dans ce dépôt. Les autres exemples couvrent les [raccourcis](../examples/macos/hotkeys.ahk), [timers](../examples/macos/timer.ahk) et [fenêtres](../examples/macos/gui.ahk).

Pour les raccourcis globaux et l'envoi de touches, autorise Accessibilité et Surveillance de l'entrée dans Réglages Système → Confidentialité et sécurité lorsque macOS les demande. Pour les captures, autorise Enregistrement de l'écran. Une relance du processus peut être nécessaire après l'autorisation.

Les packages du workflow sont non signés et non notariés. Gatekeeper et la conservation des autorisations entre deux builds ne sont donc pas résolus par ce workflow. Utilise la [liste de vérifications sur Mac](macos-manual-tests.md) avant toute annonce de compatibilité.

## Build layout

```sh
bash scripts/macos/bootstrap.sh --eto-root /path/to/Eto
bash scripts/macos/build.sh --configuration Release --rid osx-arm64 --publish --eto-root /path/to/Eto
```

Use `osx-x64` for Intel. The default dependency location is `.deps/Eto`. Upstream MSBuild projects accept `-p:EtoRoot=/absolute/path/to/Eto/`; the helpers supply this property. `KEYSHARP_EXECUTABLE` selects an explicit engine path for the launcher.

Build and publish outputs retain the upstream layout under `bin/` and `dist/publish/<rid>/`. Select architecture through the runtime identifier, not `Platform=x64` or `Platform=ARM64`.

## Verification

The [compatibility workflow](../.github/workflows/macos-compatibility.yml) defines Python tooling tests, an official Windows reference run, a Keysharp Windows run, and native macOS Apple Silicon/Intel builds. Keysharp jobs run selected upstream NUnit tests and compare the shared corpus with the official reference. The AutoHotkey archive is SHA-256 checked against `UPSTREAM.lock.json` before extraction.

The macOS labels are [`macos-15` and `macos-15-intel`](https://docs.github.com/en/actions/reference/runners/github-hosted-runners). The workflow checks `uname -m`, excludes upstream `RequiresHook` tests, and adds deterministic Quartz event-construction tests. Interactive TCC prompts, actual key delivery, GUI rendering, multiple screens, timing under load, and other applications' accessibility still require an authorized desktop session.

```sh
python3 -m unittest discover -s compat/tests -v
python3 compat/run.py --engine keysharp --executable /path/to/Keysharp --output compat/reports/macos.json
python3 compat/compare.py compat/reports/ahk-windows.json compat/reports/macos.json
```

On Windows, use `--engine ahk --executable C:\path\to\AutoHotkey64.exe`. Alternatively, pass `--baseline compat/reports/ahk-windows.json` directly to the runner. Nonzero status means a failed case, timeout, unsupported result, or comparison difference; generating a JSON report does not establish a pass.

The full upstream suite includes interactive tests and must not be run unattended without a filter. Unattended custom scripts should use `#ErrorStdOut` and `#Warn All, StdOut` to avoid modal error and warning dialogs.

Committing these workflows does not imply a GitHub Actions run or a physical macOS test. Record actual run URLs and tested OS/architecture before publishing compatibility claims.

## Packages

The [manual package workflow](../.github/workflows/macos-packages.yml) builds unsigned Apple Silicon and Intel packages. Trigger Actions → macOS packages → Run workflow. It uploads workflow artifacts without creating a GitHub release or publishing externally.

To package on a Mac:

```sh
bash scripts/macos/bootstrap.sh
ETO_DIR="$PWD/.deps/Eto" AUTO_SIGN=false SKIP_SIGN=true SKIP_NOTARIZE=true \
  bash Keysharp.Install/package-macos.sh
```

Set `RID=osx-arm64` or `RID=osx-x64` explicitly to choose a target. Upstream packaging creates `.pkg` and `.dmg` files in `dist/`; bundle names remain Keysharp and Keyview. A signed public release requires your Apple identities and notarization configuration; upstream supports `APP_CERT`, `INSTALLER_CERT`, and `NOTARY_PROFILE`.

## Source provenance

`UPSTREAM.lock.json` records the exact Keysharp snapshot, Eto dependency, and Windows reference archive. [`license.txt`](../license.txt) retains upstream and bundled third-party notices. The fork adds tooling and compatibility infrastructure; the engine and macOS backends are credited to Keysharp contributors.
