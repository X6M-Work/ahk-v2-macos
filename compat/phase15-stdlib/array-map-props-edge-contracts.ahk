#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

a := [10, 20, 30]
a.Length := 5
lines.Push("grow=" a.Length "|" a.Has(3) "|" a.Has(4) "|" a.Has(5) "|" (a.Capacity >= 5))

prev := a.Delete(2)
lines.Push("del=" prev "|" a.Has(2) "|" a.Length)

a.Length := 1
lines.Push("shrink=" a.Length "|" a[1] "|" a.Has(2))

a.Pop()
popErr := ""
try a.Pop()
catch Error
	popErr := "Error"
lines.Push("pop=" a.Length "|" popErr)

negErr := ""
try a.Length := -1
catch ValueError
	negErr .= "L|"
try a.Capacity := -1
catch ValueError
	negErr .= "C|"
lines.Push("neg=" negErr)

m := Map()
m.CaseSense := "Off"
m.Default := "fallback"
m["Alpha"] := 1
m["alpha"] := 2
lines.Push("map=" m.Count "|" m["ALPHA"] "|" m["missing"] "|" m.Has("missing") "|" m.Delete("ALPHA") "|" m.Count)

mCapErr := ""
try m.Capacity := -1
catch MemoryError
	mCapErr := "MemoryError"
lines.Push("mcap=" mCapErr)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
