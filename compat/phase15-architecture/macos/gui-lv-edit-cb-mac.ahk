#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

g := Gui()

; ListView with Checked rows, Modify, GetText, InsertCol, DeleteCol, Delete
lv := g.Add("ListView", "w240 h100 Checked", ["Name", "Score"])
lv.Add("Check", "Alice", "10")
lv.Add("", "Bob", "20")
lv.Modify(2, "Check", "Bobby", "25")
lvOk := (lv.GetCount() == 2) && (lv.GetCount("Col") == 2)
    && (lv.GetText(1, 1) == "Alice") && (lv.GetText(2, 1) == "Bobby") && (lv.GetText(2, 2) == "25")
    && (lv.GetNext(0, "Checked") == 1) && (lv.GetNext(1, "Checked") == 2)
lv.InsertCol(3, , "Extra")
colAfterIns := lv.GetCount("Col")
lv.DeleteCol(3)
colAfterDel := lv.GetCount("Col")
lv.Delete(1)
lvOk := lvOk && (colAfterIns == 3) && (colAfterDel == 2) && (lv.GetCount() == 1)

; Edit Value/Text + ReadOnly toggle
ed := g.Add("Edit", "w140", "hello")
ed.Opt("+ReadOnly")
ed.Value := "world"
ed.Opt("-ReadOnly")
edOk := (ed.Value == "world") && (ed.Text == "world")

; ComboBox Choose/Text/Value/Add/Delete
cb := g.Add("ComboBox", "w140", ["A", "B"])
cb.Add(["C"])
cb.Choose(3)
cbOk := (cb.Value == 3) && (cb.Text == "C")
cb.Delete(1)
cb.Choose(1)
cbOk := cbOk && (cb.Value == 1) && (cb.Text == "B")

; Check3 tri-state transitions (0 -> -1 -> 1 -> 0)
chk := g.Add("CheckBox", "Check3", "Tri")
chk.Value := -1
vIndet := chk.Value
chk.Value := 1
vChk := chk.Value
chk.Value := 0
vUnchk := chk.Value
chkOk := (vIndet == -1) && (vChk == 1) && (vUnchk == 0)

g.Destroy()
ok := lvOk && edOk && cbOk && chkOk
FileAppend("gui-lv-edit-cb:" (ok ? "ok" : lvOk "|" edOk "|" cbOk "|" chkOk) "`n", "*", "UTF-8-RAW")
ExitApp()
