#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))
pid := DllCall("/usr/lib/libSystem.B.dylib\getpid", "Int")
FileAppend("positive-pid:" (pid > 0) "`n", "*", "UTF-8-RAW")
ExitApp()
