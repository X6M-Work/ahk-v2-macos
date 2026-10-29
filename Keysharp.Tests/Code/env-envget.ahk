#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
#Include <assert>

x := EnvGet("PATH")

Assert(x != "", A_LineNumber) 

dummy := "KEYSHARP_ENVGET_" ProcessExist() "_" A_TickCount
x := EnvGet(dummy)

AssertEq(x, "", A_LineNumber)

FileAppend "pass", "*"
