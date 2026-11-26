#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Array InsertAt multi-value, RemoveAt range, Pop on empty throws IndexError
a := [1, 5]
a.InsertAt(2, 2, 3, 4)
lines.Push("ins=" a.Length ":" a[1] "," a[2] "," a[3] "," a[4] "," a[5])
a.RemoveAt(2, 3)
lines.Push("rem=" a.Length ":" a[1] "," a[2])

emptyErr := 0
e := []
try {
	e.Pop()
} catch Error {
	emptyErr := 1
}
lines.Push("pop_err=" emptyErr)

; Map CaseSense change on non-empty Map throws Error
m := Map("k", 1)
csErr := 0
try {
	m.CaseSense := "Off"
} catch Error {
	csErr := 1
}
m.Capacity := 32
lines.Push("map_cs_err=" csErr "|" (m.Capacity >= 32 ? 1 : 0))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
