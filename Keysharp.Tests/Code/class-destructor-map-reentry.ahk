#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#Warn LocalSameAsGlobal, Off
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message ":" err.Line ":" err.Stack "`n", "**", "UTF-8-RAW"), ExitApp(1)))
Check(actual, expected, tag) {
    if actual != expected {
        FileAppend("FAIL:" tag ":" actual ":" expected "`n", "*", "UTF-8-RAW")
        ExitApp(1)
    }
}
trace := ""
class MapValue {
    __New(label) {
        this.Label := label
    }
    __Delete() {
        global trace
        trace .= this.Label "|"
    }
}
Mark(label) {
    global trace
    trace .= label "|"
}
class ClearMapOnDelete {
    __Delete() {
        global mapping, trace
        trace .= "clear|"
        mapping.Clear()
    }
}
mapping := Map("a", MapValue("current"), "b", MapValue("tail"))
iterator := mapping.__Enum(2)
key := ClearMapOnDelete()
iterator(&key, &value)
Check(value.Label, "current", "both enum outputs protected before first assignment")
Check(trace, "clear|tail|", "current value survives reentrant Clear")
value := 0
Check(trace, "clear|tail|current|", "current output released once")
iterator := 0
mapping := 0
FileAppend("pass`n", "*", "UTF-8-RAW")
ExitApp()
