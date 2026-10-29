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
class Temporary {
    __New(label) {
        this.Label := label
    }
    __Delete() {
        global trace
        trace .= "D" this.Label "|"
    }
    Touch() {
        global trace
        trace .= "M" this.Label "|"
    }
}
Consume(value, other := 0) {
    global trace
    trace .= "C" value.Label "|"
    return 1
}
Mark(label) {
    global trace
    trace .= label "|"
    return 1
}
Identity(value) => value
Factory() {
    local value := Temporary("F")
    return value
}
Make() => Temporary("arrow")
Boom(value := 0) {
    throw Error("boom")
}
Consume(Temporary("A")), Mark("comma")
Check(trace, "CA|comma|DA|", "comma is one expression")
trace := ""
Consume(Temporary("B"), Temporary("C"))
Check(trace, "CB|DC|DB|", "arguments survive call then release in reverse order")
trace := ""
Consume(Identity(Temporary("I")))
Check(trace, "CI|DI|", "identity returns argument without duplicate destruction")
trace := ""
Consume.Call(Temporary("call"))
Check(trace, "Ccall|Dcall|", "explicit Call forwards temporary ownership")
trace := ""
held := Factory()
Check(trace, "", "factory return retained by destination")
held := 0
Check(trace, "DF|", "returned local released with destination")
trace := ""
Factory()
Check(trace, "DF|", "discarded returned local")
trace := ""
Make()
Check(trace, "Darrow|", "discarded arrow return")
trace := ""
Consume(Make())
Check(trace, "Carrow|Darrow|", "arrow return used as argument")
trace := ""
try Boom(Temporary("E"))
catch {
    Check(trace, "DE|", "exception releases before handler")
}
trace := ""
try Consume(Temporary("first"), Boom())
catch {
    Check(trace, "Dfirst|", "later argument failure releases earlier temporary")
}
trace := ""
if Temporary("condition") {
    Check(trace, "Dcondition|", "condition released before branch")
}
trace := ""
if false && Temporary("skipped") {
    Check(1, 0, "short circuit branch")
}
Check(trace, "", "unselected short circuit not evaluated")
trace := ""
Consume(true ? Temporary("chosen") : Temporary("wrong"))
Check(trace, "Cchosen|Dchosen|", "ternary tracks selected branch")
trace := ""
Temporary("receiver").Touch()
Check(trace, "Mreceiver|Dreceiver|", "temporary receiver survives method")
trace := ""
while Temporary("while") {
    Check(trace, "Dwhile|", "while condition released before body")
    break
}
trace := ""
loop {
    Mark("body")
} until Temporary("until")
Check(trace, "body|Duntil|", "until condition released")
trace := ""
switch {
    case Temporary("case"):
        Check(trace, "Dcase|", "switch condition released before body")
}
trace := ""
held := Temporary("owned")
Consume(held)
Check(trace, "Cowned|", "borrowed argument remains owned")
held := held
Check(trace, "Cowned|", "self assignment preserves owner")
held := 0
Check(trace, "Cowned|Downed|", "owner released once")
trace := ""
exportedArray := [Temporary("export")]
Check(trace, "", "unconverted container keeps temporary alive")
Check(exportedArray[1].Label, "export", "export remains usable")
Default(value := Temporary("default")) => Type(value)
trace := ""
Default()
Check(trace, "Ddefault|", "default expression transfers into parameter")
FinallyReturn() {
    try return Temporary("finally")
    finally Mark("finally")
}
trace := ""
FinallyReturn()
Check(trace, "finally|Dfinally|", "return survives user finally")
class ReentrantTemporary {
    __Delete() {
        global trace
        trace .= "R<|"
        Consume(Temporary("nested"))
        trace .= "R>|"
    }
}
trace := ""
ReentrantTemporary()
Check(trace, "R<|Cnested|Dnested|R>|", "destructor creates an independent expression")
Count(value) => 1
Values(value) => [1]
trace := ""
loop Count(Temporary("count")) {
    Check(trace, "Dcount|", "count header releases before body")
}
trace := ""
for item in Values(Temporary("values")) {
    Check(trace, "Dvalues|", "for header releases argument before body")
}
class TemporaryEnumerable extends Temporary {
    __Enum(n) => [1].__Enum(n)
}
trace := ""
for item in TemporaryEnumerable("enumerable") {
    Check(trace, "Denumerable|", "source released after independent enumerator created")
}
RefFactory() {
    local item := Temporary("ref")
    return &item
}
trace := ""
heldRef := RefFactory()
Check(trace, "", "returned variable reference keeps cell alive")
Check(%heldRef%.Label, "ref", "returned variable reference remains readable")
heldRef := 0
Check(trace, "Dref|", "returned variable reference released with destination")
FileAppend("pass`n", "*", "UTF-8-RAW")
