#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

SplitPath("C:\dir\sub\file.tar.gz", &n1, &d1, &e1, &ne1, &dr1)
lines.Push("sp1=" n1 "|" d1 "|" e1 "|" ne1 "|" dr1)

SplitPath("https://example.com/a/b/page.html", &n2, &d2, &e2, &ne2, &dr2)
lines.Push("sp2=" n2 "|" d2 "|" e2 "|" ne2 "|" dr2)

SplitPath("plain.txt", &n3, &d3, &e3, &ne3, &dr3)
lines.Push("sp3=" n3 "|" d3 "|" e3 "|" ne3 "|" dr3)

SplitPath("C:\dir\sub\", &n4, &d4, &e4, &ne4, &dr4)
lines.Push("sp4=" n4 "|" d4 "|" e4 "|" ne4 "|" dr4)

lines.Push("dir=" (DirExist(A_Temp) != "" ? 1 : 0) "|" (FileExist(A_Temp "\__ks_nonexistent_9999__") == "" ? 1 : 0))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
