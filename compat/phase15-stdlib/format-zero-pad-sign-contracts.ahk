#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

lines.Push("fpad=" Format("{:06.1f}|{:+06.1f}|{: 06.1f}|{:06.1f}", 3.5, 3.5, 3.5, -3.5))
lines.Push("xpad=" Format("{:#08x}|{:#08X}|{:#06o}", 0x1a, 0x1a, 8))
lines.Push("ipad=" Format("{:05d}|{:+05d}|{: 05d}|{:05d}", 7, 7, 7, -7))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
