#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

g := Gui()
dt := g.Add("DateTime", "w160")
dt.Value := "20260704"
mc := g.Add("MonthCal", "w220")
mc.Value := "20260704"
vDt := SubStr(dt.Value, 1, 8)
vMc := SubStr(mc.Value, 1, 8)
g.Destroy()

ok := (vDt == "20260704") && (vMc == "20260704")
FileAppend("gui-datetime-mc:" (ok ? "ok" : vDt "|" vMc) "`n", "*", "UTF-8-RAW")
ExitApp()
