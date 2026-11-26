#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

rc0 := RunWait('/bin/sh -c "exit 0"')
rc7 := RunWait('/bin/sh -c "exit 7"')
myPid := ProcessExist()
myName := ProcessGetName(myPid)
myPath := ProcessGetPath(myPid)

ok := (rc0 == 0) && (rc7 == 7) && (myPid > 0) && (StrLen(myName) > 0) && (StrLen(myPath) > 0)
FileAppend("proc-runwait:" (ok ? "ok" : rc0 "|" rc7 "|" myPid "|" myName "|" myPath) "`n", "*", "UTF-8-RAW")
ExitApp()
