# Object lifetime architecture gate

These five unmodified, noninteractive fixtures distinguish AHK reference counting from delayed .NET collection. They never request a collection, wait for a finalizer or call `__Delete` directly. All five pass official AutoHotkey 2.0.31 on Windows; all five fail the existing Keysharp binary.

```powershell
python compat/run.py --engine ahk --executable C:/tools/AutoHotkey64.exe --engine-version 2.0.31 --corpus compat/phase15-architecture --output compat/reports/phase15-architecture-ahk.json
python compat/run.py --engine keysharp --executable bin/Debug/net10.0-windows/Keysharp.exe --corpus compat/phase15-architecture --output compat/reports/phase15-architecture-keysharp.json --baseline compat/reports/phase15-architecture-ahk.json
```

The second command must fail until the ownership implementation changes. Matching a reference failure or adding `Collect()` is not conformance. `file-scope-close` requires an observable flush and release at function return; the deny-sharing flag also makes the unclosed handle observable on Windows. POSIX sharing semantics differ, so that part alone is not a macOS proof.

`macos/` is a separate capability corpus for macOS native ABI checks: `/usr/lib/libSystem.B.dylib` (`getpid`, ASCII `strlen`, `qsort` calling a script comparator through `CallbackCreate`, and `sqrtf` Float32 return) plus `float-return-output.ahk`, which compiles `parse-float.c` (`int parse_float(const char *text, float *output)` calling `sscanf(..., "%f", output)`) on the runner with `/usr/bin/clang` to verify both `sqrtf` Float32 return and `"Float*", &output` rewriting in AHK v2.0 mode. These are not Windows-equivalence tests. Expected outputs follow the C contracts and still require real Intel and Apple Silicon runs. On other platforms the manifest reports `unsupported` and fails the gate.

```sh
python3 compat/run.py --engine keysharp --executable bin/Debug/net10.0/Keysharp.dll --corpus compat/phase15-architecture/macos --output compat/reports/phase15-native-macos.json
```

Every process has an external timeout and cleanup through the shared runner. These trusted local fixtures do not touch keyboard, mouse, clipboard or GUI. The error handler writes to stderr and exits; the native callback is freed in `finally`.
