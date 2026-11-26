#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; InStr reverse search with negative Occurrence and negative StartingPos
s := "ab-ab-ab"
lines.Push("rinstr=" InStr(s, "ab", , -1, -1) "|" InStr(s, "ab", , -1, -2) "|" InStr(s, "ab", , -1, -3) "|" InStr(s, "ab", , -3, 1))

; SubStr with negative StartingPos and negative Length
lines.Push("nsub=" SubStr("0123456789", -5, -2) "|" SubStr("0123456789", -3, -1))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
