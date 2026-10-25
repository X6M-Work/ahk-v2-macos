#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(ReportFailure)
ReportFailure(err, mode) {
    FileAppend(err.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
Values := Map()
Values.CaseSense := false
Values["Key"] := 7
Values["KEY"] := 8
FileAppend(Format("{}|{}|{}|{}`n", Values.Count, Values["key"], Values.Has("kEy"), Values.Get("missing", 99)), "*", "UTF-8-RAW")
