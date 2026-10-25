#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(ReportFailure)
ReportFailure(err, mode) {
    FileAppend(err.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
õ() => "o-small"
Õ() => "o-capital"
σ() => "sigma"
ς() => "final-sigma"
MiXeD() => "ascii"
FileAppend(õ() "|" Õ() "|" σ() "|" ς() "|" mixed() "`n", "*", "UTF-8-RAW")
name := "Õ"
FileAppend(%name%() "`n", "*", "UTF-8-RAW")
