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
class OwnedValue {
    __New(label) => this.Label := label
    __Delete() {
        global trace
        trace .= this.Label "|"
    }
}
class OwnedMap extends Map {
    Field := OwnedValue("map-field")
    __Delete() {
        global trace
        trace .= "map-delete|"
    }
}
class OwnedArray extends Array {
    Field := OwnedValue("array-field")
    __Delete() {
        global trace
        trace .= "array-delete|"
    }
}
mapping := OwnedMap("x", OwnedValue("map-item"))
alias := mapping
mapping := mapping
mapping := 0
Check(trace, "", "Map alias keeps subclass and children alive")
alias := 0
Check(trace, "map-delete|map-item|map-field|", "Map subclass releases entries then own fields")
trace := ""
values := OwnedArray(OwnedValue("array-item"))
alias := values
values := values
values := 0
Check(trace, "", "Array alias keeps subclass and children alive")
alias := 0
Check(trace, "array-delete|array-item|array-field|", "Array subclass releases elements then own fields")
trace := ""
mapping := OwnedMap("x", OwnedValue("shared-map"))
cloned := mapping.Clone()
Check(cloned is OwnedMap, 1, "Map Clone keeps subclass")
mapping := 0
Check(trace, "map-delete|", "Map clone owns independent entry and property edges")
cloned := 0
Check(trace, "map-delete|map-delete|shared-map|map-field|", "Map clone releases shared values once")
trace := ""
values := OwnedArray(OwnedValue("shared-array"))
cloned := values.Clone()
Check(cloned is OwnedArray, 1, "Array Clone keeps subclass")
values := 0
Check(trace, "array-delete|", "Array clone owns independent element and property edges")
cloned := 0
Check(trace, "array-delete|array-delete|shared-array|array-field|", "Array clone releases shared values once")
class MapLayer extends Map {
    __New(label) {
        super.__New("x", OwnedValue(label))
        this.Field := OwnedValue("layer-field")
    }
    __Delete() {
        global trace
        trace .= "layer-delete|"
    }
}
class MapLeaf extends MapLayer {
}
class ArrayLayer extends Array {
    __New(label) {
        super.__New(OwnedValue(label))
        this.Field := OwnedValue("layer-field")
    }
    __Delete() {
        global trace
        trace .= "layer-delete|"
    }
}
class ArrayLeaf extends ArrayLayer {
}
trace := ""
mapping := MapLeaf("leaf-map")
mapping := 0
Check(trace, "layer-delete|leaf-map|layer-field|", "Map inherits constructor and destructor through multiple levels")
trace := ""
values := ArrayLeaf("leaf-array")
values := 0
Check(trace, "layer-delete|leaf-array|layer-field|", "Array inherits constructor and destructor through multiple levels")
class ArrayOverride extends ArrayLayer {
    __Delete() {
        global trace
        trace .= "leaf-delete|"
        super.__Delete()
    }
}
trace := ""
values := ArrayOverride("override")
values := 0
Check(trace, "leaf-delete|layer-delete|override|layer-field|", "explicit super destructor executes once")
class MapWithoutSuper extends Map {
    __New() => this["x"] := OwnedValue("map-no-super")
}
class ArrayWithoutSuper extends Array {
    __New() => this.Push(OwnedValue("array-no-super"))
}
trace := ""
mapping := MapWithoutSuper()
mapping := 0
Check(trace, "map-no-super|", "Map storage counts owners without super constructor")
trace := ""
values := ArrayWithoutSuper()
values := 0
Check(trace, "array-no-super|", "Array storage counts owners without super constructor")
class FailedMap extends OwnedMap {
    __New() {
        super.__New("x", OwnedValue("failed-map"))
        throw Error("expected")
    }
}
class FailedArray extends OwnedArray {
    __New() {
        super.__New(OwnedValue("failed-array"))
        throw Error("expected")
    }
}
trace := ""
try FailedMap()
catch {
}
Check(trace, "map-delete|failed-map|map-field|", "failed Map constructor releases storage and fields")
trace := ""
try FailedArray()
catch {
}
Check(trace, "array-delete|failed-array|array-field|", "failed Array constructor releases storage and fields")
saved := 0
calls := 0
class ResurrectMap extends Map {
    __Delete() {
        global saved, calls, trace
        calls += 1
        trace .= "map-resurrect" calls "|"
        if calls = 1
            saved := this
    }
}
class ResurrectArray extends Array {
    __Delete() {
        global saved, calls, trace
        calls += 1
        trace .= "array-resurrect" calls "|"
        if calls = 1
            saved := this
    }
}
trace := ""
mapping := ResurrectMap("x", OwnedValue("resurrected-map"))
mapping := 0
Check(trace, "map-resurrect1|", "resurrected Map keeps entries")
Check(saved["x"].Label, "resurrected-map", "resurrected Map entry remains usable")
saved := 0
Check(trace, "map-resurrect1|map-resurrect2|resurrected-map|", "Map releases entries after second destructor")
trace := ""
calls := 0
values := ResurrectArray(OwnedValue("resurrected-array"))
values := 0
Check(trace, "array-resurrect1|", "resurrected Array keeps elements")
Check(saved[1].Label, "resurrected-array", "resurrected Array element remains usable")
saved := 0
Check(trace, "array-resurrect1|array-resurrect2|resurrected-array|", "Array releases elements after second destructor")
class MutatingMap extends Map {
    __Delete() {
        global trace
        trace .= "map-start|"
        this["x"] := OwnedValue("new-map")
        trace .= "map-end|"
    }
}
class MutatingArray extends Array {
    __Delete() {
        global trace
        trace .= "array-start|"
        this[1] := OwnedValue("new-array")
        trace .= "array-end|"
    }
}
trace := ""
mapping := MutatingMap("x", OwnedValue("old-map"))
mapping := 0
Check(trace, "map-start|old-map|map-end|new-map|", "Map replacement during destructor is not reentrant")
trace := ""
values := MutatingArray(OwnedValue("old-array"))
values := 0
Check(trace, "array-start|old-array|array-end|new-array|", "Array replacement during destructor is not reentrant")
trace := ""
mapping := OwnedMap("x", OwnedValue("enum-map"))
iterator := mapping.__Enum(2)
mapping := 0
Check(trace, "", "Map native enumerator retains subclass")
Check(iterator(&index, &value), 1, "Map subclass enumerates")
value := 0
index := 0
iterator := 0
Check(trace, "map-delete|enum-map|map-field|", "Map enumerator release releases subclass")
trace := ""
values := OwnedArray(OwnedValue("enum-array"))
iterator := values.__Enum(2)
values := 0
Check(trace, "", "Array native enumerator retains subclass")
Check(iterator(&index, &value), 1, "Array subclass enumerates")
value := 0
index := 0
iterator := 0
Check(trace, "array-delete|enum-array|array-field|", "Array enumerator release releases subclass")
class IndependentArray extends OwnedArray {
    __Enum(count) => [7].__Enum(count)
}
trace := ""
values := IndependentArray(OwnedValue("independent"))
iterator := values.__Enum(2)
values := 0
Check(trace, "array-delete|independent|array-field|", "independent user enumerator does not retain old source")
Check(iterator(&index, &value), 1, "independent enumerator remains usable")
Check(value, 7, "independent enumerator value")
iterator := 0
value := 0
index := 0
trace := ""
mapping := OwnedMap("x", OwnedValue("removed-map"))
mapping.Clear()
Check(trace, "removed-map|", "Map subclass Clear releases entries before instance")
mapping := 0
Check(trace, "removed-map|map-delete|map-field|", "Map subclass Clear leaves fields owned")
trace := ""
values := OwnedArray(OwnedValue("removed-array"))
values.Length := 0
Check(trace, "removed-array|", "Array subclass truncation releases elements before instance")
values := 0
Check(trace, "removed-array|array-delete|array-field|", "Array subclass truncation leaves fields owned")
FileAppend("pass`n", "*", "UTF-8-RAW")
ExitApp()
