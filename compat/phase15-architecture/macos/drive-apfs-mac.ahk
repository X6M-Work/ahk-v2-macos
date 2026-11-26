#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

cap := DriveGetCapacity("/")
free := DriveGetSpaceFree("/")
fs := DriveGetFileSystem("/")
dt := DriveGetType("/")
st := DriveGetStatus("/")

ok := (cap > 0) && (free >= 0) && (StrLen(fs) > 0) && (dt == "Fixed") && (st == "Ready")
FileAppend("drive-apfs:" (ok ? "ok" : cap "|" free "|" fs "|" dt "|" st) "`n", "*", "UTF-8-RAW")
ExitApp()
