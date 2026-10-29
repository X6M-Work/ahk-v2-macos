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
trace := ""
ReplaceMapReceiver() {
    global mapping
    mapping := Map("x", MapValue("replacement"))
    return "x"
}
ReplaceMapReceiverSpread() => [ReplaceMapReceiver()]
ReadMapReceiver() {
    global mapping
    return mapping
}
mapping := Map("x", MapValue("original"))
value := mapping.Get(ReplaceMapReceiver())
Check(value.Label, "replacement", "method resolves named receiver after arguments")
Check(trace, "original|", "argument mutation releases original receiver before call")
mapping := 0
value := 0
Check(trace, "original|replacement|", "replacement result keeps independent owner")
trace := ""
mapping := Map("x", MapValue("grouped-original"))
value := (mapping).Get(ReplaceMapReceiver())
Check(value.Label, "replacement", "parentheses preserve named receiver resolution")
mapping := 0
value := 0
Check(trace, "grouped-original|replacement|", "grouped receiver owners balance")
trace := ""
mapping := Map("x", MapValue("computed-original"))
value := ReadMapReceiver().Get(ReplaceMapReceiver())
Check(value.Label, "computed-original", "computed receiver is evaluated before arguments")
mapping := 0
value := 0
Check(trace, "replacement|computed-original|", "computed receiver result owns its value")
trace := ""
mapping := Map("x", MapValue("spread-original"))
value := mapping.Get(ReplaceMapReceiverSpread()*)
Check(value.Label, "replacement", "spread evaluates before named receiver resolution")
mapping := 0
value := 0
Check(trace, "spread-original|replacement|", "spread receiver owners balance")
trace := ""
ReceiverMethodName() {
    global trace
    trace .= "name|"
    return "Get"
}
mapping := Map("x", MapValue("dynamic-original"))
value := mapping.%ReceiverMethodName()%(ReplaceMapReceiver())
Check(value.Label, "replacement", "computed method name preserves late receiver")
Check(trace, "name|dynamic-original|", "method name evaluates before arguments")
mapping := 0
value := 0
trace := ""
method := "Get"
ChangeReceiverMethod() {
    global method
    method := "Has"
    return "x"
}
mapping := Map("x", 10)
Check(mapping.%method%(ChangeReceiverMethod()), 1, "variable method name resolves after arguments")
ChangeLocalReceiver(&target) {
    target := Map("x", 20)
    return "x"
}
ReadLocalReceiver() {
    local target := Map("x", 10)
    return target.Get(ChangeLocalReceiver(&target))
}
Check(ReadLocalReceiver(), 20, "local receiver resolves after byref argument mutation")
ReadByRefReceiver(&target) => target.Get(ChangeLocalReceiver(&target))
Check(ReadByRefReceiver(&mapping), 20, "byref receiver resolves after argument mutation")
mapping := 0
ReplaceNumberReceiver() {
    global mapping
    mapping := Map("x", 20)
    return "x"
}
ReplaceNumberValue() {
    ReplaceNumberReceiver()
    return 1
}
mapping := Map("x", 10)
Check(mapping[ReplaceNumberReceiver()], 20, "index resolves named receiver after arguments")
mapping := Map("x", 10)
Check((mapping)[ReplaceNumberReceiver()], 20, "grouped index receiver remains a variable")
mapping := Map("x", 10)
Check(ReadMapReceiver()[ReplaceNumberReceiver()], 10, "computed index receiver remains captured")
holder := {Values: Map("x", 10)}
ReplacePropertyMap() {
    global holder
    holder.Values := Map("x", 20)
    return "x"
}
Check(holder.Values[ReplacePropertyMap()], 20, "indexed property resolves after its index arguments")
mapping := Map("x", 10)
mapping[ReplaceNumberReceiver()] := 30
Check(mapping["x"], 30, "index setter resolves receiver after index arguments")
mapping := Map("x", 10)
mapping["x"] := ReplaceNumberValue()
Check(mapping["x"], 1, "index setter resolves receiver after RHS")
mapping := Map("x", 10)
mapping.P := ReplaceNumberValue()
Check(mapping.P, 1, "property setter resolves receiver after RHS")
mapping := Map("x", 10)
mapping["x"] += ReplaceNumberValue()
Check(mapping["x"], 11, "compound index reads old value then resolves receiver for write")
mapping := Map("x", 10)
mapping.P := 10
mapping.P += ReplaceNumberValue()
Check(mapping.P, 11, "compound property resolves receiver again after RHS")
mapping := 0
holder := 0
key := "old"
ChangeMapKey() {
    global key
    key := "new"
    return 40
}
mapping := Map()
mapping.Set(key, ChangeMapKey())
Check(mapping.Has("old"), 0, "bare key argument resolves after other arguments")
Check(mapping["new"], 40, "bare key argument selects current key")
key := "old"
mapping := Map(key, ChangeMapKey())
Check(mapping["new"], 40, "constructor resolves bare arguments after other arguments")
key := "old"
ReadMapReceiver().Set(key, ChangeMapKey())
Check(mapping["new"], 40, "computed receiver preserves deferred variable arguments")
mapping.Set("x", key := "first", "y", ChangeMapKey())
Check(mapping["x"], "new", "assignment argument evaluates once then resolves its variable")
Check((mapping := Map("x", 10)).Get(ReplaceNumberReceiver()), 20, "assignment receiver evaluates once then resolves its variable")
mapping := Map("x", 10)
Check(mapping[ReplaceNumberReceiver()]++, 20, "postfix reads receiver after index evaluation")
Check(mapping["x"], 21, "postfix writes current receiver")
mapping := Map("x", 10)
Check(++mapping[ReplaceNumberReceiver()], 21, "prefix reads receiver after index evaluation")
mapping := Map("x", 10)
mapping[ReplaceNumberReceiver()] += 2
Check(mapping["x"], 22, "compound index resolves receiver after index evaluation")
mapping := Map("x", 10)
mapping.P := 10
name := "P"
mapping.%name% += ReplaceNumberValue()
Check(mapping.P, 11, "compound dynamic property resolves receiver after RHS")
ReplaceNumberSpread() => [ReplaceNumberReceiver()]
mapping := Map("x", 10)
Check(mapping[ReplaceNumberSpread()*], 20, "spread index resolves receiver after argument expansion")
mapping := Map("x", 10)
mapping[ReplaceNumberSpread()*] := 30
Check(mapping["x"], 30, "spread setter resolves receiver after argument expansion")
mapping := 0
FileAppend("pass`n", "*", "UTF-8-RAW")
ExitApp()
