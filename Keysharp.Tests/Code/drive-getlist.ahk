#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
#Include <assert>

#if WINDOWS
root := EnvGet("SystemDrive") "\"
#else
root := "/"
#endif

allDrives := DriveGetList()
kind := DriveGetType(root)
matching := DriveGetList(kind)
#if WINDOWS
Assert(InStr(allDrives, SubStr(root, 1, 1)), A_LineNumber)
Assert(InStr(matching, SubStr(root, 1, 1)), A_LineNumber)
AssertEq(DriveGetList(StrLower(kind)), matching, A_LineNumber)
#else
foundAll := false
foundMatching := false
for item in StrSplit(allDrives, ";")
    if item = root
        foundAll := true
for item in StrSplit(matching, ";")
    if item = root
        foundMatching := true
Assert(foundAll && foundMatching, A_LineNumber)
#endif

FileAppend "pass", "*"
