#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Format escaped braces, alt-form #x/#X, zero-pad, char, scientific, general
lines.Push("braces=" Format("{{}{1}{}}", "ok"))
lines.Push("alt=" Format("{:#x}|{:#X}|{:#o}", 255, 255, 8))
lines.Push("pad=" Format("{:06d}|{:08.2f}|{:c}", 42, 3.5, 65))
lines.Push("sci=" Format("{:.2e}|{:.2E}|{:g}", 1234.5, 1234.5, 12.34))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
