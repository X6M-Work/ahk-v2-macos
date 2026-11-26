#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Unicode string indexing, slicing, searching, replacing, splitting
u := "café-Ω-日本"
lines.Push("ulen=" StrLen(u) "|" SubStr(u, 1, 4) "|" SubStr(u, 6, 1) "|" SubStr(u, 8, 2))
lines.Push("uinstr=" InStr(u, "Ω") "|" InStr(u, "日本"))
lines.Push("urep=" StrReplace(u, "Ω", "Δ"))
uparts := StrSplit(u, "-")
lines.Push("usplit=" uparts.Length "|" uparts[1] "|" uparts[2] "|" uparts[3])

; Ord / Chr round-trip for BMP and supplementary plane
lines.Push("ordchr=" Ord("Ω") "|" Chr(0x03A9) "|" Ord("😀") "|" Chr(0x1F600))

; Sort case-sensitive COn vs case-insensitive default
lines.Push("sort_cs=" Sort("b,A,a,B", "COn D,"))
lines.Push("sort_ci=" Sort("c,a,b", "D,"))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
