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

    eMissing := 0, eWhich := 0, eEmpty := 0, eMode := 0, eLoopMode := 0
    try FileGetTime("no-such-file.txt")
    catch OSError
        eMissing := 1
    try FileGetTime(filePath, "X")
    catch ValueError
        eWhich := 1
    try FileGetTime("")
    catch ValueError
        eEmpty := 1
    try FileSetTime("20220304050607", filePath, "M", "FX")
    catch ValueError
        eMode := 1
    try {
        Loop Files "*", "FX"
            break
    } catch ValueError
        eLoopMode := 1
    Emit("errors|" eMissing "|" eWhich "|" eEmpty "|" eMode "|" eLoopMode)
} finally {
    try FileDelete(filePath)
    try DirDelete(dirPath, true)
}
