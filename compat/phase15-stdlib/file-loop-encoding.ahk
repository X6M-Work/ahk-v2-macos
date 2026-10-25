#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(ReportFailure)
ReportFailure(err, mode) {
    FileAppend(err.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
Emit(text) => FileAppend(text "`n", "*", "UTF-8-RAW")

for encoding in ["CP1252", "UTF-8-RAW", "UTF-16-RAW"] {
    FileEncoding(encoding)
    fileName := "lines.txt"
    FileAppend("été`r`nfin`n", fileName, encoding)
    lines := ""
    Loop Read fileName
        lines .= A_LoopReadLine "|"
    Emit(encoding "|" lines)
    FileDelete(fileName)
}
FileEncoding("CP1252")
FileAppend("été`n", "bom.txt", "UTF-8")
Loop Read "bom.txt"
    Emit("bom|" A_LoopReadLine)
try {
    Loop Read "missing.txt"
        Emit("unexpected")
} catch as err
    Emit("missing|" Type(err))
Loop Read "missing.txt"
    Emit("unexpected")
else
    Emit("missing-else")
