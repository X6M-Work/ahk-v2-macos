#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))
First(reason, code) => FileAppend("first:" reason ":" code "`n", "*", "UTF-8-RAW")
Second(reason, code) => FileAppend("second:" reason ":" code "`n", "*", "UTF-8-RAW")
Removed(reason, code) => FileAppend("removed`n", "*", "UTF-8-RAW")
OnExit(Second)
OnExit(First, -1)
OnExit(Removed)
OnExit(Removed, 0)
ExitApp()
