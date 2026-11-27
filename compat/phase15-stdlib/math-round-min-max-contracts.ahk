#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

lines.Push("rnd=" Round(1234, -2) "|" Round(1250, -2) "|" Round(1.5) "|" Round(-1.5) "|" Round(2.5) "|" Round(-2.5))
lines.Push("fc=" Floor(2.3) "|" Floor(-2.3) "|" Ceil(2.3) "|" Ceil(-2.3))
lines.Push("mm=" Min(5, -2, 9, 0) "|" Max(5, -2, 9, 0) "|" Abs(-42) "|" Abs(-3.5))
lines.Push("mod=" Mod(7, 3) "|" Mod(-7, 3) "|" Mod(7, -3) "|" Mod(-7, -3))

domErrs := ""
for fn in [() => Sqrt(-1), () => Log(-1), () => Ln(-1), () => ASin(2), () => ACos(-2)] {
	try fn()
	catch ValueError
		domErrs .= "V|"
	catch Error
		domErrs .= "E|"
}
lines.Push("dom=" domErrs)

mmEmptyErrs := ""
for fn in [() => Min([]*), () => Max([]*)] {
	try fn()
	catch Error as e
		mmEmptyErrs .= Type(e) "|"
}
lines.Push("mm_empty=" mmEmptyErrs)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
