#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(ReportFailure)
ReportFailure(err, mode) {
    FileAppend(err.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
Total := 0
Loop 7 {
    if A_Index = 2
        continue
    if A_Index = 6
        break
    Total += A_Index
}
Iteration := 0
while Iteration < 3
    Iteration += 1
switch Iteration {
    case 3: Name := "three"
    default: Name := "other"
}
FileAppend(Format("{}|{}|{}`n", Total, Iteration, Name), "*", "UTF-8-RAW")
