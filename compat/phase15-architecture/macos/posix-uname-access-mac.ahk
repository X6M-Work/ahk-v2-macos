#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

uts := Buffer(1280, 0)
rc := DllCall("libSystem.B.dylib\uname", "Ptr", uts, "Int")
sysname := StrGet(uts, 256, "UTF-8")
ppid := DllCall("libSystem.B.dylib\getppid", "Int")
acc := DllCall("libSystem.B.dylib\access", "AStr", "/bin/sh", "Int", 1, "Int")

ok := (rc == 0) && (sysname == "Darwin") && (ppid > 0) && (acc == 0)
FileAppend("posix-uname:" (ok ? "ok" : rc "|" sysname "|" ppid "|" acc) "`n", "*", "UTF-8-RAW")
ExitApp()
