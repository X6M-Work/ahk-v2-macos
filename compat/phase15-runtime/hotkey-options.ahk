#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError(ReportFailure)
ReportFailure(err, mode) {
    FileAppend(err.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}

for options in ["T2P-3B0S1I0", "t255 p+7 b s0 i0", "T1T3P-2P5B1B0S0SI", "T`t+2P`r`n-3B0S1I 100", "P999999999999999999999", "P-999999999999999999999", "P", "I", "OnOff"]
    Hotkey("F24", (*) => "", options " Off")

for options in ["P2Z", "T0", "T256", "T-1", "T", "I101", "I-1", "B2", "S2", "O", "On1", "P0x01B", "P+", "`n", "ſ"] {
    rejected := false
    try Hotkey("F24", (*) => "", options)
    catch ValueError
        rejected := true
    if !rejected
        FileAppend("fail accepted [" options "]`n", "*", "UTF-8-RAW")

    rejected := false
    try Hotkey("F23", (*) => "", options)
    catch ValueError
        rejected := true
    if !rejected
        FileAppend("fail created [" options "]`n", "*", "UTF-8-RAW")
    exists := true
    try Hotkey("F23", "Off")
    catch
        exists := false
    if exists
        FileAppend("fail partial creation [" options "]`n", "*", "UTF-8-RAW")
}
FileAppend("pass`n", "*", "UTF-8-RAW")
ExitApp()
