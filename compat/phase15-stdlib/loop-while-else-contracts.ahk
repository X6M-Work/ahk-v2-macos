#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; While ... Else
w0 := "no"
While false
	w0 := "body"
Else
	w0 := "else"

wBrk := "no"
n := 0
While (n < 5) {
	n += 1
	if (n == 2)
		break
} Else {
	wBrk := "else"
}
lines.Push("while_else=" w0 "|" wBrk "|" n)

; Loop Parse ... Else on empty input
lp0 := "no"
Loop Parse, "", ","
	lp0 := "body"
Else
	lp0 := "else"
lines.Push("parse_else=" lp0)

; A_Index inside For loop
idxStr := ""
for _, v in ["a", "b", "c"]
	idxStr .= A_Index ":" v ","
lines.Push("for_aidx=" idxStr)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
