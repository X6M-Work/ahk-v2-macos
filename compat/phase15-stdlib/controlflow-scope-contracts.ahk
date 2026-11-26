#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Static local variable initialized once and persisted across calls
NextId() {
	static n := 100
	n += 1
	return n
}
lines.Push("static=" NextId() "|" NextId() "|" NextId())

; Local shadowing vs assume-global
gVal := "outer"
ShadowFn() {
	local gVal := "inner"
	return gVal
}
GlobalFn() {
	global
	gVal := "mutated"
}
lines.Push("shadow=" ShadowFn() "|" gVal)
GlobalFn()
lines.Push("global=" gVal)

; OnExit registration & deregistration
OnExitProbe(reason, code) {
	FileAppend("exit_cb=" reason ":" code "`n", "*", "UTF-8-RAW")
}
OnExitSkipped(reason, code) {
	FileAppend("SHOULD_NOT_RUN`n", "*", "UTF-8-RAW")
}
OnExit(OnExitSkipped)
OnExit(OnExitSkipped, 0)
OnExit(OnExitProbe)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
ExitApp(0)
