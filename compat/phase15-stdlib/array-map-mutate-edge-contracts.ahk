#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Array InsertAt head, RemoveAt negative index, sparse Clone
a := [10, 20, 30]
a.InsertAt(1, 5)
removed := a.RemoveAt(-1)
a.Delete(2)
c := a.Clone()
lines.Push("arr=" removed "|" a.Length "|" c.Has(1) "|" c.Has(2) "|" c.Has(3) "|" c[1] "|" c[3])

; Map CaseSense Off preserves original key casing when updated
m := Map()
m.CaseSense := "Off"
m["CamelKey"] := 1
m["camelkey"] := 2
gotKey := ""
gotVal := 0
for k, v in m {
	gotKey := k
	gotVal := v
}
lines.Push("map_case=" gotKey "|" gotVal "|" m.Count)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
