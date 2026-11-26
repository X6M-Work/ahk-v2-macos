#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Critical & A_IsCritical
c0 := A_IsCritical
prev1 := Critical("On")
c1 := A_IsCritical
prev2 := Critical(50)
c2 := A_IsCritical
prev3 := Critical("Off")
c3 := A_IsCritical
lines.Push("crit=" c0 "|" prev1 "|" (c1 > 0 ? 1 : 0) "|" (prev2 > 0 ? 1 : 0) "|" c2 "|" prev3 "|" c3)

; Thread Priority, Interrupt, and NoTimers
Thread("Priority", 1)
Thread("Priority", 0)
Thread("Interrupt", 50, 1000)
Thread("NoTimers", true)
Thread("NoTimers", false)
lines.Push("thread=ok")

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
