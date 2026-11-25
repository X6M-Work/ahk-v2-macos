#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Short-circuit && and || return operand values in AHK v2
side := 0
Bump() {
	global side
	side += 1
	return "bumped"
}
lines.Push("sc_and=" ("first" && "second") "|" (0 && Bump()) "|" side)
lines.Push("sc_or=" (0 || "fallback") "|" ("kept" || Bump()) "|" side)

; == vs = and !== vs !=
lines.Push("eq=" ("abc" = "ABC" ? 1 : 0) "|" ("abc" == "ABC" ? 1 : 0) "|" ("abc" != "ABC" ? 1 : 0) "|" ("abc" !== "ABC" ? 1 : 0))

; Integer division //, exponentiation ** (right-associative), bitwise shifts << >> >>>
lines.Push("idiv=" (7 // 2) "|" (-7 // 2) "|" (7 // -2) "|" (-7 // -2))
lines.Push("pow=" (2 ** 3 ** 2) "|" ((-2) ** 3) "|" (-2 ** 2))
lines.Push("shift=" (1 << 5) "|" (-16 >> 2) "|" (-1 >>> 60))

; Compound assignments
v := 100
v //= 7
v <<= 1
v |= 1
s := "hi"
s .= "!"
lines.Push("comp=" v "|" s)

; Built-in runtime vars
ThisName() => A_ThisFunc
lines.Push("bvars=" StrLen(A_Space) "|" StrLen(A_Tab) "|" (A_LineNumber > 0 ? 1 : 0) "|" ThisName() "|" A_PtrSize)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
