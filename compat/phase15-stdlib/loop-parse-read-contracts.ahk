#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Loop Parse: standard delimiter + omit chars
parsed := ""
Loop Parse, "  one , two , three  ", ",", " "
	parsed .= A_Index ":" A_LoopField "|"
lines.Push("parse_std=" parsed)

; Loop Parse: CSV mode with quoted commas and escaped double quotes
csv := ""
Loop Parse, 'a,"b,c","d""e",f', "CSV"
	csv .= A_Index ":" A_LoopField "|"
lines.Push("parse_csv=" csv)

; Loop Parse: character-by-character (empty delimiter)
chars := ""
Loop Parse, "XYZ"
	chars .= A_Index "=" A_LoopField ","
lines.Push("parse_chr=" chars)

; Loop Read: file with LF and CRLF lines
tmpFile := "ks_loop_read_test.txt"
try {
	if FileExist(tmpFile)
		FileDelete(tmpFile)
	FileAppend("first`r`nsecond`nthird`n", tmpFile, "UTF-8-RAW")
	readOut := ""
	Loop Read, tmpFile
		readOut .= A_Index ":" A_LoopReadLine "|"
	lines.Push("loop_read=" readOut)
} finally {
	if FileExist(tmpFile)
		FileDelete(tmpFile)
}

; VerCompare, StrLower, StrUpper, StrTitle, StrCompare
lines.Push("case=" StrLower("AbC") "|" StrUpper("AbC") "|" StrTitle("hello WORLD"))
lines.Push("strcmp=" (StrCompare("abc", "ABC") = 0 ? 1 : 0) "|" (StrCompare("abc", "ABC", "On") > 0 ? 1 : 0))
lines.Push("ver=" VerCompare("2.0.10", "2.0.2") "|" VerCompare("1.2.3", ">=1.2.0") "|" VerCompare("1.2.3-alpha", "1.2.3"))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
