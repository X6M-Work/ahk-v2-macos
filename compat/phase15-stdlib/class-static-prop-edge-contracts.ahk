#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

class Counter {
	static _count := 0
	static __New() {
		this._count := 10
	}
	static Count {
		get => this._count
		set => this._count := value
	}
	Add(a, b) => a + b + Counter.Count
}

lines.Push("sinit=" Counter.Count)
Counter.Count := 20
lines.Push("sset=" Counter.Count)

c := Counter()
bm := ObjBindMethod(c, "Add", 5)
lines.Push("bindm=" bm(7) "|" HasProp(Counter, "Count") "|" HasMethod(c, "Add"))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
