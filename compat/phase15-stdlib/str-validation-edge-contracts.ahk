#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; SubStr StartingPos=0 or Length=0 returns ""
lines.Push("sub_edge=" StrLen(SubStr("abc", 0)) "|" StrLen(SubStr("abc", 2, 0)))

; InStr StartingPos=0 or Occurrence=0 throws ValueError
in0Err := 0, occ0Err := 0
try {
	InStr("abc", "a", , 0)
} catch ValueError {
	in0Err := 1
}
try {
	InStr("abc", "a", , 1, 0)
} catch ValueError {
	occ0Err := 1
}
lines.Push("instr_edge=" in0Err "|" occ0Err)

; StrCompare empty vs non-empty and numeric CaseSense 1/0
lines.Push("cmp=" StrCompare("", "") "|" (StrCompare("", "a") < 0 ? 1 : 0) "|" (StrCompare("a", "A", 1) != 0 ? 1 : 0) "|" (StrCompare("a", "A", 0) == 0 ? 1 : 0))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
