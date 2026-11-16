#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

Emit(line) => FileAppend(line "`n", "*", "UTF-8-RAW")

norm(text) => StrReplace(StrReplace(text, "`r`n", "`n"), "`n", ";")

for enc in ["UTF-8-RAW", "UTF-16"] {
    iniPath := A_Temp "/ks_ini_compat_" enc "_" ProcessExist() ".ini"
    try FileDelete(iniPath)

    FileAppend("[alpha]`r`n; comment line`r`nkey1=val1`r`n`r`ndq=`"quoted two`"`r`nsq='single three'`r`nsp =  trimmed  `r`nurl=http://x/?a=1&b=2`r`nempty=`r`n[Beta]`r`nx=10`r`n", iniPath, enc)

    Emit(enc "|secs|" norm(IniRead(iniPath)))
    Emit(enc "|sec|" norm(IniRead(iniPath, "ALPHA")))
    Emit(enc "|dq|" IniRead(iniPath, "alpha", "dq"))
    Emit(enc "|sq|" IniRead(iniPath, "alpha", "sq"))
    Emit(enc "|sp|" IniRead(iniPath, "alpha", "sp"))
    Emit(enc "|url|" IniRead(iniPath, "alpha", "url"))
    Emit(enc "|empty|" IniRead(iniPath, "alpha", "empty", "DEF"))
    Emit(enc "|def|" IniRead(iniPath, "alpha", "missing", "DEF"))

    try {
        IniRead(iniPath, "alpha", "missing")
        Emit(enc "|misskey|UNEXPECTED")
    } catch as e {
        Emit(enc "|misskey|" Type(e))
    }

    try {
        IniRead(iniPath, "missingsec")
        Emit(enc "|misssec|UNEXPECTED")
    } catch as e {
        Emit(enc "|misssec|" Type(e))
    }

    IniWrite("updated", iniPath, "alpha", "key1")
    IniWrite("added", iniPath, "Gamma", "g1")
    IniDelete(iniPath, "alpha", "sp")
    IniDelete(iniPath, "Beta")
    Emit(enc "|after_secs|" norm(IniRead(iniPath)))
    Emit(enc "|after_key1|" IniRead(iniPath, "alpha", "key1"))
    Emit(enc "|after_g1|" IniRead(iniPath, "Gamma", "g1"))
    Emit(enc "|after_sp|" IniRead(iniPath, "alpha", "sp", "GONE"))
    FileDelete(iniPath)
}
