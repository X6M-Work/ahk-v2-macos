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
class TrackedScope {
    __New(label := "X") {
        this.Label := label
    }
    __Delete() {
        global trace
        trace .= (trace = "" ? "" : ",") this.Label
    }
}

MakeLocal() {
    local owned := TrackedScope("local")
    return Type(owned)
}
trace := ""
Check(MakeLocal(), "TrackedScope", "local return value")
Check(trace, "local", "local destroyed on return")

ImplicitReturn() {
    local owned := TrackedScope("implicit")
}
trace := ""
ImplicitReturn()
Check(trace, "implicit", "local destroyed on implicit return")

EarlyReturn(flag) {
    local first := TrackedScope("first")
    if flag {
        local second := TrackedScope("second")
        return Type(second)
    }
    return Type(first)
}
trace := ""
Check(EarlyReturn(true), "TrackedScope", "early return value")
Check(trace, "first,second", "early return destroys active locals in order")

ArrowLocal := () => (owned := TrackedScope("arrow"), Type(owned))
trace := ""
Check(ArrowLocal(), "TrackedScope", "arrow local return")
Check(trace, "arrow", "arrow local destroyed on return")

OrderScope(zParam := TrackedScope("z"), aParam := TrackedScope("a")) {
    local mLocal := TrackedScope("m")
    local BLocal := TrackedScope("B")
    return Type(aParam) ":" Type(BLocal) ":" Type(mLocal) ":" Type(zParam)
}
trace := ""
OrderScope()
Check(trace, "a,B,m,z", "scope exit releases parameters and locals in case-insensitive alphabetical order")

BorrowParam(value) => Type(value)
ReassignParam(value) {
    value := TrackedScope("reassigned")
    return Type(value)
}
trace := ""
outer := TrackedScope("outer")
Check(BorrowParam(outer), "TrackedScope", "borrowed parameter usable")
Check(trace, "", "borrowed parameter survives callee exit")
Check(ReassignParam(outer), "TrackedScope", "reassigned parameter usable")
Check(trace, "reassigned", "reassigned parameter destroyed on callee exit")
outer := 0
Check(trace, "reassigned,outer", "caller variable destroyed when cleared")

DefaultParam(value := TrackedScope("default")) => Type(value)
trace := ""
Check(DefaultParam(), "TrackedScope", "default parameter usable")
Check(trace, "default", "default parameter destroyed on callee exit")
trace := ""
outer := TrackedScope("supplied")
Check(DefaultParam(outer), "TrackedScope", "supplied parameter overrides default")
Check(trace, "", "supplied parameter survives callee exit")
outer := 0
Check(trace, "supplied", "supplied parameter destroyed when cleared")

DefaultByRef(&slot := TrackedScope("byrefDefault")) => Type(slot)
TouchByRef(&slot) => Type(slot)
trace := ""
Check(DefaultByRef(), "TrackedScope", "omitted byref default usable")
Check(trace, "byrefDefault", "omitted byref default destroyed on callee exit")
UseLocalByRef() {
    local boxed := TrackedScope("boxedLocal")
    Check(TouchByRef(&boxed), "TrackedScope", "local byref argument usable")
    Check(trace, "", "local byref survives callee")
}
trace := ""
UseLocalByRef()
Check(trace, "boxedLocal", "boxed local destroyed when declaring scope exits")

LocalVarRefAlias() {
    local target := TrackedScope("cell")
    local refAlias := &target
    return Type(%refAlias%)
}
trace := ""
Check(LocalVarRefAlias(), "TrackedScope", "local VarRef dereference")
Check(trace, "cell", "local VarRef and boxed local destroyed at scope exit")

exportedRef := 0
ExportLocalRef() {
    global exportedRef
    local kept := TrackedScope("exportedCell")
    exportedRef := &kept
}
trace := ""
ExportLocalRef()
Check(trace, "", "exported VarRef keeps boxed local alive")
Check(Type(%exportedRef%), "TrackedScope", "exported VarRef remains readable")
exportedRef := 0
Check(trace, "exportedCell", "releasing last VarRef destroys boxed local")

UnwindWithFinally() {
    global trace
    try {
        local guarded := TrackedScope("guarded")
        throw Error("boom")
    } finally {
        trace .= (trace = "" ? "" : ",") "finally"
    }
}
trace := ""
try UnwindWithFinally()
catch Error {
}
Check(trace, "finally,guarded", "user finally runs before scope destruction on unwind")

class ThrownScope {
    __New(label) {
        this.Message := label
    }
    __Delete() {
        global trace
        trace .= (trace = "" ? "" : ",") this.Message
    }
}
ThrowTracked() {
    local err := ThrownScope("thrown")
    throw err
}
CatchTracked() {
    global trace
    try {
        ThrowTracked()
    } catch ThrownScope as caught {
        Check(trace, "", "thrown object survives unwinding into catch")
        Check(caught.Message, "thrown", "caught payload intact")
    }
    Check(trace, "", "catch variable lives until enclosing function exits")
}
trace := ""
CatchTracked()
Check(trace, "thrown", "caught object destroyed at catching function exit")

ForLoopPreservesPreLoopValue() {
    local item := TrackedScope("beforeLoop")
    for item in [1, 2] {
    }
    Check(trace, "", "for-loop backup preserves pre-loop tracked value")
    Check(Type(item), "TrackedScope", "for-loop restores pre-loop tracked value")
}
trace := ""
ForLoopPreservesPreLoopValue()
Check(trace, "beforeLoop", "restored for-loop variable destroyed at scope exit")

DynamicLocalScope() {
    local target := 0
    name := "target"
    %name% := TrackedScope("dynamic")
    return Type(target)
}
trace := ""
Check(DynamicLocalScope(), "TrackedScope", "dynamic local write")
Check(trace, "dynamic", "dynamic local destroyed at scope exit")

class HostScope {
    Method() {
        local temp := TrackedScope("methodLocal")
        return Type(temp)
    }
    Prop {
        get {
            local temp := TrackedScope("getterLocal")
            return Type(temp)
        }
        set {
            local temp := TrackedScope("setterLocal")
        }
    }
    __Delete() {
        global trace
        trace .= (trace = "" ? "" : ",") "host"
    }
}
UseHost() {
    local host := HostScope()
    Check(host.Method(), "TrackedScope", "method local return")
    Check(trace, "methodLocal", "method local destroyed on method exit")
    Check(host.Prop, "TrackedScope", "getter local return")
    Check(trace, "methodLocal,getterLocal", "getter local destroyed on getter exit")
    host.Prop := 1
    Check(trace, "methodLocal,getterLocal,setterLocal", "setter local destroyed on setter exit")
}
trace := ""
UseHost()
Check(trace, "methodLocal,getterLocal,setterLocal,host", "receiver destroyed when caller scope exits")

ReturnOwned() {
    local owned := TrackedScope("returned")
    return owned
}
ReturnOwnedArrow := () => (owned := TrackedScope("returnedArrow"), owned)
MakeCapturingArrow() {
    local owned := TrackedScope("capturedArrow")
    return () => Type(owned)
}
MakeCapturingNested() {
    local owned := TrackedScope("capturedNested")
    Inner() => Type(owned)
    return Inner
}
trace := ""
keptReturn := ReturnOwned()
keptArrow := ReturnOwnedArrow()
keptClosure := MakeCapturingArrow()
keptNested := MakeCapturingNested()
Check(trace, "", "returned and closure-captured locals survive scope exit")
Check(Type(keptReturn), "TrackedScope", "returned local usable")
Check(Type(keptArrow), "TrackedScope", "arrow-returned local usable")
Check(keptClosure(), "TrackedScope", "arrow-captured local usable")
Check(keptNested(), "TrackedScope", "nested-captured local usable")

FileAppend("pass`n", "*", "UTF-8-RAW")
