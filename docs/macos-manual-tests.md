# Native macOS verification

Not executed by the Windows validation session. Run separately on Apple Silicon and Intel.

Record macOS version, architecture, SDK, source commit, Eto commit and signing identity with the results. Build without Rosetta when testing native architecture.

| Check | Procedure | Expected result |
|---|---|---|
| Startup | `bash scripts/macos/ahk run examples/macos/hello.ahk` | One message box, clean exit after dismissing it |
| GUI | Run `examples/macos/gui.ahk`; edit the text and press the button | Native window, updated greeting, close exits the process |
| Global input | Run `examples/macos/hotkeys.ahk`; focus a plain-text editor; press F6, then F8 | Text appears once; F8 exits |
| Timers | Run `examples/macos/timer.ahk`; focus an editor; press F6, wait, press F6 again | Numbered text about once per second, then no more text |
| Cancellation | Enable the timer and press F8 | Process exits and produces no more input |
| Permission denied | Decline Accessibility/Input Monitoring on first use | No fabricated success; record the error or unavailable behavior |
| Permission granted | Grant the required permissions, restart the script | Hotkeys and text synthesis work in the editor |
| Layout | Repeat text input with the keyboard layouts being supported | Correct characters and modifier behavior |
| Packaging | Install the generated package on a clean macOS 15+ account with .NET 10 | App starts and file associations work as documented upstream |

Grant permissions in System Settings > Privacy & Security to the process macOS identifies. Check input, GUI, clipboard, screen capture, Retina/multiple displays and target applications separately before claiming support for them. Headless corpus results do not validate these features.

The examples are interactive and are deliberately excluded from unattended conformance runs.
