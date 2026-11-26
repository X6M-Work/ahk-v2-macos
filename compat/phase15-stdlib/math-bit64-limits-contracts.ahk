#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; 64-bit signed integer limits & unsigned right shift
maxI64 := 0x7FFFFFFFFFFFFFFF
minI64 := ~maxI64
lines.Push("i64=" maxI64 "|" minI64 "|" (1 << 63) "|" ((1 << 63) >>> 63))

; Min / Max single-arg and mixed numeric types
lines.Push("mm=" Min(42) "|" Max(42) "|" Min(-1.5, -2, 0) "|" Max(-1.5, -2, -0.5))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
