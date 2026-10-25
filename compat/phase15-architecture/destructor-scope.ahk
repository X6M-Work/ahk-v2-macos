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
MakeLocal() {
    local owned := Tracked()
    return Type(owned)
}
MakeLocal()
FileAppend("returned:" trace "`n", "*", "UTF-8-RAW")
ExitApp()
