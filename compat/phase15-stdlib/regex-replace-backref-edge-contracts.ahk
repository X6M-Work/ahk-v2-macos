#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

c1 := 0
r1 := RegExReplace("foo bar baz", "\b(\w+)\b", "[$U0:$L1:$$]", &c1, 2)
c2 := 0
r2 := RegExReplace("hello WORLD test", "\b(\w+)\b", "$T1", &c2, -1, 7)
r3 := RegExReplace("1234567", "(?=(\d{3})+$)(?<!^)", ",")
lines.Push("r1=" r1 "|" c1)
lines.Push("r2=" r2 "|" c2)
lines.Push("r3=" r3)
lines.Push("sp0=" RegExMatch("abc", "a", , 0) "|" RegExMatch("abc", "$", , 0) "|" RegExReplace("abc", ".", "X", , -1, 0) "|" RegExReplace("abc", "$", "!", , -1, 0))
lines.Push("bref=" RegExReplace("abc", "(b)", "[$0|${0}|$1|${1}|$9|$10|$$|$]"))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
