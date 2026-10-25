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
Critical("On")
SetTimer(Tick, -20)
Sleep(120)
FileAppend("critical:" hits "`n", "*", "UTF-8-RAW")
Critical("Off")
deadline := A_TickCount + 3000
while hits = 0 && A_TickCount < deadline
    Sleep(10)
FileAppend("released:" hits "`n", "*", "UTF-8-RAW")
ExitApp()
