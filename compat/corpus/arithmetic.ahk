#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(ReportFailure)
ReportFailure(err, mode) {
    FileAppend(err.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
FileAppend(Format("{}|{}|{}|{}|{}|{:.2f}`n", 3 + 4 * 2, (3 + 4) * 2, 2 ** 3, 17 // 5, Mod(17, 5), 7 / 2), "*", "UTF-8-RAW")
