#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Sort numeric with floats & negative floats
lines.Push("sort_flt=" Sort("-2.5,10,1.5,-10,0", "N D,"))

; Sort with custom comparator preserving order via offset tie-breaker
RevLenStable(a, b, offset) {
	d := StrLen(b) - StrLen(a)
	return d != 0 ? d : -offset
}
lines.Push("sort_off=" Sort("aa,bbb,cc,d", "D,", RevLenStable))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
