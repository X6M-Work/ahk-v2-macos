#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

g := Gui()
dt := g.Add("DateTime", "w160")
dt.Value := "20260704"
mc := g.Add("MonthCal", "w220")
mc.Value := "20260704"
vDt := SubStr(dt.Value, 1, 8)
vMc := SubStr(mc.Value, 1, 8)
dtBadErr := ""
try dt.Value := "notadate"
catch Any as e
    dtBadErr := Type(e)
mcBadErr := ""
try mc.Value := "20261301"
catch Any as e
    mcBadErr := Type(e)
mcEmptyErr := ""
try mc.Value := ""
catch Any as e
    mcEmptyErr := Type(e)
g.Destroy()

ok := (vDt == "20260704") && (vMc == "20260704")
    && (dtBadErr == "ValueError") && (mcBadErr == "ValueError") && (mcEmptyErr == "ValueError")
FileAppend("gui-datetime-mc:" (ok ? "ok" : vDt "|" vMc "|" dtBadErr "|" mcBadErr "|" mcEmptyErr) "`n", "*", "UTF-8-RAW")
ExitApp()
