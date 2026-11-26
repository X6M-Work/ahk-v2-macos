#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Dynamic function call & dynamic property access & chained ??
DoubleIt(n) => n * 2
fnName := "DoubleIt"
lines.Push("dyn_fn=" %fnName%(21))

o := { alpha: 10, beta: 20 }
k := "beta"
lines.Push("dyn_prop=" o.%k%)

CheckCoalesce(a?, b?, c := 99) => (a ?? b ?? c)
lines.Push("coal=" CheckCoalesce() "|" CheckCoalesce(, 55) "|" CheckCoalesce(11, 55))

; IsSet on local variables before and after assignment
CheckSet() {
	b0 := IsSet(v)
	v := "ok"
	b1 := IsSet(v)
	return b0 "|" b1 "|" v
}
lines.Push("isset=" CheckSet())

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
