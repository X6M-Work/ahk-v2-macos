#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
#Include <assert>

#if WINDOWS
	root := EnvGet("SystemDrive") "\"
	val := DriveGetSpaceFree(root)

	Assert(DriveGetSpaceFree(A_WinDir) > 10, A_LineNumber)
	Throws(() => DriveGetSpaceFree(A_Temp "\keysharp-missing-volume-" A_TickCount), A_LineNumber, OSError)
#elif OSX
	root := "/"
	val := DriveGetSpaceFree(root)
#else
	root := "/dev" ; the filesystem holding /dev, which every Linux machine has
	val := DriveGetSpaceFree(root)
#endif

Assert(val > 10, A_LineNumber)
Assert(val <= DriveGetCapacity(root), A_LineNumber)
Throws(() => DriveGetSpaceFree(""), A_LineNumber, ValueError)

FileAppend "pass", "*"
