#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

h := DllCall("libSystem.B.dylib\dlopen", "AStr", "/usr/lib/libz.1.dylib", "Int", 1, "Ptr")
fn := DllCall("libSystem.B.dylib\dlsym", "Ptr", h, "AStr", "zlibVersion", "Ptr")
ver := DllCall(fn, "AStr")
rc := DllCall("libSystem.B.dylib\dlclose", "Ptr", h, "Int")

ok := (h != 0) && (fn != 0) && (RegExMatch(ver, "^\d+\.\d+") > 0) && (rc == 0)
FileAppend("dlopen-zlib:" (ok ? "ok" : (h != 0) "|" (fn != 0) "|" ver "|" rc) "`n", "*", "UTF-8-RAW")
ExitApp()
