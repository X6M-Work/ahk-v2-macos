#Requires AutoHotkey v2.0
#SingleInstance Force

enabled := false
count := 0
OnExit Stop

F6:: {
    global enabled
    enabled := !enabled
    SetTimer Tick, enabled ? 1000 : 0
}

F8::ExitApp

Tick() {
    global count
    count += 1
    SendText "tick " count " "
}

Stop(*) {
    SetTimer Tick, 0
}
