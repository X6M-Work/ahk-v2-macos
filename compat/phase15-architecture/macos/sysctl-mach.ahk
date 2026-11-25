#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

ncpu := 0
sz := 4
rc := DllCall("/usr/lib/libSystem.B.dylib\sysctlbyname", "AStr", "hw.ncpu", "Int*", &ncpu, "UPtr*", &sz, "Ptr", 0, "UPtr", 0, "Int")
t1 := DllCall("/usr/lib/libSystem.B.dylib\mach_absolute_time", "UInt64")
t2 := DllCall("/usr/lib/libSystem.B.dylib\mach_absolute_time", "UInt64")
ok := (rc == 0) && (ncpu >= 1) && (t1 > 0) && (t2 >= t1)
FileAppend("sysctl-mach:" (ok ? "ok" : rc "|" ncpu "|" t1 "|" t2) "`n", "*", "UTF-8-RAW")
ExitApp()
