#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; StrReplace limit=0, numeric CaseSense 1/0, empty needle throws ValueError
c0 := 99
r0 := StrReplace("aaa", "a", "b", , &c0, 0)
lines.Push("rep0=" r0 "|" c0)

c1 := 0
r1 := StrReplace("AbAb", "a", "X", 1, &c1)
lines.Push("rep_cs1=" r1 "|" c1)

; Empty needle is a no-op returning haystack unchanged
lines.Push("rep_empty=" StrReplace("abc", "", "X"))

; StrSplit empty delimiter -> chars; MaxParts=1 -> single trimmed item
ch := StrSplit("hi!")
m1 := StrSplit("  a,b,c  ", ",", " ", 1)
lines.Push("split_edge=" ch.Length ":" ch[1] ch[2] ch[3] "|" m1.Length ":" m1[1])

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
