#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError(HandleError)
HandleError(err, mode) {
    FileAppend("trapped:" Type(err) ":" err.Message "`n", "**", "UTF-8-RAW")
    ExitApp(23)
}
throw Error("phase15-error")
