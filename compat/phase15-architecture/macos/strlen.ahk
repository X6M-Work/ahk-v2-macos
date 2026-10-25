#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))
length := DllCall("/usr/lib/libSystem.B.dylib\strlen", "AStr", "macos", "UPtr")
FileAppend("length:" length "`n", "*", "UTF-8-RAW")
ExitApp()
