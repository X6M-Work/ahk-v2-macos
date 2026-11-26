#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

lines.Push("empty=" StrLen(Sort("")) "|" Sort("only"))
lines.Push("rc=" Sort("a,B,A,b", "R COn D,"))
lines.Push("nspace=" Sort(" 10, 2, -3", "N D,"))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
