#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

g := Gui()

; ListView Insert, Sort, SortDesc, Integer Sort, Delete all
lv := g.Add("ListView", "w220 h100", ["Item", "Num"])
lv.Add(, "b", "2")
lv.Add(, "a", "10")
lv.Insert(1, , "c", "1")
insOk := (lv.GetCount() == 3) && (lv.GetText(1, 1) == "c") && (lv.GetText(2, 1) == "b") && (lv.GetText(3, 1) == "a")
lv.ModifyCol(1, "Sort")
sortOk := (lv.GetText(1, 1) == "a") && (lv.GetText(2, 1) == "b") && (lv.GetText(3, 1) == "c")
lv.ModifyCol(1, "SortDesc")
sortDOk := (lv.GetText(1, 1) == "c") && (lv.GetText(2, 1) == "b") && (lv.GetText(3, 1) == "a")
lv.ModifyCol(2, "Integer Sort")
sortIOk := (lv.GetText(1, 2) == "1") && (lv.GetText(2, 2) == "2") && (lv.GetText(3, 2) == "10")
lv.Delete()
lvOk := insOk && sortOk && sortDOk && sortIOk && (lv.GetCount() == 0)

; TreeView hierarchy, navigation, Delete(id), Delete() all
tv := g.Add("TreeView", "w220 h100")
r1 := tv.Add("R1")
c1 := tv.Add("C1", r1)
c2 := tv.Add("C2", r1)
r2 := tv.Add("R2")
tvOk := (tv.GetCount() == 4)
    && (tv.GetParent(c1) == r1) && (tv.GetChild(r1) == c1)
    && (tv.GetNext(c1) == c2) && (tv.GetPrev(c2) == c1)
    && (tv.GetNext(r1) == r2)
    && (tv.GetText(c1) == "C1") && (tv.GetText(c2) == "C2")
tv.Delete(c1)
tvOk := tvOk && (tv.GetCount() == 3) && (tv.GetChild(r1) == c2)
tv.Delete()
tvOk := tvOk && (tv.GetCount() == 0)

; Tab.UseTab invalid name -> ValueError
tab := g.Add("Tab3", "w180 h80", ["Alpha", "Beta"])
tabErr := ""
try tab.UseTab("NoSuch")
catch ValueError
    tabErr := "ValueError"
tab.UseTab()

g.Destroy()
ok := lvOk && tvOk && (tabErr == "ValueError")
FileAppend("gui-lv-tv-sort:" (ok ? "ok" : lvOk "|" tvOk "|" tabErr) "`n", "*", "UTF-8-RAW")
ExitApp()
