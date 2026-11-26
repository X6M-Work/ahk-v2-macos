#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; NumPut/NumGet on raw pointer with negative offset
b := Buffer(24, 0)
NumPut("Int64", 1234567890123, "Int", -77, b)
midPtr := b.Ptr + 8
lines.Push("neg_off=" NumGet(midPtr, -8, "Int64") "|" NumGet(midPtr, 0, "Int"))

; StrPut/StrGet with explicit length (no NUL needed for prefix read)
sbuf := Buffer(16, 0)
StrPut("ABCDEFGH", sbuf, "UTF-8")
lines.Push("str_len=" StrGet(sbuf, 4, "UTF-8") "|" StrGet(sbuf.Ptr + 2, 3, "UTF-8"))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
