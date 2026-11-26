#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

s := "ababa_ABA"
lines.Push("instr=" InStr(s, "aba", false, 1, 2) "|" InStr(s, "aba", false, -1, -1) "|" InStr(s, "aba", true, -1, -1) "|" InStr(s, "aba", false, -1, -2))
lines.Push("sub=" SubStr("abcdef", -3) "|" SubStr("abcdef", -3, 2) "|" SubStr("abcdef", 2, -2) "|" SubStr("abcdef", -4, -1))

cnt := 0
r1 := StrReplace("aAaAa", "a", "x", false, &cnt, 2)
cnt2 := 0
r2 := StrReplace("aAaAa", "a", "x", true, &cnt2)
lines.Push("rep=" r1 "|" cnt "|" r2 "|" cnt2)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
