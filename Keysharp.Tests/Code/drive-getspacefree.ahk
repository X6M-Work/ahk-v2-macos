#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
#Include <assert>

#if WINDOWS
root := EnvGet("SystemDrive") "\"
#else
root := "/"
#endif

free := DriveGetSpaceFree(root)
Assert(free >= 0, A_LineNumber)
Assert(free <= DriveGetCapacity(root), A_LineNumber)

FileAppend "pass", "*"
