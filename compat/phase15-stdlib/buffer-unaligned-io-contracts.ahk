#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Zero-byte buffer, resize 0 -> 24, unaligned NumPut/NumGet at odd offsets
b := Buffer(0)
lines.Push("b0=" b.Size)
b.Size := 24
NumPut("UChar", 0xAA, b, 0)
NumPut("Short", -1234, b, 1)
NumPut("Int", 0x12345678, b, 3)
NumPut("Int64", -9876543210123, b, 7)
NumPut("Double", 6.25, b, 15)
lines.Push("unalign=" NumGet(b, 0, "UChar") "|" NumGet(b, 1, "Short") "|" NumGet(b, 3, "Int") "|" NumGet(b, 7, "Int64") "|" Format("{:.2f}", NumGet(b, 15, "Double")))

b.Size := 0
lines.Push("b_shrink0=" b.Size)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
