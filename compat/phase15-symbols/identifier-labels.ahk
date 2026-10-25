#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(ReportFailure)
ReportFailure(err, mode) {
    FileAppend(err.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
name := "Õ"
goto(name)
õ:
FileAppend("wrong-small`n", "*", "UTF-8-RAW")
goto finish
Õ:
FileAppend("capital`n", "*", "UTF-8-RAW")
name := "ς"
goto(name)
σ:
FileAppend("wrong-sigma`n", "*", "UTF-8-RAW")
goto finish
ς:
FileAppend("final-sigma`n", "*", "UTF-8-RAW")
goto mIxEd
Mixed:
FileAppend("ascii`n", "*", "UTF-8-RAW")
finish:
FileAppend(IsLabel("õ") "|" IsLabel("Õ") "|" IsLabel("σ") "|" IsLabel("ς") "|" IsLabel("mixed") "`n", "*", "UTF-8-RAW")
