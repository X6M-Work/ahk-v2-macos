# Self-Reload lifecycle gate

`run_reload.py` places a Python controller and the engine inside the shared runner's isolated Job Object or process group. The controller remains alive while the script replaces its original process. This preserves containment until the replacement writes its completion marker and actually exits. A timeout or failure closes the entire process tree.

The trusted fixture uses a private temporary working directory, `#SingleInstance Off`, `#NoTrayIcon`, stdout warnings and an OnError stderr handler. It verifies the first OnExit reason/code, fresh state after replacement, termination of the old PID, a timer in the new instance, and its final OnExit reason/code. It does not use input, dialogs or application automation. Reload arguments and initial working-directory inheritance are not part of this case.

```powershell
python compat/phase15-reload/run_reload.py --engine ahk --executable C:/tools/AutoHotkey64.exe --output compat/reports/reload-ahk.json
python compat/phase15-reload/run_reload.py --engine keysharp --executable bin/Debug/net10.0-windows/Keysharp.exe --output compat/reports/reload-keysharp.json --baseline compat/reports/reload-ahk.json
```

Default timeout: 30 seconds, including engine compilation and both processes. Both complete successfully on the tested Windows build. This is a standalone lifecycle report using `expected`/`actual` fields, not a manifest consumed by `compat/run.py` or a report accepted by `compat/compare.py`.

The Windows replacement is checked through a synchronization handle; POSIX uses a non-signaling process-existence check. No PID outside the contained tree is terminated by the controller. Cleanup retries briefly after Job Object closure because Windows may release a terminated process's working directory asynchronously.

macOS execution remains pending. A passing Windows case does not verify native macOS Reload, termination signals, AppKit teardown or framework loading.
