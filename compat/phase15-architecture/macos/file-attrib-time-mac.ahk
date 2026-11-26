#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

p := "ks_mac_apfs_probe.txt"
try {
	if FileExist(p) {
		FileSetAttrib("-R", p)
		FileDelete(p)
	}
	FileAppend("apfs-data", p, "UTF-8-RAW")
	FileSetTime("20250615102030", p, "M")
	t := FileGetTime(p, "M")
	FileSetAttrib("+R", p)
	attrR := InStr(FileGetAttrib(p), "R") > 0
	FileSetAttrib("-R", p)
	attrW := InStr(FileGetAttrib(p), "R") == 0
	sz := FileGetSize(p)
} finally {
	if FileExist(p) {
		FileSetAttrib("-R", p)
		FileDelete(p)
	}
}

ok := (t == "20250615102030") && attrR && attrW && (sz == 9)
FileAppend("apfs-fileops:" (ok ? "ok" : t "|" attrR "|" attrW "|" sz) "`n", "*", "UTF-8-RAW")
ExitApp()
