#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

Emit(line) => FileAppend(line "`n", "*", "UTF-8-RAW")

txtPath := "ks_fileobj_text.txt"
binPath := "ks_fileobj_bin.dat"

try {
    ; Text FileOpen: Write, WriteLine, Seek, ReadLine, AtEOF, Length, Pos
    f := FileOpen(txtPath, "w", "UTF-8-RAW")
    f.WriteLine("alpha")
    f.Write("beta`ngamma")
    f.Close()

    f := FileOpen(txtPath, "r", "UTF-8-RAW")
    Emit("txt_len|" f.Length)
    l1 := f.ReadLine()
    l2 := f.ReadLine()
    l3 := f.ReadLine()
    Emit("txt_lines|" l1 "|" l2 "|" l3 "|eof=" f.AtEOF)
    f.Pos := 0
    Emit("txt_read5|" f.Read(5) "|pos=" f.Pos)
    f.Close()

    ; Append mode
    f := FileOpen(txtPath, "a", "UTF-8-RAW")
    f.Write("|end")
    f.Close()
    Emit("txt_appended|" StrReplace(StrReplace(FileRead(txtPath, "UTF-8-RAW"), "`r"), "`n", "/"))

    ; Binary FileOpen: typed Write/Read + RawWrite/RawRead + Seek
    b := FileOpen(binPath, "w")
    b.WriteUChar(200)
    b.WriteShort(-12345)
    b.WriteInt(0x12345678)
    b.WriteInt64(-9876543210123)
    b.WriteFloat(1.5)
    b.WriteDouble(3.25)
    rawIn := Buffer(4, 0)
    NumPut("UChar", 11, "UChar", 22, "UChar", 33, "UChar", 44, rawIn)
    b.RawWrite(rawIn, 4)
    b.Close()

    b := FileOpen(binPath, "r")
    Emit("bin_len|" b.Length)
    u8 := b.ReadUChar()
    i16 := b.ReadShort()
    i32 := b.ReadInt()
    i64 := b.ReadInt64()
    f32 := b.ReadFloat()
    f64 := b.ReadDouble()
    rawOut := Buffer(4, 0)
    nRead := b.RawRead(rawOut, 4)
    Emit("bin_vals|" u8 "|" i16 "|" i32 "|" i64 "|" Format("{:.2f}|{:.2f}", f32, f64))
    Emit("bin_raw|" nRead "|" NumGet(rawOut, 0, "UChar") "," NumGet(rawOut, 1, "UChar") "," NumGet(rawOut, 2, "UChar") "," NumGet(rawOut, 3, "UChar") "|eof=" b.AtEOF)
    b.Seek(-4, 2)
    Emit("bin_seek_end|" b.Pos "|" b.ReadUChar())
    b.Close()
} finally {
    try FileDelete(txtPath)
    try FileDelete(binPath)
}
