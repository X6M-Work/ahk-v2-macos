#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; ObjHasOwnProp, ObjOwnPropCount, ObjOwnProps, ObjGetCapacity, ObjSetCapacity
o := { alpha: 10, beta: 20 }
lines.Push("own=" ObjHasOwnProp(o, "alpha") "|" ObjHasOwnProp(o, "missing") "|" ObjOwnPropCount(o))
cap := ObjSetCapacity(o, 16)
lines.Push("cap=" (cap >= 16 ? 1 : 0) "|" (ObjGetCapacity(o) >= 16 ? 1 : 0))
capNegErr := ""
try ObjSetCapacity(o, -1)
catch Any as e
	capNegErr := Type(e)
capHugeErr := ""
try ObjSetCapacity(o, 0x7FFFFFFF0)
catch Any as e
	capHugeErr := Type(e)
lines.Push("cap_err=" capNegErr "|" capHugeErr)

sum := 0
for k, v in ObjOwnProps(o)
	sum += v
lines.Push("sum=" sum)

; ObjGetBase / ObjSetBase / HasBase
proto := { kind: "custom", Double: (this) => this.alpha * 2 }
ObjSetBase(o, proto)
lines.Push("base=" (ObjGetBase(o) == proto ? 1 : 0) "|" HasBase(o, proto) "|" o.kind "|" o.Double())

; Clone preserves own props and base
c := o.Clone()
c.alpha := 99
lines.Push("clone=" o.alpha "|" c.alpha "|" c.kind "|" c.Double())

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
