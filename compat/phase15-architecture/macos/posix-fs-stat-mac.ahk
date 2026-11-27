#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

; 1. POSIX open/write/lseek/read/close/unlink via libSystem.B.dylib
; macOS flags: O_RDWR=2, O_CREAT=0x0200, O_TRUNC=0x0400 -> 0x0602
dir := A_Temp "/ks_posix_fs_" A_TickCount
DirCreate(dir)
DirCreate(dir "/sub")
pFile := dir "/fdtest.bin"
fd := DllCall("libSystem.B.dylib\open", "AStr", pFile, "Int", 0x0602, "Int", 0x1A4, "Int")
wBuf := Buffer(8, 0)
StrPut("MacPOSIX", wBuf, 8, "UTF-8")
nw := DllCall("libSystem.B.dylib\write", "Int", fd, "Ptr", wBuf, "UPtr", 8, "Ptr")
pos := DllCall("libSystem.B.dylib\lseek", "Int", fd, "Int64", 0, "Int", 0, "Int64")
rBuf := Buffer(9, 0)
nr := DllCall("libSystem.B.dylib\read", "Int", fd, "Ptr", rBuf, "UPtr", 8, "Ptr")
rcClose := DllCall("libSystem.B.dylib\close", "Int", fd, "Int")
rdText := StrGet(rBuf, 8, "UTF-8")
rcUnlink := DllCall("libSystem.B.dylib\unlink", "AStr", pFile, "Int")
fdOk := (fd >= 0) && (nw == 8) && (pos == 0) && (nr == 8) && (rcClose == 0) && (rdText == "MacPOSIX") && (rcUnlink == 0)

; 2. Recursive Loop Files on APFS
FileAppend("a", dir "/a.txt", "UTF-8-RAW")
FileAppend("b", dir "/sub/b.txt", "UTF-8-RAW")
cnt := 0
Loop Files, dir "/*.txt", "R"
    cnt++
DirDelete(dir, 1)
loopOk := (cnt == 2)

ok := fdOk && loopOk
FileAppend("posix-fs:" (ok ? "ok" : fdOk "|" rdText "|" cnt) "`n", "*", "UTF-8-RAW")
ExitApp()
