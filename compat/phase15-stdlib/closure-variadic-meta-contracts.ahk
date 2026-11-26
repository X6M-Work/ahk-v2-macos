#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Variadic closure factory + BuiltIn Func metadata
MakeJoiner(sep) {
	return (parts*) => JoinLoop(parts, sep)
}
JoinLoop(arr, sep) {
	s := ""
	for idx, v in arr
		s .= (idx > 1 ? sep : "") v
	return s
}

j := MakeJoiner("::")
lines.Push("vclos=" j("a", "b", "c") "|" (j is Closure) "|" (j is Func))
lines.Push("bi_meta=" StrLen.IsBuiltIn "|" StrLen.MinParams "|" StrLen.MaxParams "|" JoinLoop.IsBuiltIn)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
