#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Backreference, non-capturing group, and match metadata
pos := RegExMatch("foo bar bar baz", "(?:foo\s+)(?<word>\w+)\s+\1", &m)
lines.Push("bref=" pos "|" m[1] "|" m.Name[1] "|" m.Pos[1] "|" m.Len[1])

; RegExReplace case conversion escapes $U, $L, $T (numbered, named, and escaped $$)
lines.Push("rcase=" RegExReplace("hello WORLD", "(?<w1>\w+)\s+(?<w2>\w+)", "$U1 $L2|$T{w1}|$$U1"))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
