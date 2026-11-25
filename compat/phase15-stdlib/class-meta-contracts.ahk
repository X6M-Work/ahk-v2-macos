#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

class Box {
	static Created := 0
	_val := 0
	__New(v := 0) {
		Box.Created += 1
		this._val := v
	}
	Val {
		get => this._val
		set => this._val := value * 2
	}
	__Item[k] {
		get => this._val + k
		set => this._val := value - k
	}
}

class Dyn {
	__New() {
		this.DefineProp("_store", { Value: Map() })
	}
	__Get(name, params) => this._store.Has(name) ? this._store[name] : "none:" name
	__Set(name, params, value) => (this._store[name] := value)
	__Call(name, params) => "call:" name ":" params.Length
}

b := Box(5)
lines.Push("box_init=" Box.Created "|" b.Val "|" b[3])
b.Val := 10
lines.Push("box_set=" b.Val "|" b[1])
b[4] := 30
lines.Push("box_idx=" b.Val)

d := Dyn()
d.foo := "bar"
lines.Push("dyn=" d.foo "|" d.missing "|" d.ping(1, 2, 3))

; HasOwnProp, HasProp, HasMethod, DeleteProp, OwnProps
o := { a: 1, b: 2 }
lines.Push("props=" o.HasOwnProp("a") "|" o.HasProp("HasOwnProp") "|" o.HasMethod("HasOwnProp") "|" b.HasProp("Val"))
o.DeleteProp("a")
ownList := ""
for k, v in o.OwnProps()
	ownList .= k "=" v ","
lines.Push("own=" o.HasOwnProp("a") "|" ownList)

; Type() and is hierarchy
lines.Push("types=" Type(1) "|" Type(1.5) "|" Type("s") "|" Type(b) "|" (1 is Integer) "|" (1 is Number) "|" (1 is Primitive) "|" (b is Box) "|" (b is Object) "|" (b is Any))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
