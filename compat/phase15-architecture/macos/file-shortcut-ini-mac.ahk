#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

dir := A_Temp "/ks_mac_sc_ini_" A_TickCount
DirCreate(dir)
target := dir "/hello.txt"
FileAppend("mac-shortcut", target, "UTF-8-RAW")

; 1. Symlink shortcut roundtrip
sym := dir "/hello.link"
FileCreateShortcut(target, sym)
FileGetShortcut(sym, &sTgt, &sDir)
symOk := (InStr(sTgt, "hello.txt") > 0) && (StrLen(sDir) > 0)

; 2. .desktop launcher shortcut roundtrip (args + workingDir + description)
desk := dir "/app.desktop"
FileCreateShortcut(target, desk, dir, "--flag 42", "MacDesc")
FileGetShortcut(desk, &dTgt, &dDir, &dArgs, &dDesc)
deskOk := (InStr(dTgt, "hello.txt") > 0) && (dDir == dir) && (dArgs == "--flag 42") && (dDesc == "MacDesc")

; 3. INI roundtrip on macOS
ini := dir "/cfg.ini"
IniWrite("alpha", ini, "Sec1", "k1")
IniWrite("beta", ini, "Sec1", "k2")
r1 := IniRead(ini, "Sec1", "k1")
IniDelete(ini, "Sec1", "k2")
r2 := IniRead(ini, "Sec1", "k2", "GONE")
iniOk := (r1 == "alpha") && (r2 == "GONE")

DirDelete(dir, 1)
ok := symOk && deskOk && iniOk
FileAppend("shortcut-ini:" (ok ? "ok" : symOk "|" deskOk "|" iniOk "|" sTgt "|" dArgs "|" r1 "|" r2) "`n", "*", "UTF-8-RAW")
ExitApp()
