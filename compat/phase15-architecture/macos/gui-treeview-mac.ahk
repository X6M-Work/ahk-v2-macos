#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

g := Gui()
tv := g.Add("TreeView", "w200 h120")
r1 := tv.Add("Root1")
c1 := tv.Add("Child1", r1)
c2 := tv.Add("Child2", r1)
tv.Modify(c2, , "Child2Renamed")
t1 := tv.GetText(r1)
t2 := tv.GetText(c2)
par := tv.GetParent(c1)
ch := tv.GetChild(r1)
cnt1 := tv.GetCount()
tv.Delete(c1)
cnt2 := tv.GetCount()
g.Destroy()

ok := (t1 == "Root1") && (t2 == "Child2Renamed") && (par == r1) && (ch == c1) && (cnt1 == 3) && (cnt2 == 2)
FileAppend("gui-treeview:" (ok ? "ok" : t1 "|" t2 "|" (par == r1) "|" (ch == c1) "|" cnt1 "|" cnt2) "`n", "*", "UTF-8-RAW")
ExitApp()
