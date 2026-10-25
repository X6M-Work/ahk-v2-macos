#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))
value := DllCall("/usr/lib/libSystem.B.dylib\sqrtf", "Float", 2.0, "Float")
FileAppend(Format("return|{:.17g}`n", value), "*", "UTF-8-RAW")
ExitApp()
