#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

; Write a minimal valid 1x1 24-bit BMP (58 bytes)
bmpPath := A_Temp "/ks_il_test_" A_TickCount ".bmp"
bmp := Buffer(58, 0)
NumPut("UChar", 0x42, "UChar", 0x4D, "UInt", 58, "UInt", 0, "UInt", 54, bmp, 0)
NumPut("UInt", 40, "Int", 1, "Int", 1, "UShort", 1, "UShort", 24, bmp, 14)
NumPut("UChar", 0x00, "UChar", 0x80, "UChar", 0xFF, bmp, 54)
f := FileOpen(bmpPath, "w")
f.RawWrite(bmp, 58)
f.Close()

il := IL_Create(2)
idx := IL_Add(il, bmpPath)

g := Gui()
lv := g.Add("ListView", "w200 h80", ["Name"])
lv.SetImageList(il, 1)
lv.Add("Icon1", "Row1")

tv := g.Add("TreeView", "w200 h80")
tv.SetImageList(il)
n1 := tv.Add("Node1", 0, "Icon1")

ok := (il != 0) && (idx == 1) && (lv.GetCount() == 1) && (lv.GetText(1, 1) == "Row1") && (tv.GetCount() == 1) && (tv.GetText(n1) == "Node1")
g.Destroy()
il2 := IL_Create(1)
idx2 := IL_Add(il2, bmpPath)
destroyed := IL_Destroy(il2)
FileDelete(bmpPath)
ok := ok && (il2 != 0) && (idx2 == 1) && (destroyed == 1)
FileAppend("gui-imagelist:" (ok ? "ok" : il "|" idx "|" il2 "|" idx2 "|" destroyed) "`n", "*", "UTF-8-RAW")
ExitApp()
