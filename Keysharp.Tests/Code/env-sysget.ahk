#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
#Include <assert>

val := SysGet(80)

Assert(val > 0, A_LineNumber)

val := SysGet(0)

AssertEq(val, A_ScreenWidth, A_LineNumber)

; The screen size is the primary monitor's, and the DPI is an integer, as in AutoHotkey.
MonitorGet(MonitorGetPrimary(), &left, &top, &right, &bottom)
AssertEq(A_ScreenWidth "x" A_ScreenHeight, (right - left) "x" (bottom - top), A_LineNumber)
AssertEq(Type(A_ScreenDPI), "Integer", A_LineNumber)
Assert(A_ScreenDPI >= 72, A_LineNumber)

val := SysGet(43)

Assert(val > 0, A_LineNumber)

val := SysGet(19)

Assert(val > 0, A_LineNumber)

AssertEq(Type(SysGet(76)), "Integer", A_LineNumber)
AssertEq(Type(SysGet(77)), "Integer", A_LineNumber)
Assert(SysGet(78) >= SysGet(0), A_LineNumber)
Assert(SysGet(79) >= SysGet(1), A_LineNumber)
AssertEq(SysGet(81), 1, A_LineNumber)
AssertEq(SysGet(67), 0, A_LineNumber)

FileAppend "pass", "*"
