#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Parameterized property with 2 arguments (get & set)
class Grid {
	cells := Map()
	Cell[r, c] {
		get => this.cells.Get(r "," c, 0)
		set => this.cells[r "," c] := value
	}
}

g := Grid()
g.Cell[2, 3] := 99
lines.Push("grid=" g.Cell[2, 3] "|" g.Cell[1, 1])

; Inherited __Get / __Call on subclass
class BaseMeta {
	__Get(name, params) => "base_get:" name
	__Call(name, params) => "base_call:" name ":" params.Length
}
class SubMeta extends BaseMeta {
	ownVal := 7
}
sm := SubMeta()
lines.Push("meta_inh=" sm.ownVal "|" sm.unknownProp "|" sm.unknownFn(1, 2))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
