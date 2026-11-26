#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Numeric vs string comparison semantics in AHK v2
lines.Push("cmp_str=" ("010" = "10" ? 1 : 0) "|" ("010" == "10" ? 1 : 0) "|" (10 = "10" ? 1 : 0) "|" (10 = "010" ? 1 : 0))
lines.Push("cmp_num=" (10 = 10.0 ? 1 : 0) "|" (10 == 10.0 ? 1 : 0) "|" (Number("0x10") == 16 ? 1 : 0) "|" Type(Number("0x10")) "|" Type(Number("-1.25")))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
