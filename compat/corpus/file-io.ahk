#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(ReportFailure)
ReportFailure(err, mode) {
    FileAppend(err.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
Path := A_WorkingDir "/conformance.txt"
FileAppend("été`nline", Path, "UTF-8-RAW")
Content := FileRead(Path, "UTF-8")
Lines := StrSplit(Content, "`n")
Existed := !!FileExist(Path)
FileDelete(Path)
FileAppend(Format("{}|{}|{}|{}|{}`n", Lines.Length, Lines[1], Lines[2], Existed, !!FileExist(Path)), "*", "UTF-8-RAW")
