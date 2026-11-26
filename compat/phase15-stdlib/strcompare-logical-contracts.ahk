#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

lines.Push("cmp=" (StrCompare("abc", "ABC", "Off") == 0) "|" (StrCompare("abc", "ABC", "On") > 0) "|" (StrCompare("file2", "file10", "Logical") < 0))
lines.Push("ver=" VerCompare("2.0.10", "2.0.2") "|" VerCompare("2.0.0-beta.1", "2.0.0") "|" VerCompare("2.0.0", "2.0") "|" VerCompare("2.1.0", ">=2.0.5") "|" VerCompare("1.9.9", ">=2.0.5"))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
