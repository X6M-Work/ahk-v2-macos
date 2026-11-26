#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

; Native libSystem.B.dylib strtol, memcpy, and memcmp via DllCall
val := DllCall("/usr/lib/libSystem.B.dylib\strtol", "AStr", "0x2A", "Ptr", 0, "Int", 0, "Ptr")
src := Buffer(8, 0)
dst := Buffer(8, 0)
NumPut("Int", 12345, "Int", -6789, src)
DllCall("/usr/lib/libSystem.B.dylib\memcpy", "Ptr", dst, "Ptr", src, "UPtr", 8, "Ptr")
cmp := DllCall("/usr/lib/libSystem.B.dylib\memcmp", "Ptr", dst, "Ptr", src, "UPtr", 8, "Int")
a := NumGet(dst, 0, "Int")
b := NumGet(dst, 4, "Int")

ok := (val == 42) && (cmp == 0) && (a == 12345) && (b == -6789)
FileAppend("libc-mem-strtol:" (ok ? "ok" : val "|" cmp "|" a "|" b) "`n", "*", "UTF-8-RAW")
ExitApp()
