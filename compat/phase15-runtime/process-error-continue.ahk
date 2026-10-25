#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
errors := 0
OnError(ContinueError)
ContinueError(err, mode) {
    global errors
    errors += 1
    if Type(err) != "TypeError" {
        FileAppend("unexpected:" Type(err) "`n", "**", "UTF-8-RAW")
        ExitApp(1)
    }
    return -1
}
Integer("not-a-number")
FileAppend("continued:" errors "`n", "*", "UTF-8-RAW")
ExitApp()
