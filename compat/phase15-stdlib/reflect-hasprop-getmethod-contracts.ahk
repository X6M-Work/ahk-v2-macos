#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

class BaseC {
	Ping(x) => "base:" x
	Val => 10
}
class SubC extends BaseC {
	__New() {
		this.own := 42
	}
}

s := SubC()
m := GetMethod(s, "Ping")
lines.Push("has=" HasProp(s, "own") "|" HasProp(s, "Val") "|" HasProp(s, "Missing") "|" HasMethod(s, "Ping") "|" HasMethod(s, "Val") "|" HasMethod(s, "own"))
lines.Push("own=" ObjHasOwnProp(s, "own") "|" ObjHasOwnProp(s, "Val") "|" ObjOwnPropCount(s))
lines.Push("call=" m(s, 7) "|" HasMethod([], "Push") "|" HasProp([], "Length") "|" HasMethod(Map(), "Get"))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
