#Requires AutoHotkey v2.1-alpha.1
#ErrorStdOut
#Warn All, StdOut
#Warn LocalSameAsGlobal, Off
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message ":" err.Line "`n", "**", "UTF-8-RAW"), ExitApp(1)))
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
mapping := ["x": MapValue("literal")]
mapping := 0
Check(trace, "literal|", "compiled Map literal owns entries")
trace := ""
mapping := Map("a", MapValue("A"), "b", MapValue("B"))
iterator := mapping.__Enum(2)
mapping.Delete("b")
Check(trace, "", "native snapshot owns removed value")
iterator(&key, &value)
mapping.Clear()
Check(trace, "", "native snapshot survives Clear")
Check(value.Label, "A", "first snapshot value")
iterator(&key, &value)
Check(value.Label, "B", "removed snapshot value remains usable")
value := 0
iterator := 0
Check(trace, "B|A|", "snapshot releases entries when enumerator released")
trace := ""
mapping := Map("a", MapValue("old"), "b", 2)
iterator := mapping.__Enum(2)
mapping["a"] := MapValue("new")
Check(trace, "old|", "cached snapshot follows existing value replacement")
iterator(&key, &value)
Check(value.Label, "new", "updated snapshot value")
value := 0
mapping.Clear()
iterator := 0
Check(trace, "old|new|", "updated snapshot balances references")
trace := ""
pairs := ["x", MapValue("pairs")]
mapping.Set(pairs)
pairs := 0
Check(trace, "", "Set from Array retains value")
mapping["x"] := unset
Check(trace, "pairs|", "unset item removes entry")
trace := ""
source := Map("x", MapValue("shared"))
mapping := Map("old", MapValue("old-storage"))
mapping.Set(source)
Check(trace, "old-storage|", "adopting storage releases previous entries")
source["y"] := 2
Check(mapping["y"], 2, "adopted storage remains shared")
source := 0
Check(mapping["x"].Label, "shared", "shared storage remains usable")
mapping.Set(mapping)
Check(mapping["x"].Label, "shared", "self storage adoption")
mapping := 0
FileAppend("pass`n", "*", "UTF-8-RAW")
ExitApp()
