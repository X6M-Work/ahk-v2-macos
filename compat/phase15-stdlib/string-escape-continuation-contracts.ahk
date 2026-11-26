#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Escape sequences and quote styles
lines.Push("esc=" Ord("`n") "|" Ord("`r") "|" Ord("`t") "|" Ord("`b") "|" Ord("``"))
lines.Push("q=" 'say "hi"' "|" "it's ok")

; Continuation section with LTrim and Join|
block := "
(LTrim Join|
    alpha
    beta
    gamma
)"
lines.Push("cont=" block)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
