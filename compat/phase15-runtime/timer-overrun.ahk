#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))
hits := 0
depth := 0
maximum := 0
Tick() {
    global hits, depth, maximum
    depth += 1
    maximum := Max(maximum, depth)
    hits += 1
    Sleep(80)
    if hits = 3
        SetTimer(Tick, 0)
    depth -= 1
}
SetTimer(Tick, 20)
deadline := A_TickCount + 4000
while hits < 3 && A_TickCount < deadline
    Sleep(10)
SetTimer(Tick, 0)
Sleep(150)
FileAppend("hits:" hits "`nmaximum-depth:" maximum "`n", "*", "UTF-8-RAW")
ExitApp()
