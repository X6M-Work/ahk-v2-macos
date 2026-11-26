#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Shallow Clone shares nested references while copying top-level fields
inner := { v: 1 }
outer := { a: 10, ref: inner }
cl := outer.Clone()
cl.a := 20
cl.ref.v := 99
lines.Push("shallow=" outer.a "|" cl.a "|" outer.ref.v "|" cl.ref.v)

; ObjOwnPropCount transitions: empty -> populated -> post-DeleteProp
e := {}
c0 := ObjOwnPropCount(e)
e.x := 1, e.y := 2
c1 := ObjOwnPropCount(e)
e.DeleteProp("x")
c2 := ObjOwnPropCount(e)
lines.Push("owncnt=" c0 "|" c1 "|" c2)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
