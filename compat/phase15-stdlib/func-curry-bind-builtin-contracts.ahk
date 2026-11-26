#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; 3-level curried fat-arrow closures
Curry3 := (a) => (b) => (c) => a * 100 + b * 10 + c
lines.Push("curry=" Curry3(1)(2)(3))

; Func.Bind on built-in functions with omitted leading argument
repAtoB := StrReplace.Bind(, "a", "b")
wrapBrk := Format.Bind("[{}]")
lines.Push("bind_bi=" repAtoB("banana") "|" wrapBrk("ok"))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
