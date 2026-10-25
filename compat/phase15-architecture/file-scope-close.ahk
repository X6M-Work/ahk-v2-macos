#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))
WriteLocal() {
    stream := FileOpen("scope.txt", "w-rwd", "UTF-8-RAW")
    stream.Write("sealed")
}
WriteLocal()
try text := FileRead("scope.txt", "UTF-8")
catch
    text := "locked"
FileAppend("read:" text "`n", "*", "UTF-8-RAW")
ExitApp()
