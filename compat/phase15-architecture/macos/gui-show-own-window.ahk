#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

g := Gui(, "KS Mac Probe Window")
g.Add("Text", "w200 h24", "HelloMacText")
g.Show("w260 h120 NoActivate")
hwnd := g.Hwnd
exists := WinExist("ahk_id " hwnd)
title := WinGetTitle("ahk_id " hwnd)
WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " hwnd)
wtxt := WinGetText("ahk_id " hwnd)
g.Opt("+AlwaysOnTop")
g.Opt("-AlwaysOnTop")
g.Destroy()

ok := (exists == hwnd) && (title == "KS Mac Probe Window") && (ww >= 200) && (wh >= 100) && InStr(wtxt, "HelloMacText")
FileAppend("gui-own-win:" (ok ? "ok" : exists "|" title "|" ww "x" wh "|" wtxt) "`n", "*", "UTF-8-RAW")
ExitApp()
