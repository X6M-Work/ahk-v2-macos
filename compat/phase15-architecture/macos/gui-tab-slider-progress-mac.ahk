#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

g := Gui()
tab := g.Add("Tab3", "w240 h140", ["One", "Two"])
tab.UseTab(1)
sl := g.Add("Slider", "Range0-100", 25)
sl.Value := 60
pr := g.Add("Progress", "Range0-100", 10)
pr.Value := 75
tab.UseTab(2)
ed := g.Add("Edit", "w80")
ud := g.Add("UpDown", "Range1-50", 12)
ud.Value := 33
tab.UseTab()
tab.Choose(2)

ok := (sl.Value == 60) && (pr.Value == 75) && (ud.Value == 33) && (tab.Value == 2)
g.Destroy()
FileAppend("gui-tab-slider:" (ok ? "ok" : sl.Value "|" pr.Value "|" ud.Value "|" tab.Value) "`n", "*", "UTF-8-RAW")
ExitApp()
