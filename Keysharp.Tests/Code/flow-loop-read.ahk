#NoTrayIcon
#ErrorStdOut
#Warn All, StdOut
#Warn LocalSameAsGlobal, Off
#Include <assert>
#Include <testpaths>

x := ""

; MsgBox(A_WorkingDir)

Loop Read _TestFixturePath("test-text-file.txt")
{
	x .= A_LoopReadLine
}

AssertEq(x, "this is line 1another lineline 3", A_LineNumber)

x := ""
try FileDelete _TestFixturePath("test-text-file-out.txt")

Loop Read _TestFixturePath("test-text-file.txt"), _TestFixturePath("test-text-file-out.txt") ; this is a comment
{
	y := Random()
	x .= A_LoopReadLine
	x .= y
	z := A_LoopReadLine
	z .= y
	FileAppend(z)
}

z := ""

Loop Read  _TestFixturePath("test-text-file-out.txt") ; another comment
{
	z.= A_LoopReadLine
}

AssertEq(x, z, A_LineNumber)

; Leaving the loop early closes the file.
Loop Read _TestFixturePath("test-text-file-out.txt")
	break

FileDelete _TestFixturePath("test-text-file-out.txt")

; A missing file raises OSError, unless an Else handles it.
ReadMissing() {
	Loop Read "missing-loop-read-input.txt"
		return
}

Throws(ReadMissing, A_LineNumber, OSError)
x := ""

Loop Read "missing-loop-read-input.txt"
	x := "body"
else
	x := "else"

AssertEq(x, "else", A_LineNumber)

; An output file of * is standard output, which the loop leaves open.
Loop Read _TestFixturePath("test-text-file.txt"), "*"
	FileAppend ""

FileAppend "pass", "*"
