#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

lines.Push("sign=" Format("{:+06d}|{:+06d}|{: 6d}|{:-6s}", 42, -42, 7, "hi"))
lines.Push("trunc=" Format("{:.3s}|{:-5.2s}|{:5.2s}", "abcdef", "abcdef", "abcdef"))
lines.Push("alt=" Format("{:#x}|{:#X}|{:#o}|{:#o}|{:#.0f}", 255, 255, 0, 64, 5.0))
lines.Push("gen=" Format("{:g}|{:G}|{:.4g}|{:.4G}", 123.45, 1234567.0, 0.0001234, 12345.0))
lines.Push("case=" Format("{:U}|{:L}|{:T}", "aBc", "aBc", "hello world"))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
