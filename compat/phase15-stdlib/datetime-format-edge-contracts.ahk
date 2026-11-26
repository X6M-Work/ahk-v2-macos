#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; FormatTime short timestamps, WDay, YDay, 12h/24h
lines.Push("ft1=" FormatTime("20240229090507", "yy-M-d H:m:s|hh:mm:ss"))
lines.Push("ft2=" FormatTime("20240229", "WDay") "|" FormatTime("20240229", "YDay"))
lines.Push("ft3=" FormatTime("2024", "yyyy-MM-dd"))

; DateAdd / DateDiff with short timestamps and Minutes
lines.Push("da=" DateAdd("20240229", 90, "Minutes"))
lines.Push("dd=" DateDiff("20240301013000", "20240229000000", "Minutes"))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
