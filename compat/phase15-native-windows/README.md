# Windows Float ABI reference

This Windows-only corpus checks the exact Float32-to-Float64 value returned by `ucrtbase\sqrtf` and written through a `Float*` output parameter by `msvcrt\sscanf`. Both libraries are supplied by Windows; no custom native binary or compiler is required.

The fixtures pass official AutoHotkey 2.0.31. The original Keysharp binary rounded through a short decimal representation; its return and output values both differed. The compatibility correction retains the exact binary Float32 value in v2.0 mode.

```powershell
python compat/run.py --engine ahk --executable C:/tools/AutoHotkey64.exe --corpus compat/phase15-native-windows --output compat/reports/native-windows-ahk.json
python compat/run.py --engine keysharp --executable bin/Debug/net10.0-windows/Keysharp.exe --corpus compat/phase15-native-windows --output compat/reports/native-windows-keysharp.json --baseline compat/reports/native-windows-ahk.json
```

Other platforms report `unsupported`, not a passing Windows ABI gate. `compat/phase15-architecture/macos/sqrtf.ahk` is a separate pending capability probe against libSystem.
