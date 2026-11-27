#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

; Live macOS AppKit / Eto check: GuiControl.Visible before Show (default, Hidden, Opt, setter)
; and TreeView Bold item state (Modify Bold / -Bold, Get Bold).
g := Gui()
ed := g.Add("Edit", "w120", "hello")
edH := g.Add("Edit", "w120 Hidden", "hidden")
v0 := ed.Visible ? 1 : 0
vh0 := edH.Visible ? 1 : 0

ed.Opt("+Hidden")
v1 := ed.Visible ? 1 : 0
ed.Opt("-Hidden")
v2 := ed.Visible ? 1 : 0
ed.Visible := false
v3 := ed.Visible ? 1 : 0
ed.Visible := true
v4 := ed.Visible ? 1 : 0

tv := g.Add("TreeView", "w180 h90")
r1 := tv.Add("Alpha")
b0 := tv.Get(r1, "Bold") ? 1 : 0
tv.Modify(r1, "Bold")
b1 := tv.Get(r1, "Bold") ? 1 : 0
tv.Modify(r1, "-Bold")
b2 := tv.Get(r1, "Bold") ? 1 : 0

g.Destroy()

ok := (v0 == 1 && vh0 == 0 && v1 == 0 && v2 == 1 && v3 == 0 && v4 == 1 && b0 == 0 && b1 == 1 && b2 == 0) ? 1 : 0
FileAppend("ok=" ok " vis=" v0 vh0 v1 v2 v3 v4 " bold=" b0 b1 b2 "`n", "*", "UTF-8-RAW")
ExitApp(ok ? 0 : 1)
