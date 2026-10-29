#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
#Include <assert>

#if WINDOWS
root := EnvGet("SystemDrive") "\"
#else
root := "/"
#endif

serial := DriveGetSerial(root)
Assert(serial >= 0, A_LineNumber)
#if WINDOWS
AssertEq(DriveGetSerial(RTrim(root, "\")), serial, A_LineNumber)
Throws(() => DriveGetSerial(A_Temp "\keysharp-missing-volume-" ProcessExist() "-" A_TickCount), A_LineNumber, OSError)
#endif

FileAppend "pass", "*"
