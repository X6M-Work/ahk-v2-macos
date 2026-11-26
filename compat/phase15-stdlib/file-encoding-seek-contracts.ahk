#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []
bomFile := "ks_bom_test.txt"
rawFile := "ks_raw_test.txt"

try {
	for _, p in [bomFile, rawFile]
		if FileExist(p)
			FileDelete(p)

	; UTF-8 with BOM vs UTF-8-RAW without BOM
	f1 := FileOpen(bomFile, "w", "UTF-8")
	f1.Write("ABCD1234")
	f1.Close()

	f2 := FileOpen(rawFile, "w", "UTF-8-RAW")
	f2.Write("ABCD1234")
	f2.Close()

	rawBuf1 := FileRead(bomFile, "RAW")
	rawBuf2 := FileRead(rawFile, "RAW")
	lines.Push("bom_sizes=" rawBuf1.Size "|" rawBuf2.Size "|" NumGet(rawBuf1, 0, "UChar") "|" NumGet(rawBuf1, 1, "UChar") "|" NumGet(rawBuf1, 2, "UChar"))
	lines.Push("read_txt=" FileRead(bomFile, "UTF-8") "|" FileRead(rawFile, "UTF-8"))

	; Seek from end (origin=2) and current (origin=1)
	fr := FileOpen(rawFile, "r", "UTF-8-RAW")
	fr.Seek(-4, 2)
	tail := fr.Read(4)
	fr.Seek(-6, 1)
	mid := fr.Read(2)
	fr.Close()
	lines.Push("seek=" tail "|" mid)
} finally {
	for _, p in [bomFile, rawFile]
		if FileExist(p)
			FileDelete(p)
}

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
