#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

g := Gui()
gb := g.Add("GroupBox", "w200 h120", "BoxTitle")
cb := g.Add("CheckBox", "xp+10 yp+20 Check3", "TriState")
cb.Value := -1
v1 := cb.Value
cb.Value := 1
v2 := cb.Value
lk := g.Add("Link", "w160", 'Visit <a href="https://example.com">Site</a>')
hk := g.Add("Hotkey", "w120")
hk.Value := "^!a"
hkVal := hk.Value
btn := g.Add("Button", "w80", "Click")
btn.Enabled := false
en := btn.Enabled
btn.Visible := false
vis := btn.Visible
gbText := gb.Text
lkText := lk.Text
g.Destroy()

ok := (gbText == "BoxTitle") && (v1 == -1) && (v2 == 1) && (InStr(lkText, "Site") > 0) && (StrUpper(hkVal) == "^!A") && (en == 0) && (vis == 0)
FileAppend("gui-misc-ctls:" (ok ? "ok" : gbText "|" v1 "|" v2 "|" lkText "|" hkVal "|" en "|" vis) "`n", "*", "UTF-8-RAW")
ExitApp()
