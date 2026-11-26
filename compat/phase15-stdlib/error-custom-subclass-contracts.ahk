#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

class CustomErr extends Error {
	__New(msg, code) {
		super.__New(msg)
		this.Code := code
	}
}

caught := ""
try {
	throw CustomErr("bad state", 503)
} catch CustomErr as ce {
	caught := ce.Message "|" ce.Code "|" (ce is Error) "|" (ce is CustomErr) "|" Type(ce)
} catch Error {
	caught := "wrong"
}
lines.Push("cerr=" caught)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
