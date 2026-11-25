#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Array: Push, Pop, InsertAt, RemoveAt, Delete, Has, Get, negative index, Length resize, Clone
a := [10, 20, 30]
a.Push(40, 50)
p := a.Pop()
a.InsertAt(2, 15)
r := a.RemoveAt(4)
lines.Push("arr_ops=" p "|" r "|" a.Length "|" a[1] "," a[2] "," a[3] "," a[4] "|" a[-1])

a.Delete(2)
lines.Push("arr_del=" a.Has(2) "|" a.Get(2, "miss") "|" a.Get(1, "miss"))

sparse := ""
for i, v in a
	sparse .= i ":" (IsSet(v) ? v : "_") ","
lines.Push("arr_sparse=" sparse)

c := a.Clone()
c[1] := 999
lines.Push("arr_clone=" a[1] "|" c[1])

a.Length := 2
lines.Push("arr_shrink=" a.Length "|" a.Has(2) "|" a[1])
a.Length := 4
lines.Push("arr_grow=" a.Length "|" a.Has(4))

; Map: CaseSense On/Off, Default, Get, Set, Delete, Has, Count, Clear, Clone, int vs string keys
m := Map()
m.CaseSense := "Off"
m.Set("Alpha", 1, "beta", 2)
lines.Push("map_ci=" m.CaseSense "|" m["alpha"] "|" m.Has("BETA") "|" m.Count)

m.Default := "fallback"
lines.Push("map_def=" m["missing"] "|" m.Get("missing", "override"))

m.Set("gamma", 3, 1, "int1", "1", "str1")
lines.Push("map_keys=" m[1] "|" m["1"] "|" m.Count)
delVal := m.Delete("beta")
lines.Push("map_del=" delVal "|" m.Has("beta") "|" m.Count)

mc := m.Clone()
mc["Alpha"] := 100
lines.Push("map_clone=" m["Alpha"] "|" mc["Alpha"])

m.Clear()
lines.Push("map_clear=" m.Count)

ms := Map()
ms.CaseSense := "On"
ms["Key"] := "upper"
ms["key"] := "lower"
lines.Push("map_cs=" ms.CaseSense "|" ms["Key"] "|" ms["key"] "|" ms.Count)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
