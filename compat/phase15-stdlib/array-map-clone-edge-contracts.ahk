#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Array negative bounds & Length := 0
a := ["x", "y", "z"]
lines.Push("arr_neg=" a[-3] "|" a[-1])
oobErr := 0
try {
	_ := a[-4]
} catch IndexError {
	oobErr := 1
}
a.Length := 0
lines.Push("arr_clr=" oobErr "|" a.Length)

; Map: Integer vs Float vs String keys are distinct, UnsetItemError on missing key
m := Map(1, "int", 1.0, "flt", "1", "str")
lines.Push("map_types=" m[1] "|" m[1.0] "|" m["1"] "|" m.Count)

missErr := 0
try {
	_ := m["nope"]
} catch UnsetItemError {
	missErr := 1
}
lines.Push("map_miss=" missErr)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
