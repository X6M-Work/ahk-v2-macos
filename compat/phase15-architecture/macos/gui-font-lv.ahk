#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#Warn Experimental, Off
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

g := Gui()
g.SetFont("s12 Bold")
fh := g.FontHandle
fSnap := g.Font

tab := g.Add("Tab3", "w220 h120", ["One", "Two"])
tab.UseTab()
tab.GetPos(&tx, &ty, &tw, &th)

lv := g.Add("ListView", "w200 h80", ["Name", "Val"])
lv.Add(, "alpha", "1")
lv.Add(, "beta", "2")
lv.SetRowColor(1, "Red", "White")
lv.SetCellColor(2, 2, "Blue", "Yellow")
lv.ClearColors()
rowCount := lv.GetCount()
g.Destroy()

ok := (fh != 0) && (fSnap.Size == 12) && (fSnap.Weight == 700) && (tw >= 200) && (th >= 100) && (rowCount == 2)
FileAppend("gui-font-lv:" (ok ? "ok" : fh "|" fSnap.Size "|" fSnap.Weight "|" tw "|" th "|" rowCount) "`n", "*", "UTF-8-RAW")
ExitApp()
