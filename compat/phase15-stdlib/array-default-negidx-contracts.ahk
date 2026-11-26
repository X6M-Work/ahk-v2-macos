#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Array negative-index Has/Get/Delete/InsertAt and Default property
a := [10, 20, 30]
a.Default := "fallback"
lines.Push("neg=" a.Has(-1) "|" a.Get(-1) "|" a.Get(-3))
a.Delete(-2)
lines.Push("del_neg=" a.Has(2) "|" a[2] "|" a.Get(2, "ov"))
a.InsertAt(-1, 25)
lines.Push("ins_neg=" a.Length "|" a[3] "|" a[4])

a.Capacity := 32
lines.Push("cap=" (a.Capacity >= 32 ? 1 : 0))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
