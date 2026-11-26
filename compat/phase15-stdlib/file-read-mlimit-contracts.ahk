#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []
p := "ks_fileread_mlimit.txt"

try {
	if FileExist(p)
		FileDelete(p)
	FileAppend("0123456789", p, "UTF-8-RAW")
	FileAppend("ABCDEF", p, "UTF-8-RAW")

	full := FileRead(p, "UTF-8")
	lim5 := FileRead(p, "m5 UTF-8")
	lines.Push("read=" full "|" lim5 "|" StrLen(lim5))
} finally {
	if FileExist(p)
		FileDelete(p)
}

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
