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

sl.Value := 999
slHi := sl.Value
sl.Value := -50
slLo := sl.Value
pr.Value := 999
prHi := pr.Value
pr.Value := -50
prLo := pr.Value
ud.Value := 999
udHi := ud.Value
ud.Value := -50
udLo := ud.Value
udBad := ""
try ud.Value := "abc"
catch TypeError
	udBad := "TypeError"
tabErrs := ""
try tab.Value := 99
catch ValueError
	tabErrs .= "H|"
try tab.Value := -1
catch ValueError
	tabErrs .= "N|"

ok := (slHi == 100) && (slLo == 0) && (prHi == 100) && (prLo == 0) && (udHi == 50) && (udLo == 1) && (udBad == "TypeError") && (tabErrs == "H|N|") && (tab.Value == 2)
g.Destroy()
FileAppend("gui-tab-slider:" (ok ? "ok" : slHi "|" slLo "|" prHi "|" prLo "|" udHi "|" udLo "|" udBad "|" tabErrs "|" tab.Value) "`n", "*", "UTF-8-RAW")
ExitApp()
