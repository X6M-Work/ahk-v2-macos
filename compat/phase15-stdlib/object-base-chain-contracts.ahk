#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; 4-level prototype chain + ObjSetBase switching + TypeError on non-object base
p1 := { a: 1, b: 1, c: 1 }
p2 := { base: p1, b: 2 }
p3 := { base: p2, c: 3 }
o := { base: p3 }
lines.Push("chain=" o.a "|" o.b "|" o.c "|" HasBase(o, p1))

badBase := ""
try ObjSetBase(o, "")
catch TypeError
	badBase := "TypeError"
lines.Push("badbase=" badBase)

ObjSetBase(o, p1)
lines.Push("rebased=" o.a "|" o.b "|" o.c "|" HasBase(o, p2) "|" HasBase(o, p1))

ObjSetBase(o, Object.Prototype)
lines.Push("restored=" HasBase(o, Object.Prototype) "|" HasBase(o, p1))

valErrs := ""
try ObjSetBase({}, [])
catch ValueError
	valErrs .= "D|"
try ObjSetBase(p1, p3)
catch ValueError
	valErrs .= "C|"
lines.Push("verr=" valErrs)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
