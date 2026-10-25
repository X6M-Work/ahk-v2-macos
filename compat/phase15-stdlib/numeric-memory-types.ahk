#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(ReportFailure)
ReportFailure(err, mode) {
    FileAppend(err.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
Emit(text) => FileAppend(text "`n", "*", "UTF-8-RAW")

for tag in ["i", "Int16", "UChar", "Str", "P", "F", "D", "z", ""] {
    buf := Buffer(16, 0)
    try {
        width := NumPut(tag, 1, buf) - buf.Ptr
        Emit(tag "|" width "|" NumGet(buf, tag))
    } catch as err
        Emit(tag "|" Type(err))
}
for value in ["bad", "", "2.5", 2.5] {
    buf := Buffer(8, 255)
    try {
        NumPut("Int", value, buf)
        Emit("value|" Type(value) "|" NumGet(buf, "Int"))
    } catch as err
        Emit("value|" Type(value) "|" Type(err))
}
buf := Buffer(4)
NumPut("Float", 1.2345, buf)
Emit(Format("float|{:.17g}", NumGet(buf, "Float")))
