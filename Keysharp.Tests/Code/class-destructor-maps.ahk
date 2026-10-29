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
MakeMap() => Map("x", MapValue("returned"))
mapping := Map("c", MapValue("C"), "a", MapValue("A"), "b", MapValue("B"))
alias := mapping
mapping := mapping
mapping := 0
Check(trace, "", "alias keeps entries")
alias := 0
Check(trace, "C|B|A|", "last alias releases in reverse key order")
trace := ""
mapping := Map(3, MapValue("3"), 1, MapValue("1"), 2, MapValue("2"))
mapping.Clear()
Check(trace, "3|2|1|", "Clear releases in reverse numeric order")
trace := ""
key := MapValue("key")
mapping := Map(key, MapValue("value"))
key := 0
mapping := 0
Check(trace, "value|key|", "value is released before object key")
trace := ""
mapping := Map(MapValue("key1"), MapValue("value1"), MapValue("key2"), MapValue("value2"))
expected := ""
for key, value in mapping
    expected := value.Label "|" key.Label "|" expected
mapping := 0
Check(trace, expected, "object keys release in reverse enumeration order")
trace := ""
shared := MapValue("shared")
mapping := Map(shared, shared)
shared := 0
mapping := 0
Check(trace, "shared|", "key and value have independent owners")
trace := ""
mapping := Map("x", MapValue("old"))
mapping["x"] := mapping["x"]
Check(trace, "", "same element replacement")
mapping["x"] := MapValue("new"), Mark("after-set")
Check(trace, "old|after-set|", "replacement releases before next expression")
trace := ""
removed := mapping.Delete("x")
Check(trace, "", "Delete transfers result")
removed := 0
Check(trace, "new|", "Delete result owns value")
trace := ""
mapping := Map("x", MapValue("ignored"))
mapping.Delete("x")
Check(trace, "ignored|", "discarded Delete result expires")
trace := ""
mapping := Map()
mapping.CaseSense := "Off"
mapping["KEY"] := MapValue("case-old")
mapping.Set("key", MapValue("case-new"))
Check(trace, "case-old|", "equivalent key replaces only value")
Check(mapping.Count, 1, "equivalent key keeps one entry")
for key in mapping
    Check(key, "KEY", "original key retained")
mapping := 0
Check(trace, "case-old|case-new|", "case-insensitive entry released once")
trace := ""
mapping := Map("x", MapValue("clone"))
cloned := mapping.Clone()
mapping.Clear()
Check(trace, "", "Clone owns independent entries")
cloned := 0
Check(trace, "clone|", "last cloned entry releases")
trace := ""
mapping := MakeMap()
value := mapping.Get("x")
mapping := 0
Check(trace, "", "Get result survives Map")
value := 0
Check(trace, "returned|", "returned Map transfers its entries")
trace := ""
mapping := Map("x", MapValue("first"))
mapping.__New("y", MapValue("second"))
Check(mapping.Count, 2, "explicit __New adds entries")
mapping.Clear()
Check(trace, "second|first|", "__New entries own their values")
trace := ""
mapping := Map("x", [MapValue("nested")])
mapping := 0
Check(trace, "nested|", "nested Array released through Map")
trace := ""
values := [Map("x", MapValue("nested-map"))]
values := 0
Check(trace, "nested-map|", "nested Map released through Array")
trace := ""
for key, value in Map("a", MapValue("A"), "b", MapValue("B")) {
    Mark(value.Label)
    break
}
Check(trace, "A|B|A|", "break disposes source before restoring outputs")
trace := ""
try {
    for key, value in Map("x", MapValue("exception"))
        throw Error("expected")
} catch {
}
Check(trace, "exception|", "exception disposes enumerated source")
trace := ""
mapping := Map("a", MapValue("a"), "b", MapValue("b"))
iterator := mapping.__Enum(2)
mapping := 0
Check(trace, "", "exported enumerator owns Map")
while iterator(&key, &value) {
}
key := 0
value := 0
Check(trace, "", "completed enumerator still owns Map")
iterator := 0
Check(trace, "b|a|", "enumerator release destroys source")
trace := ""
mapping := Map("a", MapValue("kept"), "b", MapValue("deleted"))
iterator := mapping.__Enum(2)
mapping.Delete("b")
Check(trace, "deleted|", "enumeration does not retain removed entries")
Check(iterator(&key, &value), 1, "enumeration after removal")
Check(value.Label, "kept", "enumeration sees remaining value")
key := 0
value := 0
iterator := 0
mapping := 0
Check(trace, "deleted|kept|", "remaining entry released")
trace := ""
mapping := Map("x", MapValue("omitted"))
mapping.Set("a", MapValue("a"), unset, MapValue("discarded"), "x", unset)
Check(trace, "discarded|", "unset key or value skips pair without replacing")
Check(mapping.Count, 2, "Set skips omitted pairs")
mapping.Set()
Check(mapping.Count, 2, "empty Set preserves entries")
try mapping.Set("bad", MapValue("odd"), "orphan")
catch {
}
Check(trace, "discarded|odd|", "odd Set releases temporaries")
Check(mapping.Count, 2, "odd Set validates before mutation")
mapping.Capacity := 64
Check(mapping.Count, 2, "capacity preserves ownership")
mapping := 0
Check(trace, "discarded|odd|omitted|a|", "skipped pairs do not leak ownership")
trace := ""
class ObserveMapCount {
    __New(label) {
        this.Label := label
    }
    __Delete() {
        global mapping, trace
        trace .= this.Label ":" mapping.Count ":" mapping.Has("a") ":" mapping.Has("b") "|"
    }
}
mapping := Map("a", ObserveMapCount("A"), "b", ObserveMapCount("B"))
mapping.Clear()
Check(trace, "B:1:1:0|A:0:0:0|", "Clear removes one entry before each destructor")
trace := ""
class FillMapOnDelete {
    __Delete() {
        global mapping, trace
        trace .= "old|"
        mapping["new"] := MapValue("added")
    }
}
mapping := Map("a", FillMapOnDelete(), "b", MapValue("tail"))
mapping.Clear()
Check(mapping.Count, 0, "Clear removes entries inserted by destructors")
Check(trace, "tail|old|added|", "reentrant Clear drains new entries")
mapping := 0
Check(trace, "tail|old|added|", "reentrant entry released")
trace := ""
class ResurrectIntoMap {
    __Delete() {
        global saved, trace, deletes
        deletes += 1
        trace .= deletes "|"
        if deletes = 1
            saved["resurrected"] := this
    }
}
deletes := 0
saved := Map()
value := ResurrectIntoMap()
value := 0
Check(trace, "1|", "Map retains during __Delete")
saved.Clear()
Check(trace, "1|2|", "Map releases resurrected instance")
saved := 0
FileAppend("pass`n", "*", "UTF-8-RAW")
ExitApp()
