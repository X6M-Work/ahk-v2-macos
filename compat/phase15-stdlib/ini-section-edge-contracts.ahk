#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []
ini := "ks_ini_edge_test.ini"

try {
	if FileExist(ini)
		FileDelete(ini)
	IniWrite("a=b=c", ini, "Sec1", "K1")
	IniWrite("val2", ini, "Sec1", "K2")
	IniWrite("other", ini, "Sec2", "K3")

	lines.Push("k1=" IniRead(ini, "Sec1", "K1"))
	lines.Push("miss=" IniRead(ini, "Sec1", "NoKey", "DEF"))
	secs := StrReplace(Sort(IniRead(ini)), "`n", ",")
	lines.Push("secs=" secs)

	IniDelete(ini, "Sec1", "K2")
	lines.Push("del_k=" IniRead(ini, "Sec1", "K2", "GONE"))
	IniDelete(ini, "Sec2")
	lines.Push("del_s=" IniRead(ini))
} finally {
	if FileExist(ini)
		FileDelete(ini)
}

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
