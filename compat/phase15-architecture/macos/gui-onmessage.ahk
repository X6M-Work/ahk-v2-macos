#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#Warn Experimental, Off
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

g := Gui()
btn := g.Add("Button", "w100 h30", "Click")
hGui := (guiObj, wp, lp, msg) => ""
hCtrl := (ctrlObj, wp, lp, msg) => ""
g.OnMessage(0x0201, hGui)
btn.OnMessage(0x0201, hCtrl)
g.OnMessage(0x0201, hGui, 0)
btn.OnMessage(0x0201, hCtrl, 0)
g.Destroy()

FileAppend("gui-onmessage:ok`n", "*", "UTF-8-RAW")
ExitApp()
