#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

Emit(line) => FileAppend(line "`n", "*", "UTF-8-RAW")

isWin := InStr(A_Temp, ":") == 2
root := isWin ? SubStr(A_Temp, 1, 3) : "/"
missing := isWin ? (A_Temp "\keysharp-missing-volume-" ProcessExist()) : ("/keysharp-missing-volume-" ProcessExist())

Emit("status_root|" DriveGetStatus(root))
Emit("status_missing|" DriveGetStatus(missing))

dtype := DriveGetType(root)
Emit("type_root_valid|" ((dtype == "Fixed" || dtype == "RAMDisk") ? 1 : 0))
Emit("type_missing|" DriveGetType(missing))

cap := DriveGetCapacity(root)
free := DriveGetSpaceFree(root)
Emit("space_valid|" ((cap > 0 && free >= 0 && free <= cap) ? 1 : 0))

fs := DriveGetFileSystem(root)
Emit("fs_nonempty|" (StrLen(fs) > 0 ? 1 : 0))

serial := DriveGetSerial(root)
Emit("serial_range|" ((serial >= 0 && serial <= 0xFFFFFFFF) ? 1 : 0))

listAll := DriveGetList()
Emit("list_nonempty|" (StrLen(listAll) > 0 ? 1 : 0))
Emit("list_case_match|" (DriveGetList(StrLower(dtype)) == DriveGetList(dtype) ? 1 : 0))

for entry in [
    ["cap_empty", () => DriveGetCapacity("")],
    ["free_empty", () => DriveGetSpaceFree("")],
    ["cap_missing", () => DriveGetCapacity(missing)],
    ["free_missing", () => DriveGetSpaceFree(missing)],
    ["fs_missing", () => DriveGetFileSystem(missing)],
    ["serial_missing", () => DriveGetSerial(missing)],
    ["list_empty", () => DriveGetList("")],
    ["list_bogus", () => DriveGetList("Bogus")],
    ["eject_empty", () => DriveEject("")],
    ["retract_empty", () => DriveRetract("")]
] {
    label := entry[1]
    fn := entry[2]
    try {
        fn()
        Emit(label "|UNEXPECTED")
    } catch as e {
        Emit(label "|" Type(e))
    }
}
