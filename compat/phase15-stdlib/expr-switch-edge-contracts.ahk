#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Nested right-associative ternary
Grade(n) => n >= 90 ? "A" : n >= 80 ? "B" : n >= 70 ? "C" : "F"
lines.Push("tern=" Grade(95) "|" Grade(82) "|" Grade(70) "|" Grade(50))

; Switch with expressionless Switch (true-branch matching)
Classify(x) {
	Switch {
		Case x < 0: return "neg"
		Case x == 0: return "zero"
		Case x > 0 && x < 10: return "small"
		Default: return "big"
	}
}
lines.Push("sw_expr=" Classify(-3) "|" Classify(0) "|" Classify(5) "|" Classify(42))

; Conversion error handling
intErr := 0
try {
	Integer("not_a_number")
} catch Error {
	intErr := 1
}
fltErr := 0
try {
	Float("xyz")
} catch Error {
	fltErr := 1
}
lines.Push("conv_err=" intErr "|" fltErr)

; String edge cases: SubStr out-of-range, InStr not found, StrSplit empty string
lines.Push("str_edge=" SubStr("abc", 10) "|" InStr("abc", "z") "|" StrSplit("", ",").Length)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
