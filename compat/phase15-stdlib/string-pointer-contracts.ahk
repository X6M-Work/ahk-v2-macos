#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(ReportFailure)
ReportFailure(err, mode) {
    FileAppend(err.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
Emit(text) => FileAppend(text "`n", "*", "UTF-8-RAW")
text := "été🌍"
address := StrPtr(text)
Emit("read|" StrGet(address))
Emit("stable|" (address = StrPtr(text)))
VarSetStrCapacity(&text, 32)
address := StrPtr(text)
NumPut("UShort", Ord("A"), "UShort", 0, address)
VarSetStrCapacity(&text, -1)
Emit("write|" text)
Emit("stable-write|" (address = StrPtr(text)))
