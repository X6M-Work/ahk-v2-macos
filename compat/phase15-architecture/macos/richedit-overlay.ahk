#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#Warn Experimental, Off
#NoTrayIcon
#Import Ks { Overlay }
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

g := Gui()
re := g.Add("RichEdit", "w240 h100")
re.Value := "hello`nworld"
len := re.TextLength
lines := re.LineCount
re.Select(1, 5)
sel := re.SelectedText
re.SetFormat(1, 5, "cRed bold")
fmt := re.GetFormat(1, 5)
g.Destroy()

ov := Overlay(10, 10, 16, 8)
ov.Canvas.FillRect(0, 0, 16, 8, "0xFFFF0000")
p1 := ov.Canvas.GetPixel(4, 4)
ov.Redraw((canvas) => canvas.FillRect(0, 0, 16, 8, "0xFF00FF00"))
p2 := ov.Canvas.GetPixel(4, 4)
ov.Destroy()

ok := (len >= 11) && (lines >= 2) && (sel == "hello") && (fmt.Weight == 700) && (p1 == 0xFFFF0000) && (p2 == 0xFF00FF00)
FileAppend("richedit-overlay:" (ok ? "ok" : len "|" lines "|" sel "|" fmt.Weight "|" Format("{:X}|{:X}", p1, p2)) "`n", "*", "UTF-8-RAW")
ExitApp()
