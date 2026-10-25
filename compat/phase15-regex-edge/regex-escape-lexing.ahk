#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(FatalError)
FatalError(UnhandledError, ErrorMode) {
    FileAppend(UnhandledError.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
for Entry in [
    ["unknown-o", "oo", "\o{2}"],
    ["strict-o", "oo", "X)\o{2}"],
    ["quoted", "\j", "\Q\j\E"],
    ["comment", "j", "(?#\Q)\j"],
    ["extended", "j", "x)#\Q`n\j"],
    ["inline-extended", "j", "(?x)#\Q`n\j"],
    ["scoped-extended", "j", "(?x:#\Q`n\j)"],
    ["inline-disable", "#j", "x)(?-x)#\j"],
    ["initial-bracket", "]", "x)[]#\j]"],
    ["posix-class", "j", "x)[[:alpha:]#\j]"],
    ["quoted-class", "j", "[\Q\j\E]"],
    ["scoped-o", "oo", "(?x:\o{2})"],
    ["scoped-o-strict", "oo", "X)(?x:\o{2})"],
    ["quoted-o", "\o{2}", "\Q\o{2}\E"],
    ["comment-o", "oo", "(?x)#\o{2}`n\o{2}"],
    ["mixed-unknowns", "joy", "(?x)\j\o\y"],
    ["inline-hex", "x", "(?x)\x"],
    ["scoped-hex-braces", "x{2z}", "(?x:\x{2z})"],
    ["quoted-hex", "\x{2z}", "\Q\x{2z}\E"],
    ["class-hex", "z", "[\x{2z}]"],
    ["hex-empty-braces", "x{}", "(?x)\x{}"],
    ["hex-incomplete", "x{12", "(?x)\x{12"],
    ["unsupported-u", "u1234", "(?x)\u1234"],
    ["reserved-g", "g", "(?x)\g"],
    ["reserved-k", "k", "(?x)\k"],
    ["unknown-F", "F", "(?x)\F"],
    ["strict-F", "F", "X)(?x)\F"],
    ["escaped-o", "\o", "(?x)\\o"]
] {
    try FileAppend(Entry[1] ":" RegExMatch(Entry[2], Entry[3]) "`n", "*", "UTF-8-RAW")
    catch as Failure
        FileAppend(Entry[1] ":" Type(Failure) "`n", "*", "UTF-8-RAW")
}
