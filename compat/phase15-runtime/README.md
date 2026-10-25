# Scheduler and process lifecycle characterization

Eight fixtures compare the actual AutoHotkey 2.0.31 executable with Keysharp: one-shot timers, cancelling before launch, repeating timer cancellation, non-reentrant overruns, Critical buffering, underlying-thread Pause, Pause without an underlying thread, and OnExit order/removal/veto. Timing assertions concern event counts and order; they use generous deadlines rather than exact milliseconds. A failed deadline is a test failure, never an unsupported result.

```powershell
python compat/run.py --engine ahk --executable C:/tools/AutoHotkey64.exe --engine-version 2.0.31 --corpus compat/phase15-runtime --output compat/reports/phase15-runtime-ahk.json
python compat/run.py --engine keysharp --executable bin/Debug/net10.0-windows/Keysharp.exe --corpus compat/phase15-runtime --output compat/reports/phase15-runtime-keysharp.json --baseline compat/reports/phase15-runtime-ahk.json
```

Three additional standalone process fixtures verify ExitApp(17), an OnError handler writing stderr then ExitApp(23), and continuation after a TypeError with OnError returning -1. They need explicit expected exit codes, so `run_processes.py` uses the shared runner's isolation, closed stdin, daemon disabling, timeout and process-tree cleanup, with strict stdout/stderr/code checks.

```powershell
python compat/phase15-runtime/run_processes.py --engine ahk --executable C:/tools/AutoHotkey64.exe --output compat/reports/phase15-processes-ahk.json
python compat/phase15-runtime/run_processes.py --engine keysharp --executable bin/Debug/net10.0-windows/Keysharp.exe --output compat/reports/phase15-processes-keysharp.json --baseline compat/reports/phase15-processes-ahk.json
```

On macOS use `python3` and the local Keysharp `.dll` path. Keep the official Windows report as the baseline. Report durations are informational. The process report schema is specific to these lifecycle probes and is not accepted by `compat/compare.py`.

All fixtures are noninteractive and declare ErrorStdOut and StdOut warnings. Unexpected errors have an OnError handler that writes stderr and exits. The continuation fixture handles only the expected TypeError. These results do not establish native macOS behavior, scheduling under load, hotkey interaction, menu behavior, Reload, multiple real threads, or complete lifecycle compatibility.
