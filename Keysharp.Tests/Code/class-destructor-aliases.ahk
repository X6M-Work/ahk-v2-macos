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
class TrackedAlias {
    __Delete() {
        global trace
        trace .= "X"
    }
}
a := TrackedAlias()
b := (a)
a := a
b := b
a := 0
Check(trace, "", "alias retained")
b := 0
Check(trace, "X", "last alias released")

trace := ""
a := b := TrackedAlias()
b := a
b := 0
Check(trace, "", "chain retained")
a := 0
Check(trace, "X", "chain released")

LocalAliases() {
    global trace
    local first := TrackedAlias()
    local second := first
    first := first
    first := 0
    Check(trace, "", "local retained")
    second := 0
    Check(trace, "X", "local released")
}
trace := ""
LocalAliases()

constructionAlias := 0
class ConstructingAlias {
    __New() {
        global constructionAlias
        constructionAlias := this
        constructionAlias := 0
    }
    __Delete() {
        global trace
        trace .= "C"
    }
}
trace := ""
a := ConstructingAlias()
Check(trace, "", "construction remains protected")
a := 0
Check(trace, "C", "constructed value released")

class ReadsOwnAlias {
    __New() => this.Label := "L"
    __Delete() {
        global trace
        trace .= this.Label
    }
}
trace := ""
a := ReadsOwnAlias()
a := 0
Check(trace, "L", "destructor can read its receiver")

class CaseFoldedAlias {
    __new() => this.Label := "L"
    __delete() {
        global trace
        trace .= this.Label
    }
}
trace := ""
a := CaseFoldedAlias()
a := a
a := 0
Check(trace, "L", "lifecycle names ignore ASCII case")

class ReplacementAlias {
    __Delete() {
        global trace
        trace .= "R"
    }
}
class ReentrantAlias {
    __Delete() {
        global a, trace
        trace .= "D"
        a := ReplacementAlias()
    }
}
trace := ""
a := ReentrantAlias()
result := (a := 0)
Check(trace, "D", "reentrant replacement retained")
a := 0
Check(trace, "D", "assignment result retains final slot")
result := 0
Check(trace, "DR", "reentrant replacement released")

cellReference := 0
class BoxReentryAlias {
    __Delete() {
        global cellReference, trace
        trace .= "B"
        PutBoxReplacement(cellReference)
    }
}
PutBoxReplacement(&slot) => slot := ReplacementAlias()
BoxedReentry() {
    global cellReference, keptBoxResult, trace
    local cell := BoxReentryAlias()
    cellReference := &cell
    local finalValue := (cell := 0)
    Check(Type(finalValue), "ReplacementAlias", "boxed assignment reads rewritten slot")
    Check(trace, "B", "boxed replacement retained")
    keptBoxResult := finalValue
    cellReference := 0
}
trace := ""
BoxedReentry()

class DeletingAlias {
    __Delete() {
        global trace
        trace .= "D"
        local temporary := this
        temporary := temporary
        temporary := 0
    }
}
trace := ""
a := DeletingAlias()
a := 0
Check(trace, "D", "no recursive delete")

savedAlias := 0
deletes := 0
class ResurrectedAlias {
    Read() => Type(this)
    __Delete() {
        global deletes, savedAlias
        deletes += 1
        if deletes < 3
            savedAlias := this
    }
}
a := ResurrectedAlias()
a := 0
Check(deletes, 1, "resurrected")
Check(IsObject(savedAlias), true, "resurrected object survives predicate")
Check(Type(savedAlias), "ResurrectedAlias", "resurrected object survives type lookup")
Check(savedAlias.Read(), "ResurrectedAlias", "resurrected receiver survives method")
savedAlias := savedAlias
savedAlias := 0
Check(deletes, 2, "released again")
ReturnResurrected(value) => value
secondAlias := ReturnResurrected(savedAlias)
savedAlias := 0
Check(deletes, 2, "returned resurrected alias retains ownership")
Check(IsObject(secondAlias), true, "returned resurrected object remains usable")
secondAlias := 0
Check(deletes, 3, "third destruction after returned alias released")

class OverwritesIncomingAlias {
    __Delete() {
        global a, trace
        trace .= "D"
        a := 0
    }
}
trace := ""
a := OverwritesIncomingAlias()
result := (a := ReplacementAlias())
Check(trace, "DR", "overwritten incoming value released")
Check(result, 0, "assignment reads rewritten slot")

trace := ""
a := TrackedAlias()
arrayContainer := [a]
a := 0
Check(trace, "", "array retains escaped value")
Check(Type(arrayContainer[1]), "TrackedAlias", "array value remains usable")

trace := ""
a := TrackedAlias()
propertyContainer := {Value: a}
a := 0
Check(trace, "", "property retains escaped value")
Check(Type(propertyContainer.Value), "TrackedAlias", "property remains usable")

BorrowedAlias(value) {
    global a, trace, keptBorrowed
    keptBorrowed := value
    a := 0
    Check(trace, "", "argument remains alive")
    Check(Type(value), "TrackedAlias", "argument remains usable")
}
trace := ""
a := TrackedAlias()
BorrowedAlias(a)

escapedConstruction := 0
class ArrayEscapingAlias {
    __New() {
        global escapedConstruction
        escapedConstruction := [this]
    }
    __Delete() {
        global trace
        trace .= "E"
    }
}
trace := ""
a := ArrayEscapingAlias()
a := 0
Check(trace, "", "constructor exports through array")
Check(Type(escapedConstruction[1]), "ArrayEscapingAlias", "constructed array value remains usable")

escapedClosure := 0
class ClosureEscapingAlias {
    __New() {
        global escapedClosure
        escapedClosure := () => this
    }
    __Delete() {
        global trace
        trace .= "E"
    }
}
trace := ""
a := ClosureEscapingAlias()
a := 0
Check(trace, "", "constructor exports through closure")
Check(Type(escapedClosure()), "ClosureEscapingAlias", "captured receiver remains usable")

trace := ""
a := TrackedAlias()
reference := &a
a := 0
Check(trace, "X", "reference is a cell")

FileAppend("pass`n", "*", "UTF-8-RAW")
