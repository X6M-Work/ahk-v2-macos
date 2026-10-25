#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(ReportFailure)
ReportFailure(err, mode) {
    FileAppend(err.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
Swap(&Left, &Right) {
    Temporary := Left
    Left := Right
    Right := Temporary
}
Scale(Value, Factor := 3) => Value * Factor
Present(Value?) => IsSet(Value)
Left := 4
Right := 9
Swap(&Left, &Right)
FileAppend(Format("{}|{}|{}|{}|{}|{}`n", Left, Right, Scale(5), Scale(5, 2), Present(), Present(0)), "*", "UTF-8-RAW")
