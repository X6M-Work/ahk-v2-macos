#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Dotall s), multiline m), and newline modes `a), `n)
lines.Push("dotall=" RegExMatch("a`nb", "a.b") "|" RegExMatch("a`nb", "s)a.b"))
lines.Push("nl_a=" StrReplace(StrReplace(StrReplace(RegExReplace("x`r`ny`nz`rw", "`am)^", ">"), "`r`n", "/"), "`n", "/"), "`r", "/"))
lines.Push("nl_n=" StrReplace(RegExReplace("x`ny", "`nm)^", ">"), "`n", "/"))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
