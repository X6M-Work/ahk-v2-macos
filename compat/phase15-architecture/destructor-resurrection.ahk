#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))
calls := 0
saved := 0
class Resurrecting {
    __Delete() {
        global calls, saved
        calls += 1
        if calls = 1
            saved := this
    }
}
owned := Resurrecting()
owned := 0
FileAppend("first:" calls ":" IsObject(saved) "`n", "*", "UTF-8-RAW")
saved := 0
FileAppend("second:" calls "`n", "*", "UTF-8-RAW")
ExitApp()
