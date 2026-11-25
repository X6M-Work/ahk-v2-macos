#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; RegExMatch options: i, m, s, U (ungreedy), lookahead/lookbehind, StartingPos, Count, Mark
pos := RegExMatch("<b>one</b><b>two</b>", "U)<b>(.*)</b>", &m)
lines.Push("ungreedy=" pos "|" m[1] "|" m.Count)

pos2 := RegExMatch("line1`nAlpha`nline3", "im)^alpha$", &m2)
lines.Push("multiline=" pos2 "|" m2[0])

pos3 := RegExMatch("foo123bar", "(?<=foo)\d+(?=bar)", &m3)
lines.Push("look=" pos3 "|" m3[0])

pos4 := RegExMatch("abc123def456", "\d+", &m4, -6)
lines.Push("negstart=" pos4 "|" m4[0])

pos5 := RegExMatch("cat", "dog(*MARK:d)|cat(*MARK:c)", &m5)
lines.Push("mark=" pos5 "|" m5.Mark)

; RegExReplace: limit, count, escaped $$, case-insensitive
cnt := 0
r1 := RegExReplace("a1 b2 c3", "([a-z])(\d)", "$2-$1", &cnt, 2)
lines.Push("rep_lim=" r1 "|" cnt)

r2 := RegExReplace("price=5", "\d+", "$$$0")
lines.Push("rep_dollar=" r2)

; ~= regex match operator
lines.Push("re_op=" ("hello123" ~= "\d+") "|" ("hello" ~= "\d+"))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
