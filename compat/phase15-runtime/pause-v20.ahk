#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))
done := false
CheckPause() {
    global done
    Pause(1)
    FileAppend("paused:" A_IsPaused "`n", "*", "UTF-8-RAW")
    Pause(0)
    FileAppend("resumed:" A_IsPaused "`n", "*", "UTF-8-RAW")
    done := true
}
SetTimer(CheckPause, -20)
deadline := A_TickCount + 3000
while !done && A_TickCount < deadline
    Sleep(10)
FileAppend("done:" done "`n", "*", "UTF-8-RAW")
ExitApp()
