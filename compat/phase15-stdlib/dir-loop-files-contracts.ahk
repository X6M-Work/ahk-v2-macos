#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []
root := "ks_loopfiles_root"
sub := root "/sub"

try {
	if DirExist(root)
		DirDelete(root, true)
	DirCreate(sub)
	FileAppend("hello", root "/a.txt", "UTF-8-RAW")
	FileAppend("world!", sub "/b.log", "UTF-8-RAW")

	fNames := []
	Loop Files, root "/*", "F"
		fNames.Push(A_LoopFileName ":" A_LoopFileExt ":" A_LoopFileSize)
	lines.Push("files_top=" Sort(fNames[1]))

	dNames := []
	Loop Files, root "/*", "D"
		dNames.Push(A_LoopFileName)
	lines.Push("dirs_top=" dNames.Length ":" dNames[1])

	rec := []
	Loop Files, root "/*", "FR"
		rec.Push(A_LoopFileName)
	recStr := ""
	for _, n in rec
		recStr .= (recStr != "" ? "," : "") n
	lines.Push("files_rec=" Sort(recStr, "D,"))
} finally {
	if DirExist(root)
		DirDelete(root, true)
}

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
