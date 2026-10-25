#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(ReportFailure)
ReportFailure(err, mode) {
    FileAppend(err.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
Text := "Été漢字"
FileAppend(Format("{}|{}|{}|{}`n", StrLen(Text), SubStr(Text, 4, 2), InStr(Text, "漢"), StrReplace("a😀a", "a", "é")), "*", "UTF-8-RAW")
