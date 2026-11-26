#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; One-shot SetTimer and cancelled timer
hits := 0
cancelledHits := 0
OnOnce() {
	global hits
	hits += 1
}
OnCancel() {
	global cancelledHits
	cancelledHits += 1
}

t0 := A_TickCount
SetTimer(OnCancel, -120)
SetTimer(OnCancel, 0)
SetTimer(OnOnce, -20)

deadline := A_TickCount + 2000
while (hits < 1 && A_TickCount < deadline)
	Sleep(10)
Sleep(40)
t1 := A_TickCount

lines.Push("timer=" hits "|" cancelledHits "|" (t1 >= t0 ? 1 : 0))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
ExitApp()
