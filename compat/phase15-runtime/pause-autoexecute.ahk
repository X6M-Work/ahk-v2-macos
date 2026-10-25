#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))
hits := 0
Tick() {
    global hits
    hits += 1
}
Pause(1)
SetTimer(Tick, -20)
Sleep(120)
FileAppend("paused:" hits "`n", "*", "UTF-8-RAW")
Pause(0)
deadline := A_TickCount + 3000
while hits = 0 && A_TickCount < deadline
    Sleep(10)
FileAppend("released:" hits "`n", "*", "UTF-8-RAW")
ExitApp()
