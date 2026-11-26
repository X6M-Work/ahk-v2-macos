#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []
p := "ks_file_eol_trunc.txt"

try {
	if FileExist(p)
		FileDelete(p)

	; Write CRLF, read with `n translation (CRLF -> LF)
	f := FileOpen(p, "w", "UTF-8-RAW")
	f.Write("L1`r`nL2`r`n")
	f.Close()

	fr := FileOpen(p, "r `n", "UTF-8-RAW")
	all := fr.Read()
	fr.Close()
	lines.Push("eol_len=" StrLen(all) "|" StrReplace(all, "`n", "/"))

	; File.Length truncation
	ft := FileOpen(p, "rw", "UTF-8-RAW")
	ft.Length := 2
	ft.Seek(0, 0)
	trunc := ft.Read()
	ft.Close()
	lines.Push("trunc=" StrLen(trunc) "|" trunc)
} finally {
	if FileExist(p)
		FileDelete(p)
}

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
