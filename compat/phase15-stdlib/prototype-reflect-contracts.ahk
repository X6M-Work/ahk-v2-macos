#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; DefineProp (Value, Get/Set, Call) and GetOwnPropDesc
o := {}
o.DefineProp("x", { Value: 42 })
o.DefineProp("doubled", { Get: (this) => this.x * 2 })
o.DefineProp("add", { Call: (this, n) => this.x + n })
dVal := o.GetOwnPropDesc("x")
dGet := o.GetOwnPropDesc("doubled")
dCall := o.GetOwnPropDesc("add")
lines.Push("defprop=" o.x "|" o.doubled "|" o.add(8) "|" dVal.Value "|" (dGet.HasOwnProp("Get") ? 1 : 0) "|" (dCall.HasOwnProp("Call") ? 1 : 0))
lines.Push("owncnt=" ObjOwnPropCount(o))

; HasBase, GetMethod, Clone with DefineProp
class Parent {
	Greet(who) => "hi " who
}
class Child extends Parent {
}
ch := Child()
gm := ch.GetMethod("Greet")
lines.Push("reflect=" HasBase(ch, Parent.Prototype) "|" HasBase(Child, Parent) "|" gm(ch, "mac"))

; Conversions & type checks
lines.Push("conv=" Integer("0x1F") "|" Format("{:.2f}", Float("1.5e2")) "|" Type(Number("42")) "|" Type(Number("42.5")) "|" String(123))
lines.Push("is_t=" IsNumber("3.14") "|" IsInteger("42") "|" IsInteger("42.5") "|" IsFloat(42.5) "|" IsXDigit("deadBEEF") "|" IsSpace(" `t`r`n") "|" IsAlnum("abc123"))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
