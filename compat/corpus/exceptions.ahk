#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(ReportFailure)
ReportFailure(err, mode) {
    FileAppend(err.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
Finalized := 0
Result := ""
try {
    throw ValueError("bad", "fixture", "detail")
} catch ValueError as Problem {
    Result := Format("{}|{}|{}", Type(Problem), Problem.Message, Problem.Extra)
} finally {
    Finalized += 1
}
FileAppend(Format("{}|{}`n", Result, Finalized), "*", "UTF-8-RAW")
