#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#Warn Experimental, Off
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

g := Gui()
g.SetFont("s12")
ed := g.Add("Edit", "x20 y25 w140 h28", "seed")
ed.SetFont("s12 Bold")
ef := ed.Font
ed.GetPos(&ex, &ey, &ew, &eh)
ed.Move(30, 35, 160, 32)
ed.GetPos(&ex2, &ey2, &ew2, &eh2)

pb := g.Add("Progress", "w150 h20 Range0-200", 50)
pb.Value := 125
pbVal := pb.Value

cb := g.Add("CheckBox", "Checked", "Agree")
cbVal := cb.Value
cb.Value := 0
cbVal2 := cb.Value
g.Destroy()

ok := (ef.Size == 12) && (ef.Weight == 700) && (ex == 20) && (ey == 25) && (ex2 == 30) && (ey2 == 35) && (ew2 == 160) && (pbVal == 125) && (cbVal == 1) && (cbVal2 == 0)
FileAppend("gui-controls-coords:" (ok ? "ok" : ef.Size "|" ef.Weight "|" ex "," ey "|" ex2 "," ey2 "," ew2 "|" pbVal "|" cbVal "|" cbVal2) "`n", "*", "UTF-8-RAW")
ExitApp()
