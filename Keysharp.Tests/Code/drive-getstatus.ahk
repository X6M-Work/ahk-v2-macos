#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
#Include <assert>

#if WINDOWS
root := EnvGet("SystemDrive") "\"
#else
root := "/"
#endif

AssertEq(DriveGetStatus(root), "Ready", A_LineNumber)

FileAppend "pass", "*"
