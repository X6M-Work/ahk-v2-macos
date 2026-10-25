#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(ReportFailure)
ReportFailure(err, mode) {
    FileAppend(err.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
Values := [1, 2, 3]
Values.InsertAt(2, 9)
Removed := Values.RemoveAt(3)
Values.Delete(2)
FileAppend(Format("{}|{}|{}|{}|{}`n", Removed, Values.Length, Values[1], Values.Has(2), Values[-1]), "*", "UTF-8-RAW")
