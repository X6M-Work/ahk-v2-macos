#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(ReportFailure)
ReportFailure(err, mode) {
    FileAppend(err.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
Position := RegExMatch("item-042 tail", "i)([a-z]+)-(\d+)", &Match)
Replaced := RegExReplace("a1 b22 c333", "\d+", "#")
FileAppend(Format("{}|{}|{}|{}|{}`n", Position, Match[1], Match[2], Match.Len(0), Replaced), "*", "UTF-8-RAW")
