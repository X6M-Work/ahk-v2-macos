#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

g := Gui()
gb := g.Add("GroupBox", "w200 h80", "Choice")
r1 := g.Add("Radio", "xp+10 yp+20 Checked", "OptA")
r2 := g.Add("Radio", "xp y+6", "OptB")
v1 := r1.Value
v2 := r2.Value
r2.Value := 1
v1b := r1.Value
v2b := r2.Value

sb := g.Add("StatusBar")
sb.SetParts(100, 100)
sb.SetText("Ready", 1)
sb.SetText("OK", 2)
g.Destroy()

ok := (v1 == 1) && (v2 == 0) && (v1b == 0) && (v2b == 1)
FileAppend("gui-sb-radio:" (ok ? "ok" : v1 "|" v2 "|" v1b "|" v2b) "`n", "*", "UTF-8-RAW")
ExitApp()
