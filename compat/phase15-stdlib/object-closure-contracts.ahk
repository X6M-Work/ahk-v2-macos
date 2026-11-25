#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

Emit(line) => FileAppend(line "`n", "*", "UTF-8-RAW")

class Animal {
    static Kind := "Creature"
    __New(name) {
        this.Name := name
    }
    Speak() => this.Name ":..."
}

class Dog extends Animal {
    __New(name, bark) {
        super.__New(name)
        this.Bark := bark
    }
    Speak() => super.Speak() "/" this.Bark
    Sum(a, b, c := 10) => a + b + c
}

d := Dog("Rex", "Woof")
Emit("class_speak|" d.Speak())
Emit("class_is|" (d is Dog) "|" (d is Animal) "|" (d is Object) "|" Animal.Kind)
Emit("class_has|" d.HasOwnProp("Name") "|" d.HasOwnProp("Speak") "|" d.HasProp("Speak") "|" d.HasMethod("Speak") "|" ObjOwnPropCount(d))

; BoundFunc and ObjBindMethod
boundMethod := ObjBindMethod(d, "Sum", 1)
Emit("bind_method|" boundMethod(2, 3) "|" boundMethod(2))

MakeAdder(base) {
    acc := base
    Add(delta) {
        acc += delta
        return acc
    }
    return Add
}
adder := MakeAdder(10)
Emit("closure|" adder(5) "|" adder(7))

; Variadic forwarding and Func.Bind
JoinAll(sep, items*) {
    out := ""
    for i, v in items
        out .= (i > 1 ? sep : "") v
    return out
}
joinDash := JoinAll.Bind("-")
arr := ["x", "y", "z"]
Emit("variadic|" joinDash(arr*) "|" joinDash("a", "b"))

; Prototype / Base manipulation
baseObj := { tag: "B", Calc: (this, n) => n * 2 }
childObj := {}
ObjSetBase(childObj, baseObj)
Emit("base_proto|" (ObjGetBase(childObj) == baseObj ? 1 : 0) "|" childObj.tag "|" childObj.Calc(6) "|" childObj.HasOwnProp("tag") "|" childObj.HasProp("tag"))
