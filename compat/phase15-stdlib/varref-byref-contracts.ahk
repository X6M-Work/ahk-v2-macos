#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; VarRef stored in container, dereferenced via %ref%, passed to ByRef
MakeRef(init) {
	v := init
	return &v
}

r := MakeRef(10)
box := [r]
lines.Push("vref_type=" (r is VarRef) "|" Type(r) "|" IsSetRef(r) "|" %box[1]%)

%r% := 25
lines.Push("vref_mut=" %r% "|" %box[1]%)

AddTo(&target, delta) {
	target += delta
}
AddTo(r, 17)
lines.Push("vref_byref=" %r%)

; Unset VarRef -> set through ByRef
InitRef(&slot) {
	before := IsSetRef(&slot)
	slot := "ready"
	return before "|" IsSetRef(&slot)
}
lines.Push("vref_init=" InitRef(&u) "|" u)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
