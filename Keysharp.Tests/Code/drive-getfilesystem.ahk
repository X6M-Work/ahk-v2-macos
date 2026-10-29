#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
#Include <assert>

#if WINDOWS
root := EnvGet("SystemDrive") "\"
#else
root := "/"
#endif

Assert(StrLen(DriveGetFileSystem(root)) > 0, A_LineNumber)
Assert(Type(DriveGetLabel(root)) = "String", A_LineNumber)

FileAppend "pass", "*"
