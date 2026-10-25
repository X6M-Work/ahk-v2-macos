#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))
trace := ""
class Tracked {
    __Delete() {
        global trace
        trace .= "deleted"
    }
}
a := Tracked()
b := a
a := 0
FileAppend("aliased:" trace "`n", "*", "UTF-8-RAW")
b := 0
FileAppend("released:" trace "`n", "*", "UTF-8-RAW")
ExitApp()
