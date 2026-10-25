#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
#SingleInstance Off
SetWorkingDir(A_ScriptDir)
OnError(ReportFailure)
ReportFailure(err, mode) {
    FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW")
    FileAppend(err.Message, "failed.txt", "UTF-8-RAW")
    ExitApp(1)
}
Record(text) => FileAppend(text "`n", "trace.txt", "UTF-8-RAW")
ticks := 0
second := false
OnExit(AtExit)
AtExit(reason, code) {
    global second
    Record("exit|" reason "|" code)
    if second && reason = "Exit"
        FileAppend(ProcessExist(), "done.txt", "UTF-8-RAW")
}
OldTick() {
    global ticks
    ticks += 1
}
Finish() {
    global ticks
    ticks += 1
    SetTimer(Finish, 0)
    Record("timer|" ticks)
    ExitApp()
}
if !FileExist("predecessor.txt") {
    FileAppend(ProcessExist(), "predecessor.txt", "UTF-8-RAW")
    Record("first|loaded")
    SetTimer(OldTick, 20)
    Reload()
    Sleep(25000)
    FileAppend("reload-incomplete`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
second := true
Record("second|loaded")
Record("fresh|" ticks)
oldPid := Integer(FileRead("predecessor.txt", "UTF-8"))
deadline := A_TickCount + 5000
while ProcessExist(oldPid) && A_TickCount < deadline
    Sleep(20)
Record("old-exited|" (!ProcessExist(oldPid)))
SetTimer(Finish, -20)
Sleep(10000)
FileAppend("timer-incomplete`n", "**", "UTF-8-RAW")
ExitApp(1)
