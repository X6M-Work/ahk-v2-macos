#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Format specifiers: hex, octal, sign, width, left-align, precision, scientific
lines.Push("fmt_int=" Format("{:08X}|{:x}|{:o}|{:+d}|{: 4d}", 0x1A2B, 255, 64, 7, 9))
lines.Push("fmt_str=" Format("[{:5s}]|[{:-5s}]|[{:.3s}]", "hi", "hi", "abcdef"))
lines.Push("fmt_flt=" Format("{:.2f}|{:.4f}", 3.14159, 0.5))

; Hex & negative hex parsing
lines.Push("hex=" Integer("0x10") "|" Integer("-0x10") "|" Integer("0xFF") "|" Float("-2.5"))

; Trig / log / exp / sqrt / abs
lines.Push("trig=" Format("{:.4f}|{:.4f}|{:.4f}|{:.4f}", Sqrt(2), Log(1000), Ln(Exp(2)), Abs(-42.5)))
lines.Push("trig2=" Format("{:.4f}|{:.4f}|{:.4f}", Sin(0), Cos(0), ATan(1) * 4))

; Min / Max with mixed numeric strings, ints, floats
lines.Push("minmax=" Min("10", 2, 3.5) "|" Max("10", 2, 3.5))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
