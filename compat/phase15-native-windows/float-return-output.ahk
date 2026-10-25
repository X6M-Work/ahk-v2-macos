#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))
value := DllCall("ucrtbase\sqrtf", "Float", 2.0, "CDecl Float")
FileAppend(Format("return|{:.17g}`n", value), "*", "UTF-8-RAW")
output := 0.0
count := DllCall("msvcrt\sscanf", "AStr", "1.2345", "AStr", "%f", "Float*", &output, "CDecl Int")
FileAppend(Format("output|{}|{:.17g}`n", count, output), "*", "UTF-8-RAW")
ExitApp()
