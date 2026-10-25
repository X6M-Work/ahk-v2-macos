#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(ReportFailure)
ReportFailure(err, mode) {
    FileAppend(err.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
Count := 0
Left := false && ++Count
Right := true || ++Count
Choice := Count = 0 ? "zero" : "changed"
FileAppend(Format("{}|{}|{}|{}|{}|{}`n", Count, Left, Right, Choice, "AHK" = "ahk", "AHK" == "ahk"), "*", "UTF-8-RAW")
