#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
#Include <assert>

FileEncoding("utf-8")
fe := A_FileEncoding

AssertEq(fe, "UTF-8", A_LineNumber)

FileEncoding("utf-8-raw")
fe := A_FileEncoding

AssertEq(fe, "UTF-8-RAW", A_LineNumber)

FileEncoding("utf-16")
fe := A_FileEncoding

AssertEq(fe, "UTF-16", A_LineNumber)

FileEncoding("unicode")
fe := A_FileEncoding

AssertEq(fe, "UTF-16", A_LineNumber)

FileEncoding("utf-16-raw")
fe := A_FileEncoding

AssertEq(fe, "UTF-16-RAW", A_LineNumber)

FileEncoding("ascii")
fe := A_FileEncoding

AssertEq(fe, "CP20127", A_LineNumber)

FileEncoding("us-ascii")
fe := A_FileEncoding

AssertEq(fe, "CP20127", A_LineNumber)

; An encoding name which cannot be resolved is an error, so a typo can never quietly read a file as
; something else. The setting is left as it was.
threw := 0

try
	FileEncoding("no-such-encoding")
catch ValueError
	threw++

try
	FileEncoding("cp999999")
catch ValueError
	threw++

try
	FileRead(A_ScriptFullPath, "no-such-encoding")
catch ValueError
	threw++

Assert(threw == 3 && A_FileEncoding == "CP20127", A_LineNumber)

FileAppend "pass", "*"
