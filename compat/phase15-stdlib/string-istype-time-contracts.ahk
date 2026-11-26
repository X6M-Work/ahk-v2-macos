#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

lines.Push("is_chr=" IsAlpha("abc") "|" IsAlpha("ab1") "|" IsDigit("12345") "|" IsDigit("-5") "|" IsLower("abc") "|" IsUpper("ABC"))
lines.Push("is_time=" IsTime("20240229") "|" IsTime("20230229") "|" IsTime("20241301") "|" IsTime("20240101250000") "|" IsTime("20240101235959"))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
