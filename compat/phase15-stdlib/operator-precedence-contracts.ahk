#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Operator precedence: arithmetic, bitwise, shift, logical word operators (not/and/or)
lines.Push("prec1=" (2 + 3 * 4) "|" (2 * 3 ** 2) "|" (1 + 2 << 2) "|" (1 | 2 & 3))
lines.Push("prec2=" (not 0 ? 1 : 0) "|" (1 and 2) "|" (0 or "yes") "|" (~(-5)))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
