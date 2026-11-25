#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; DateAdd / DateDiff across leap day and negative intervals
d1 := DateAdd("20240228120000", 1, "Days")
d2 := DateAdd("20240228120000", 2, "Days")
d3 := DateAdd("20240301000000", -1, "Hours")
lines.Push("dateadd=" d1 "|" d2 "|" d3)
lines.Push("datediff=" DateDiff("20240301000000", "20240228000000", "Days") "|" DateDiff("20240228000000", "20240301000000", "Hours") "|" DateDiff("20240228010203", "20240228000000", "Seconds"))

; FormatTime deterministic numeric tokens
lines.Push("fmttime=" FormatTime("20240229153045", "yyyy-MM-dd HH:mm:ss") "|" FormatTime("20240229", "YDay"))

; Round: positive N, zero N, negative N, half-away-from-zero
lines.Push("round=" Round(2.5) "|" Round(3.5) "|" Round(-2.5) "|" Round(-3.5) "|" Round(3.14159, 2) "|" Round(1234, -2) "|" Round(1250, -2))

; Ceil / Floor / Mod / Min / Max / Random exact bound
lines.Push("math=" Ceil(2.1) "|" Ceil(-2.1) "|" Floor(2.9) "|" Floor(-2.9) "|" Mod(7, 3) "|" Mod(-7, 3) "|" Min(5, -2, 9) "|" Max(5, -2, 9) "|" Random(7, 7))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
