#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))
cancelled := 0
hits := 0
CancelledTick() {
    global cancelled
    cancelled += 1
}
Tick() {
    global hits
    hits += 1
    if hits = 3
        SetTimer(Tick, 0)
}
SetTimer(CancelledTick, -100)
SetTimer(CancelledTick, 0)
SetTimer(Tick, 20)
deadline := A_TickCount + 3000
while hits < 3 && A_TickCount < deadline
    Sleep(10)
SetTimer(Tick, 0)
Sleep(150)
FileAppend("cancelled:" cancelled "`nhits:" hits "`n", "*", "UTF-8-RAW")
ExitApp()
