#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Unmatched optional capturing group metadata
pos := RegExMatch("ac", "(a)(b)?(c)", &m)
lines.Push("opt_grp=" pos "|" m[1] "|" m[2] "|" m[3] "|" m.Pos[2] "|" m.Len[2] "|" m.Count)

; Zero-width lookahead match & StartingPos past end
pos2 := RegExMatch("xyz", "(?=y)", &m2)
lines.Push("zw=" pos2 "|" m2.Len[0] "|" RegExMatch("abc", "a", , 10))

; Non-participating named group still reports its Name; invalid subpatterns throw ValueError
RegExMatch("a", "(a)(?<opt>b)?", &m3)
errs := ""
for fn in [() => m3[99], () => m3[-1], () => m3["nope"], () => m3.Pos[99], () => m3.Len[99], () => m3.Name[99]] {
	try fn()
	catch ValueError
		errs .= "V|"
}
lines.Push("opt_name=" m3.Name[2] "|" errs)
nErr := ""
try m3.Name()
catch Error
	nErr := "Err"
lines.Push("noarg=" m3.Pos() "|" m3.Len() "|" m3.Pos "|" m3.Len "|" nErr)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
