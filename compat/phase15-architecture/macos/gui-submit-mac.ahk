#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

g := Gui()
g.Add("Edit", "vEd1", "single")
g.Add("Edit", "vEd2 r3", "multi`nline")
g.Add("CheckBox", "vChk3 Check3", "Tri")
g["Chk3"].Value := -1
g.Add("Radio", "vRadGrp", "R1")
g.Add("Radio", "Checked", "R2")
g.Add("Radio", "vRadA Group Checked", "RA")
g.Add("Radio", "vRadB", "RB")
g.Add("DropDownList", "vDdl Choose2", ["A", "B", "C"])
g.Add("DropDownList", "vDdlAlt AltSubmit Choose2", ["A", "B", "C"])
g.Add("ListBox", "vLb Choose2", ["X", "Y", "Z"])
g.Add("ListBox", "vLbAlt AltSubmit Choose2", ["X", "Y", "Z"])
g.Add("Slider", "vSl Range0-100", 42)
g.Add("Hotkey", "vHk", "^a")
saved := g.Submit(false)
g.Destroy()

ok := (saved.Ed1 == "single")
    && (StrReplace(saved.Ed2, "`n", "|") == "multi|line")
    && (saved.Chk3 == -1)
    && (saved.RadGrp == 2)
    && (saved.RadA == 1) && (saved.RadB == 0)
    && (saved.Ddl == "B") && (saved.DdlAlt == 2)
    && (saved.Lb == "Y") && (saved.LbAlt == 2)
    && (saved.Sl == 42) && (Type(saved.Sl) == "Integer")
    && (saved.Hk = "^a")
FileAppend("gui-submit:" (ok ? "ok" : saved.Ed1 "|" saved.Chk3 "|" saved.RadGrp "|" saved.RadA "|" saved.RadB "|" saved.Ddl "|" saved.DdlAlt "|" saved.Lb "|" saved.LbAlt "|" saved.Sl "|" Type(saved.Sl)) "`n", "*", "UTF-8-RAW")
ExitApp()
