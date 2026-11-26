#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; InStr case sensitivity, occurrence, negative starting pos
lines.Push("instr_cs=" InStr("AaAa", "A", "On", 1, 1) "|" InStr("AaAa", "A", "On", 1, 2) "|" InStr("AaAa", "A", "On", 1, 3) "|" InStr("AaAa", "a", "On", -1))

; StrReplace case sensitivity, count, limit
c1 := 0, c2 := 0
r1 := StrReplace("AaAa", "a", "X", "On", &c1)
r2 := StrReplace("AaAa", "a", "X", "Off", &c2, 2)
lines.Push("rep_cs=" r1 ":" c1 "|" r2 ":" c2)

; StrSplit with array of delimiters + omit chars + max parts
p := StrSplit(" one - two _ three - four ", ["-", "_"], " ", 3)
lines.Push("split_arr=" p.Length "|" p[1] "|" p[2] "|" p[3])

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
