#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

class Outer {
	static Prefix := "OUT"
	class Inner {
		__New(v) {
			this.v := v
		}
		static Tag() => Outer.Prefix ":IN"
		Label() => Outer.Prefix "-" this.v
	}
}

inst := Outer.Inner(7)
lines.Push("nested=" Type(inst) "|" Outer.Inner.Tag() "|" inst.Label() "|" (inst is Outer.Inner))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
