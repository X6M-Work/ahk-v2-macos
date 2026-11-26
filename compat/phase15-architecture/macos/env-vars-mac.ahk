#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

ok := (StrLen(A_Temp) > 0) && (StrLen(A_UserName) > 0) && (StrLen(A_ComputerName) > 0) && (StrLen(A_OSVersion) > 0) && (A_Is64bitOS == 1) && (A_PtrSize == 8) && (A_WorkingDir != "")
FileAppend("env-vars-mac:" (ok ? "ok" : A_Temp "|" A_UserName "|" A_ComputerName "|" A_OSVersion "|" A_Is64bitOS "|" A_PtrSize) "`n", "*", "UTF-8-RAW")
ExitApp()
