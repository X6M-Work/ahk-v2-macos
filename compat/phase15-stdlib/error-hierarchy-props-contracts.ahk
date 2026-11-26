#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

e1 := ValueError("bad val", -1, "x")
e2 := TypeError("bad type", -1, "y")
e3 := IndexError("bad idx")
e4 := PropertyError("no prop")
e5 := MethodError("no meth")
e6 := UnsetItemError("no item")
e7 := TargetError("no target")
e8 := ZeroDivisionError("div0")
e9 := OSError(0)

lines.Push("base=" (e1 is Error) "|" (e2 is Error) "|" (e3 is Error) "|" (e7 is Error) "|" (e8 is Error) "|" (e9 is Error))
lines.Push("sub=" (e4 is MemberError) "|" (e5 is MemberError) "|" (e6 is UnsetError) "|" (e4 is PropertyError) "|" (e5 is MethodError))
lines.Push("props=" e1.Message "|" e1.Extra "|" e2.Message "|" e2.Extra)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
