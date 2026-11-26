#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Map.Set chaining, Default override, and Delete on missing key throws UnsetItemError
m := Map()
m.Set("a", 1).Set("b", 2)
m.Default := -1
lines.Push("chain=" m["a"] "|" m["b"] "|" m["missing"] "|" m.Get("missing", 99))

delErr := 0
try {
	m.Delete("nope")
} catch UnsetItemError {
	delErr := 1
}
lines.Push("del_err=" delErr)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
