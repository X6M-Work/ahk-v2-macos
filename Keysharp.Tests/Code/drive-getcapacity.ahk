#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
#Include <assert>

#if WINDOWS
root := EnvGet("SystemDrive") "\"
#else
root := "/"
#endif

capacity := DriveGetCapacity(root)
Assert(capacity > 0, A_LineNumber)
Assert(DriveGetSpaceFree(root) <= capacity, A_LineNumber)

FileAppend "pass", "*"
