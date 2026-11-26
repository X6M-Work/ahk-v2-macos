#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

class BaseA {
	static Tag := "A"
	__New(v) {
		this.log := "A:" v
	}
	Speak() => "A"
	Val => 10
}

class MidB extends BaseA {
	__New(v) {
		super.__New(v)
		this.log .= ">B"
	}
	Speak() => super.Speak() "-B"
	Val => super.Val + 5
}

class LeafC extends MidB {
	__New(v) {
		super.__New(v)
		this.log .= ">C"
	}
	Speak() => super.Speak() "-C"
	Val => super.Val + 2
}

c := LeafC(7)
lines.Push("ctor=" c.log)
lines.Push("meth=" c.Speak() "|" c.Val "|" LeafC.Tag)
lines.Push("hier=" HasBase(c, BaseA.Prototype) "|" HasBase(LeafC, BaseA) "|" Type(c) "|" Type(LeafC) "|" Type(LeafC.Prototype))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
