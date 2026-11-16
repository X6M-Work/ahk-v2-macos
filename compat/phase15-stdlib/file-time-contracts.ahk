#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

Emit(line) => FileAppend(line "`n", "*", "UTF-8-RAW")

filePath := "sample.txt"
dirPath := "folder"
DirCreate(dirPath)
FileAppend("hello", filePath, "UTF-8-RAW")

try {
    FileSetTime("20210203040506", filePath, "M")
    tM := FileGetTime(filePath, "M")
    tBlank := FileGetTime(filePath, "")
    Emit("file_m|" tM)
    Emit("file_blank|" tBlank)

    tDir := FileGetTime(dirPath)
    Emit("dir_len|" StrLen(tDir))
    Emit("dir_istime|" IsTime(tDir))

    FileSetTime("20220304050607", dirPath, "M", "D")
    Emit("dir_m|" FileGetTime(dirPath, "M"))
} finally {
    try FileDelete(filePath)
    try DirDelete(dirPath, true)
}
