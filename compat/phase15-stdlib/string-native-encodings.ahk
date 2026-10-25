#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(ReportFailure)
ReportFailure(err, mode) {
    FileAppend(err.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
Emit(text) => FileAppend(text "`n", "*", "UTF-8-RAW")

Emit("file-default-encoding|" A_FileEncoding)
Emit("empty-encoding|" (StrPut("a", "") = StrPut("a", "CP0")))
buf := Buffer(32, 0)
NumPut("UChar", 65, buf)
Emit("empty-read|" StrGet(buf, ""))
for encoding in ["UTF-8", "CP1252", "UTF-16"] {
    buf := Buffer(64, 0)
    StrPut("été", buf, encoding)
    Emit(encoding "|" StrGet(buf, encoding) "|" StrGet(buf.Ptr, encoding))
}

FileEncoding("UTF-8")
FileEncoding("")
Emit("file-empty-encoding|" (A_FileEncoding = "CP0"))

for encoding in ["CP0", "CP1252", "UTF-8", "UTF-8-RAW", "UTF-16", "UTF-16-RAW", 0, 1252, 65001, 1200] {
    FileEncoding(encoding)
    Emit("setting|" encoding "|" A_FileEncoding)
}
FileEncoding("UTF-16-RAW")
stream := FileOpen("explicit-empty.txt", "w", "")
stream.Write("a")
stream.Close()
stream := FileOpen("omitted.txt", "w")
stream.Write("a")
stream.Close()
Emit("file-open-empty|" FileGetSize("explicit-empty.txt"))
Emit("file-open-omitted|" FileGetSize("omitted.txt"))
FileEncoding("CP1252")
CheckEncoding() {
    Emit("timer-encoding|" A_FileEncoding)
    ExitApp()
}
SetTimer(CheckEncoding, -20)
