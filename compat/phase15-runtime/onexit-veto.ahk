#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))
attempts := 0
CheckExit(reason, code) {
    global attempts
    attempts += 1
    FileAppend("attempt:" attempts ":" reason ":" code "`n", "*", "UTF-8-RAW")
    return attempts = 1
}
Finish() => ExitApp(0)
OnExit(CheckExit)
SetTimer(Finish, -150)
ExitApp(5)
