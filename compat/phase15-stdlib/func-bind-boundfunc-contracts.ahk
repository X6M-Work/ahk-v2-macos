#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

Combine(a, b, c := 30, rest*) {
	s := a ":" b ":" c
	for idx, v in rest
		s .= ":" v
	return s
}

b1 := Combine.Bind(, 20)
b2 := b1.Bind(10)
lines.Push("b1=" b1(1) "|" b1(1, 99, 100))
lines.Push("b2=" b2() "|" b2(40, 50))
lines.Push("meta=" (b1 is BoundFunc) "|" (b1 is Func) "|" b1.IsVariadic)

extra := [7, 8]
lines.Push("var=" b2(6, extra*))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
