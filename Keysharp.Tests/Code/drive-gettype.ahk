#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
#Include <assert>

#if WINDOWS
root := EnvGet("SystemDrive") "\"
#else
root := "/"
#endif

kind := DriveGetType(root)
Assert(kind == "Fixed" || kind == "RAMDisk", A_LineNumber)

FileAppend "pass", "*"
