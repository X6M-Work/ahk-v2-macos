#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

g := Gui()

; ListView bulk row-0 Modify (Select, -Select, Check, -Check), GetCount("Selected"), GetNext Focused, ModifyCol rename
lv := g.Add("ListView", "w240 h100 Checked", ["ColA", "ColB"])
lv.Add(, "r1", "v1")
lv.Add(, "r2", "v2")
lv.Add(, "r3", "v3")
lv.Modify(0, "Select")
selAll := lv.GetCount("Selected")
lv.Modify(0, "-Select")
unselAll := lv.GetCount("Selected")
lv.Modify(2, "Select Focus")
selFoc := (lv.GetCount("Selected") == 1) && (lv.GetNext(0, "Focused") == 2)
lv.Modify(0, "Check")
chkAll := (lv.GetNext(0, "Checked") == 1) && (lv.GetNext(1, "Checked") == 2) && (lv.GetNext(2, "Checked") == 3)
lv.Modify(0, "-Check")
unchkAll := (lv.GetNext(0, "Checked") == 0)
lv.ModifyCol(1, 100, "RenamedA")
hdrOk := (lv.GetText(0, 1) == "RenamedA")
lvOk := (selAll == 3) && (unselAll == 0) && selFoc && chkAll && unchkAll && hdrOk

; TreeView Select/GetSelection, Check/GetNext Checked, rename, Full traversal
tv := g.Add("TreeView", "w200 h100 Checked")
r1 := tv.Add("Root1")
c1 := tv.Add("Child1", r1)
r2 := tv.Add("Root2")
tv.Modify(c1, "Select")
tv.Modify(c1, "Check")
tv.Modify(c1, , "RenamedChild")
n1 := tv.GetNext(0, "Full")
n2 := tv.GetNext(n1, "Full")
n3 := tv.GetNext(n2, "Full")
n4 := tv.GetNext(n3, "Full")
tvOk := (tv.GetSelection() == c1) && (tv.GetNext(0, "Checked") == c1)
    && (tv.GetText(c1) == "RenamedChild")
    && (n1 == r1) && (n2 == c1) && (n3 == r2) && (n4 == 0)

; StatusBar SetParts + SetText + Text
sb := g.Add("StatusBar")
sb.SetParts(80, 120)
sb.SetText("Part1", 1)
sb.SetText("Part2", 2)
sb.SetText("Part3", 3)
sbOk := (sb.Text == "Part1")

g.Destroy()
ok := lvOk && tvOk && sbOk
FileAppend("gui-lv-tv-bulk:" (ok ? "ok" : lvOk "|" tvOk "|" sbOk) "`n", "*", "UTF-8-RAW")
ExitApp()
