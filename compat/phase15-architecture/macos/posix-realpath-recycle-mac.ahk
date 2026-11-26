#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

; 1. mach_absolute_time monotonic counter
t1 := DllCall("libSystem.B.dylib\mach_absolute_time", "UInt64")
t2 := DllCall("libSystem.B.dylib\mach_absolute_time", "UInt64")
machOk := (t1 > 0) && (t2 >= t1)

; 2. POSIX realpath("/tmp") -> "/private/tmp" on macOS
buf := Buffer(1024, 0)
p := DllCall("libSystem.B.dylib\realpath", "AStr", "/tmp", "Ptr", buf, "Ptr")
rp := p ? StrGet(p, "UTF-8") : ""
rpOk := (rp == "/private/tmp")

; 3. FileRecycle via NSFileManager.TrashItem
tmpFile := A_Temp "/ks_mac_recycle_" A_TickCount ".tmp"
FileAppend("trash-me", tmpFile, "UTF-8-RAW")
existed := FileExist(tmpFile) != ""
FileRecycle(tmpFile)
gone := FileExist(tmpFile) == ""
recOk := existed && gone

ok := machOk && rpOk && recOk
FileAppend("posix-recycle:" (ok ? "ok" : machOk "|" rp "|" recOk) "`n", "*", "UTF-8-RAW")
ExitApp()
