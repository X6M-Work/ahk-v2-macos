#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []
pBom := "ks_u16_bom.txt"
pRaw := "ks_u16_raw.txt"
sample := "café-Ω-日本"

try {
	for _, p in [pBom, pRaw]
		if FileExist(p)
			FileDelete(p)

	f1 := FileOpen(pBom, "w", "UTF-16")
	f1.Write(sample)
	f1.Close()

	f2 := FileOpen(pRaw, "w", "UTF-16-RAW")
	f2.Write(sample)
	f2.Close()

	b1 := FileRead(pBom, "RAW")
	b2 := FileRead(pRaw, "RAW")
	lines.Push("u16_sz=" b1.Size "|" b2.Size "|" NumGet(b1, 0, "UChar") "|" NumGet(b1, 1, "UChar"))
	lines.Push("u16_txt=" FileRead(pBom, "UTF-16") "|" FileRead(pRaw, "UTF-16"))
} finally {
	for _, p in [pBom, pRaw]
		if FileExist(p)
			FileDelete(p)
}

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
