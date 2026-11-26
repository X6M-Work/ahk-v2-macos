#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Mod with negative divisors and ZeroDivisionError checks
lines.Push("mod_neg=" Mod(7, -3) "|" Mod(-7, -3) "|" Mod(0, 5))

z1 := 0, z2 := 0, z3 := 0
try {
	_ := 1 / 0
} catch ZeroDivisionError {
	z1 := 1
}
try {
	_ := 1 // 0
} catch ZeroDivisionError {
	z2 := 1
}
try {
	_ := Mod(5, 0)
} catch ZeroDivisionError {
	z3 := 1
}
lines.Push("zdiv=" z1 "|" z2 "|" z3)

; Whitespace-padded numeric strings & division types
lines.Push("pad_num=" Integer("  42  ") "|" Format("{:.2f}", Float(" -3.5 ")) "|" Integer("0X10"))
lines.Push("div_t=" Type(1 / 2) "|" Type(10 / 2) "|" Type(10 // 2) "|" Format("{:.1f}", 1 / 2))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
