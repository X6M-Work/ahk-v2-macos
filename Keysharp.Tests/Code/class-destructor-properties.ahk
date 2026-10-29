#Requires AutoHotkey v2.0
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
class PropertyValue {
    __New(label) {
        this.Label := label
    }
    __Delete() {
        global trace
        trace .= this.Label "|"
    }
}
class PropertyOwner {
    Child := PropertyValue("field")
}
mapping := Map("b", PropertyValue("entry-b"), "a", PropertyValue("entry-a"))
mapping.Default := PropertyValue("default")
mapping.Z := PropertyValue("z")
mapping.A := PropertyValue("a")
mapping := 0
Check(trace, "entry-b|entry-a|a|default|z|", "entries then own properties")
trace := ""
holder := {Child: PropertyValue("literal")}
holder := 0
Check(trace, "literal|", "literal owns child")
trace := ""
holder := Object()
holder.Child := PropertyValue("object")
alias := holder
holder := 0
Check(trace, "", "alias owns properties")
alias := 0
Check(trace, "object|", "Object constructor owns properties")
trace := ""
holder := PropertyOwner()
holder := 0
Check(trace, "field|", "class initializer owns child")
trace := ""
class FailedPropertyOwner {
    __New() {
        this.Child := PropertyValue("failed-child")
        throw Error("expected")
    }
    __Delete() {
        global trace
        trace .= "failed-parent:" this.Child.Label "|"
    }
}
try FailedPropertyOwner()
catch {
}
Check(trace, "failed-parent:failed-child|failed-child|", "failed construction keeps fields until destructor returns")
trace := ""
class ConstructedSelfRead {
    __New() {
        this.Self := this
        other := this.Self
        this.DeleteProp("Self")
        other := 0
    }
    __Delete() {
        global trace
        trace .= "constructed|"
    }
}
value := ConstructedSelfRead()
value := 0
Check(trace, "constructed|", "property reads preserve constructing lifetime")
trace := ""
holder := {Child: PropertyValue("old")}
holder.Child := holder.Child
Check(trace, "", "property self assignment")
holder.Child := PropertyValue("new")
Check(trace, "old|", "replacement releases previous property")
removed := holder.DeleteProp("Child")
Check(trace, "old|", "DeleteProp transfers value")
removed := 0
Check(trace, "old|new|", "DeleteProp result releases")
trace := ""
holder.DefineProp("Child", {Value: PropertyValue("defined")})
holder := 0
Check(trace, "defined|", "DefineProp descriptor transfers value")
trace := ""
holder := {Child: PropertyValue("cloned")}
cloned := holder.Clone()
holder := 0
Check(trace, "", "clone owns independent property references")
cloned := 0
Check(trace, "cloned|", "clone releases child")
trace := ""
mapping := Map()
mapping.Default := PropertyValue("map-clone")
cloned := mapping.Clone()
mapping := 0
Check(trace, "", "Map clone owns Default")
cloned := 0
Check(trace, "map-clone|", "Map clone releases Default")
trace := ""
values := []
values.Child := PropertyValue("array-clone")
cloned := values.Clone()
values := 0
cloned := 0
Check(trace, "array-clone|", "Array clone owns custom property")
trace := ""
holder := {Child: PropertyValue("descriptor")}
descriptor := holder.GetOwnPropDesc("Child")
holder := 0
Check(trace, "", "exported descriptor owns value")
Check(descriptor.Value.Label, "descriptor", "descriptor value remains usable")
descriptor := 0
Check(trace, "descriptor|", "descriptor releases value")
trace := ""
MakeHolder() => {Child: PropertyValue("temporary")}
Consume(value) {
    Check(value.Label, "temporary", "child read from temporary parent")
}
Consume(MakeHolder().Child)
Check(trace, "temporary|", "temporary parent and child expire together")
trace := ""
mapping := Map()
mapping.Default := PropertyValue("fallback")
value := mapping.Get("absent")
mapping := 0
Check(trace, "", "fallback result survives Map")
value := 0
Check(trace, "fallback|", "fallback result releases")
trace := ""
holder := {Child: PropertyValue("enumerated")}
iterator := holder.OwnProps()
holder := 0
Check(trace, "", "OwnProps enumerator keeps receiver")
iterator(&key, &value)
Check(value.Label, "enumerated", "OwnProps result remains usable")
value := 0
iterator := 0
Check(trace, "enumerated|", "OwnProps releases source")
trace := ""
holder := {A: PropertyValue("A"), B: PropertyValue("B")}
iterator := holder.OwnProps()
holder.DeleteProp("B")
Check(trace, "B|", "OwnProps does not retain removed properties")
holder.A := PropertyValue("updated")
Check(trace, "B|A|", "OwnProps sees property replacement")
iterator(&key, &value)
Check(value.Label, "updated", "OwnProps reads current property")
value := 0
iterator := 0
holder := 0
Check(trace, "B|A|updated|", "enumerated properties release once")
trace := ""
saved := {}
deletes := 0
class ResurrectIntoProperty {
    __Delete() {
        global saved, deletes, trace
        deletes += 1
        trace .= deletes "|"
        if deletes = 1
            saved.Child := this, Check(IsObject(saved.Child), 1, "property read preserves deleting lifetime")
    }
}
value := ResurrectIntoProperty()
value := 0
Check(trace, "1|", "own property retains during destructor")
saved.DeleteProp("Child")
Check(trace, "1|2|", "own property releases resurrected value")
saved := 0
trace := ""
class PropertyAccessor {
    __New(label) {
        this.Label := label
    }
    Call(*) {
        return 42
    }
    __Delete() {
        global trace
        trace .= this.Label "|"
    }
}
holder := {}
holder.DefineProp("P", {Get: PropertyAccessor("get"), Set: PropertyAccessor("set")})
Check(holder.P, 42, "callable getter remains usable")
holder.DefineProp("P", {Value: PropertyValue("data")})
Check(trace, "get|set|", "descriptor replacement releases accessor slots")
holder.DefineProp("P", {Get: PropertyAccessor("next-get")})
Check(trace, "get|set|data|", "descriptor replacement releases data slot")
holder.DeleteProp("P")
Check(trace, "get|set|data|next-get|", "DeleteProp releases getter")
trace := ""
class MetadataAccessor {
    MinParams => 1
    MaxParams {
        get {
            global holder, trace
            Check(holder.GetOwnPropDesc("P").HasOwnProp("Get"), 1, "getter descriptor published before metadata")
            trace .= "metadata|"
            return 1
        }
    }
    IsVariadic => false
    Call(*) => 42
    __Delete() {
        global trace
        trace .= "metadata-get|"
    }
}
holder := {P: PropertyValue("old-data")}
holder.DefineProp("P", {Get: MetadataAccessor()})
Check(trace, "old-data|metadata|", "old slot released before metadata callback")
holder := 0
Check(trace, "old-data|metadata|metadata-get|", "metadata getter released once")
trace := ""
class DropPropertyOwner {
    __Delete() {
        global holder, trace
        trace .= "drop|"
        holder := 0
    }
}
holder := {Child: DropPropertyOwner()}
holder.Child := PropertyValue("incoming")
Check(trace, "drop|incoming|", "replacement protects receiver through reentrant release")
mapping := Map("x", 1)
rejected := false
try Object.Prototype.Clone.Call(mapping)
catch TypeError {
    rejected := true
}
Check(rejected, 1, "base Object Clone rejects Map native data")
mapping := 0
values := [1, 2]
rejected := false
try Object.Prototype.Clone.Call(values)
catch TypeError {
    rejected := true
}
Check(rejected, 1, "base Object Clone rejects Array native data")
values := 0
FileAppend("pass`n", "*", "UTF-8-RAW")
ExitApp()
