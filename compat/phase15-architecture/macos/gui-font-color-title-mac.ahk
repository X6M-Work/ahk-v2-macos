#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

g := Gui("+Resize +MinSize120x80", "InitTitle")
g.Title := "MacStyledTitle"
g.BackColor := "223344"
g.SetFont("s12 cFF8800", "Helvetica")
txt := g.Add("Text", "w140", "StyledText")
txt.GetPos(&tx, &ty, &tw, &th)
tTitle := g.Title
tText := txt.Text
missErr := ""
try _ := g["NoSuchCtrl"]
catch Any as e
    missErr := Type(e)
g.Destroy()
deadErr := ""
try g.Add("Text", , "after")
catch Any as e
    deadErr := Type(e)

ok := (tTitle == "MacStyledTitle") && (tText == "StyledText") && (tw >= 140) && (th > 0)
    && (missErr == "UnsetItemError") && (deadErr == "Error")
FileAppend("gui-style:" (ok ? "ok" : tTitle "|" tText "|" tw "|" th "|" missErr "|" deadErr) "`n", "*", "UTF-8-RAW")
ExitApp()
