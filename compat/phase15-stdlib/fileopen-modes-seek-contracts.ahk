#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

tmp := A_Temp "\ks_fileopen_modes_" A_TickCount "_" Random(1000, 9999) ".tmp"
try {
	f := FileOpen(tmp, "w", "UTF-8-RAW")
	f.Write("abc")
	f.Close()

	f := FileOpen(tmp, "a", "UTF-8-RAW")
	f.Write("defg")
	f.Close()

	f := FileOpen(tmp, "rw", "UTF-8-RAW")
	f.Seek(0, 0)
	head := f.Read(3)
	posAfterHead := f.Pos
	lenNow := f.Length
	f.Seek(-2, 2)
	tail := f.Read()
	eofNow := f.AtEOF
	f.Seek(0, 2)
	wb := Buffer(4, 0)
	NumPut("UChar", 0x31, "UChar", 0x32, "UChar", 0x33, "UChar", 0x34, wb)
	nw := f.RawWrite(wb, 4)
	f.Seek(7, 0)
	rb := Buffer(4, 0)
	nr := f.RawRead(rb, 4)
	f.Close()

	lines.Push("read=" head "|" posAfterHead "|" lenNow "|" tail "|" eofNow)
	lines.Push("raw=" nw "|" nr "|" StrGet(rb, 4, "UTF-8"))
} finally {
	try FileDelete(tmp)
}

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
