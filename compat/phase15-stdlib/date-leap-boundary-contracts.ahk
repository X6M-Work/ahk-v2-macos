#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Century leap-year rules (1900 non-leap, 2000 leap) and year-boundary subtraction
lines.Push("leap=" DateAdd("19000228000000", 1, "Days") "|" DateAdd("20000228000000", 1, "Days"))
lines.Push("ybound=" DateAdd("20250101000000", -1, "Seconds"))
lines.Push("diff_yr=" DateDiff("20250101000000", "20240101000000", "Days") "|" DateDiff("20240101000000", "20230101000000", "Days"))

uErr := ""
try DateAdd("20260704", 1, "Centuries")
catch ValueError
	uErr .= "A|"
try DateDiff("20260704", "20260703", "Centuries")
catch ValueError
	uErr .= "D|"
try DateAdd("", 1, "Days")
catch ValueError
	uErr .= "E|"
lines.Push("uerr=" uErr)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
