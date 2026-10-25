#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))
OnExit((reason, code) => FileAppend("exit:" reason ":" code "`n", "*", "UTF-8-RAW"))
ExitApp(17)
