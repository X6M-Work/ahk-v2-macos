#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(ReportFailure)
ReportFailure(err, mode) {
    FileAppend(err.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
MakeCounter(Start) {
    Count := Start
    return (*) => ++Count
}
First := MakeCounter(10)
Second := MakeCounter(100)
FileAppend(Format("{}|{}|{}`n", First(), First(), Second()), "*", "UTF-8-RAW")
