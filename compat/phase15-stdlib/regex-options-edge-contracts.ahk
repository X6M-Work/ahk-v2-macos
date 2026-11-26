#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; D) dollar-endonly, A) anchored, J) duplicate named groups, x) extended
lines.Push("opt_D=" RegExMatch("abc`n", "abc$") "|" RegExMatch("abc`n", "D)abc$"))
lines.Push("opt_A=" RegExMatch("abc", "bc") "|" RegExMatch("abc", "A)bc") "|" RegExMatch("abc", "A)ab"))
pJ := RegExMatch("b", "J)(?<x>a)|(?<x>b)", &mJ)
lines.Push("opt_J=" pJ "|" mJ["x"])
pX := RegExMatch("ab12", "x) ab  # letters`n \d+ # digits", &mX)
lines.Push("opt_x=" pX "|" mX[0])

; RegExReplace empty-match insertion & $U0/$L0/$T0
lines.Push("rep_empty=" RegExReplace("abc", "", "-"))
lines.Push("rep_case0=" RegExReplace("aBc", "\w+", "$U0|$L0|$T0"))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
