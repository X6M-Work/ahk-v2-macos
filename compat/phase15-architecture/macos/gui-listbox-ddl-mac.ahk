#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

g := Gui()
lb := g.Add("ListBox", "w140 r4", ["One", "Two", "Three"])
lb.Choose(2)
lbVal := lb.Value
lbTxt := lb.Text
lb.Add(["Four"])
lb.Delete(1)

ddl := g.Add("DropDownList", "w140 Choose1", ["Red", "Green", "Blue"])
ddl.Choose(3)
ddlVal := ddl.Value
ddlTxt := ddl.Text

sl := g.Add("Slider", "w140 Range0-100", 25)
sl.Value := 70
slVal := sl.Value
g.Destroy()

ok := (lbVal == 2) && (lbTxt == "Two") && (ddlVal == 3) && (ddlTxt == "Blue") && (slVal == 70)
FileAppend("gui-list-controls:" (ok ? "ok" : lbVal "|" lbTxt "|" ddlVal "|" ddlTxt "|" slVal) "`n", "*", "UTF-8-RAW")
ExitApp()
