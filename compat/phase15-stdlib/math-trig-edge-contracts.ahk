#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

lines.Push("inv_trig=" Format("{:.4f}|{:.4f}|{:.4f}", ASin(1) * 2, ACos(0) * 2, ATan(0)))
lines.Push("mod_flt=" Format("{:.2f}|{:.2f}", Mod(5.5, 2.0), Mod(-5.5, 2.0)))
lines.Push("abs_big=" Abs(-9000000000000) "|" Format("{:.2f}", Abs(-0.75)))
lines.Push("round_neg=" Round(1499, -3) "|" Round(1500, -3) "|" Round(-1500, -3))
lines.Push("exp_log=" Format("{:.4f}|{:.4f}|{:.4f}", Exp(0), Ln(1), Log(100)))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
