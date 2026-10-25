#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(ReportFailure)
ReportFailure(err, mode) {
    FileAppend(err.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
Sum(Values*) {
    Total := 0
    for Value in Values
        Total += Value
    return Total
}
Values := [2, 3, 5]
Bound := Sum.Bind(10)
FileAppend(Format("{}|{}|{}`n", Sum(Values*), Bound(4, 6), Sum()), "*", "UTF-8-RAW")
