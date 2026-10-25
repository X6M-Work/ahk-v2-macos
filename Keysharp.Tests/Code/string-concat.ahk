#NoTrayIcon
#Include <assert>

x := "this is a string"
y := " and another string"
z := x . y

Assert(z = "this is a string and another string", A_LineNumber)

x := 123
y := 456
z := x . y

Assert(z = "123456", A_LineNumber)

z := ""
z := x y

Assert(z = "123456", A_LineNumber)

z := "The number is " . (x * 10)

Assert(z = "The number is 1230", A_LineNumber)

z := "The number is"
. " another line"

Assert(z = "The number is another line", A_LineNumber)

a .= "hello"

Assert(a = "hello", A_LineNumber)

CheckObjectConcatenation21() {
	#Requires AutoHotkey v2.1-alpha.1
	objectText := {ToString: (this) => "named"}
	AssertEq("a" . objectText . "b", "anamedb", A_LineNumber)
	objectText := [1, 2]
	AssertEq("a" . objectText, "a" String(objectText), A_LineNumber)
	objectText := {}
	Throws(() => "a" . objectText, A_LineNumber, TypeError)
	Throws(() => objectText . "a", A_LineNumber, TypeError)
}
CheckObjectConcatenation21()

FileAppend "pass", "*"
