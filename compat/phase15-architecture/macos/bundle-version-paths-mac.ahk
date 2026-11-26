#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

ver := FileGetVersion("/System/Applications/Calculator.app")
okVer := RegExMatch(ver, "^\d+\.\d+") > 0
okApp := (SubStr(A_AppData, -27) == "/Library/Application Support") && (A_AppDataCommon == "/Library/Application Support")
okSys := (A_PtrSize == 8) && (A_Is64bitOS == 1) && (A_OSVersion != "") && (A_UserName != "")

ok := okVer && okApp && okSys
FileAppend("bundle-paths:" (ok ? "ok" : ver "|" A_AppData "|" A_AppDataCommon "|" A_OSVersion) "`n", "*", "UTF-8-RAW")
ExitApp()
