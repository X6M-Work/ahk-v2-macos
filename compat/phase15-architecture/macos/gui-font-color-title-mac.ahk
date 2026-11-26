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
g.Destroy()

ok := (tTitle == "MacStyledTitle") && (tText == "StyledText") && (tw >= 140) && (th > 0)
FileAppend("gui-style:" (ok ? "ok" : tTitle "|" tText "|" tw "|" th) "`n", "*", "UTF-8-RAW")
ExitApp()
