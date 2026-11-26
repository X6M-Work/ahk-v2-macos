#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Multi-type catch clause
CatchMulti(kind) {
	try {
		if (kind == 1)
			throw ValueError("v-err")
		else if (kind == 2)
			throw TypeError("t-err")
		else
			throw OSError(2)
	} catch ValueError, TypeError as err1 {
		return "vt:" err1.Message
	} catch OSError as err2 {
		return "os:" err2.Number
	}
}
lines.Push("multi=" CatchMulti(1) "|" CatchMulti(2) "|" CatchMulti(3))

; Catching non-Error thrown values (string, integer)
CatchAny(val) {
	try {
		throw val
	} catch Any as caught {
		return caught
	}
}
lines.Push("any=" CatchAny("boom") "|" CatchAny(404))

; Rethrow inside catch
rethrowLog := ""
try {
	try {
		throw ValueError("inner")
	} catch ValueError as e {
		rethrowLog .= "c1:" e.Message "|"
		throw
	}
} catch ValueError as e2 {
	rethrowLog .= "c2:" e2.Message
}
lines.Push("rethrow=" rethrowLog)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
