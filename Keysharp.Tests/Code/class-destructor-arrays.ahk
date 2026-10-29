#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#Warn LocalSameAsGlobal, Off
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))
Check(actual, expected, tag) {
    if actual != expected {
        FileAppend("FAIL:" tag ":" actual ":" expected "`n", "*", "UTF-8-RAW")
        ExitApp(1)
    }
}
trace := ""
class ArrayValue {
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
values := [ArrayValue("A"), ArrayValue("B")]
Check(trace, "", "literal keeps elements")
copy := values
values := 0
Check(trace, "", "alias keeps array")
copy := 0
Check(trace, "A|B|", "last array alias releases elements in index order")
trace := ""
values := Array(ArrayValue("C"), ArrayValue("D"))
values.Length := 0
Check(trace, "C|D|", "constructor and length truncation own elements")
trace := ""
values := [ArrayValue("E"), ArrayValue("F")]
values[1] := ArrayValue("G"), Mark("after-set")
Check(trace, "E|after-set|", "fast replacement releases old value before next expression")
trace := ""
values["1"] := ArrayValue("H")
Check(trace, "G|", "slow replacement uses same ownership")
trace := ""
removed := values.Delete(1)
Check(trace, "", "Delete transfers value into result")
removed := 0
Check(trace, "H|", "Delete result owns value")
trace := ""
values.Pop(), Mark("after-pop")
Check(trace, "after-pop|F|", "discarded Pop result lives through comma expression")
trace := ""
values.Length := 0
values.Push(ArrayValue("I"), ArrayValue("J"))
values.InsertAt(2, ArrayValue("K"))
Check(trace, "", "Push and InsertAt retain values")
values.RemoveAt(1, 2), Mark("after-range")
Check(trace, "I|K|after-range|", "RemoveAt range releases values before return")
trace := ""
values := 0
Check(trace, "J|", "remaining element released with array")
trace := ""
values := [ArrayValue("L")]
cloned := values.Clone()
values := 0
Check(trace, "", "clone independently retains elements")
cloned := 0
Check(trace, "L|", "last clone releases element once")
MakeArray() => [ArrayValue("M")]
trace := ""
values := MakeArray()
Check(trace, "", "returned array survives callee scope")
values := 0
Check(trace, "M|", "returned array owns its element")
Variadic(args*) {
    global trace
    trace .= "V" args[1].Label "|"
}
trace := ""
Variadic(ArrayValue("N"))
Check(trace, "VN|N|", "variadic argument released at statement boundary")
Boom(args*) {
    throw Error("boom")
}
trace := ""
try Boom(ArrayValue("O"))
catch {
    Check(trace, "O|", "variadic argument released before catch")
}
ReturnArgs(args*) => args
trace := ""
values := ReturnArgs(ArrayValue("P"))
Check(trace, "", "returned variadic array remains owned")
values := 0
Check(trace, "P|", "returned variadic array releases element")
trace := ""
element := 0
for element in [ArrayValue("Q")] {
    Check(trace, "", "for retains temporary array")
    Check(element.Label, "Q", "for element remains usable")
}
Check(trace, "Q|", "for releases source after restoring variable")
trace := ""
for element in [ArrayValue("R"), ArrayValue("S")] {
    break
}
Check(trace, "S|R|", "source disposed before final loop variable restored")
trace := ""
try {
    for element in [ArrayValue("T")] {
        throw Error("loop")
    }
} catch {
    Check(trace, "T|", "exception disposes for source")
}
trace := ""
sharedReference := &element
%sharedReference% := ArrayValue("reference")
%sharedReference% := 0
Check(trace, "reference|", "global reference writes retain and release values")
trace := ""
values := [ArrayValue("enumerator")]
iterator := values.__Enum(1)
values := 0
Check(trace, "", "explicit enumerator retains source")
Check(iterator(&element), true, "explicit enumerator remains callable")
Check(element.Label, "enumerator", "explicit enumerator yields live value")
element := 0
Check(trace, "", "enumerator still retains yielded value")
iterator := 0
Check(trace, "enumerator|", "last enumerator alias releases source")
trace := ""
values := [[ArrayValue("nested1")], [ArrayValue("nested2")]]
values := 0
Check(trace, "nested1|nested2|", "nested arrays release recursively in index order")
class ReinsertingValue {
    __Delete() {
        global values, trace
        trace .= "old|"
        values.Push(ArrayValue("new"))
    }
}
trace := ""
values := [ReinsertingValue(), ArrayValue("tail")]
values.Length := 0
Check(trace, "old|tail|", "clear publishes removal before destructor callbacks")
Check(values.Length, 1, "reentrant Push preserves inserted item")
values := 0
Check(trace, "old|tail|new|", "reentrantly inserted item remains owned")
calls := 0
savedValues := []
class ArrayResurrection {
    __Delete() {
        global calls, savedValues
        calls++
        if calls = 1
            savedValues.Push(this)
    }
}
owned := ArrayResurrection()
owned := 0
Check(calls, 1, "first destruction resurrects into array")
Check(savedValues.Length, 1, "array retained resurrected value")
savedValues.Length := 0
Check(calls, 2, "array removal destroys resurrected value again")
EscapeSink(value) {
    global keptEscape
    keptEscape := {Value: value}
}
trace := ""
values := [ArrayValue("U")]
EscapeSink(values)
values := 0
Check(trace, "", "unconverted property protects array and its elements")
Check(keptEscape.Value[1].Label, "U", "escaped nested element remains usable")
FileAppend("pass`n", "*", "UTF-8-RAW")
