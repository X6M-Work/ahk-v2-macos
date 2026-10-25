#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(ReportFailure)
ReportFailure(err, mode) {
    FileAppend(err.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
Emit(text) => FileAppend(text "`n", "*", "UTF-8-RAW")

for pattern in ["a\yb", "a\jb", "a\gb", "\x", "\x{2z}", "\u1234", "[\j]", "\k", "\8"] {
    for prefix in ["", "X)"] {
        try Emit(prefix pattern "|" RegExMatch("ayb ajb agb x x{2z} u1234 j k 8", prefix pattern))
        catch as err
            Emit(prefix pattern "|" Type(err))
    }
}
