#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Sort P<n> (sort by character position), Z (trailing delimiter), U + D,
lines.Push("sort_P=" Sort("x3,a1,m2", "P2 D,"))
lines.Push("sort_Z=" Sort("b,a,", "D,") "|" Sort("b,a,", "Z D,"))
lines.Push("sort_U=" Sort("B,a,b,A", "U D,"))
lines.Push("sort_NR=" Sort("3,10,2,-5,0", "N R D,"))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
