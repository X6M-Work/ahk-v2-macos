#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
#Include <assert>

#if WINDOWS
root := EnvGet("SystemDrive") "\"
driveLetter := SubStr(root, 1, 2)
val := DriveGetFileSystem(root)

; The file system and label belong to a volume, so only its root names it.
AssertEq(DriveGetFileSystem(driveLetter), val, A_LineNumber)
Throws(() => DriveGetFileSystem(A_WinDir), A_LineNumber, OSError)
Throws(() => DriveGetFileSystem(A_Temp "\keysharp-missing-volume-" A_TickCount), A_LineNumber, OSError)
AssertEq(DriveGetLabel(driveLetter), DriveGetLabel(root), A_LineNumber)
Throws(() => DriveGetLabel(A_WinDir), A_LineNumber, OSError)
Throws(() => DriveSetLabel(A_Temp "\keysharp-missing-volume-" A_TickCount, "x"), A_LineNumber, OSError)
#else
root := "/"
val := DriveGetFileSystem(root)
#endif

Assert(
#if WINDOWS
	val == "NTFS" || val == "FAT32" || val == "FAT" || val == "CDFS" || val == "UDF"
#else
	val != ""
#endif
, A_LineNumber)
Assert(Type(DriveGetLabel(root)) = "String", A_LineNumber)

FileAppend "pass", "*"
