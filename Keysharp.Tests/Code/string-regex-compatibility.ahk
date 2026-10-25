#NoTrayIcon
#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#Include <assert>

AssertEq(Match20("j", "\j"), 1, A_LineNumber)
Throws(() => Match21("j", "\j"), A_LineNumber, Error)
AssertEq(Match20("j", "\j"), 1, A_LineNumber)

Throws(() => Match21("y", "\y"), A_LineNumber, Error)
AssertEq(Match20("y", "\y"), 1, A_LineNumber)
Throws(() => Match21("y", "\y"), A_LineNumber, Error)

AssertEq(Match21(Chr(2), "\o{2}"), 1, A_LineNumber)
AssertEq(Match20("oo", "\o{2}"), 1, A_LineNumber)
AssertEq(Match21("oo", "\o{2}"), 0, A_LineNumber)

AssertEq(Match20("ajb", "a\jb"), 1, A_LineNumber)
Throws(() => Replace21("ajb", "a\jb", "X"), A_LineNumber, Error)
AssertEq(Replace20("ajb", "a\jb", "X"), "X", A_LineNumber)

AssertEq(Replace20("xjx", "x\jx", "V"), "V", A_LineNumber)
Throws(() => Match21("xjx", "x\jx"), A_LineNumber, Error)
AssertEq(Replace20("xjx", "x\jx", "V"), "V", A_LineNumber)

AssertEq(Replace21(Chr(2), "(?x)\o{2}", "W"), "W", A_LineNumber)
AssertEq(Match20("oo", "(?x)\o{2}"), 1, A_LineNumber)
AssertEq(Replace20("oo", "(?x)\o{2}", "Z"), "Z", A_LineNumber)
AssertEq(Replace21(Chr(2), "(?x)\o{2}", "W"), "W", A_LineNumber)

Match20(InputText, PatternText) {
    #Requires AutoHotkey v2.0
    return RegExMatch(InputText, PatternText)
}
Match21(InputText, PatternText) {
    #Requires AutoHotkey v2.1-alpha.1
    return RegExMatch(InputText, PatternText)
}
Replace20(InputText, PatternText, ReplacementText) {
    #Requires AutoHotkey v2.0
    return RegExReplace(InputText, PatternText, ReplacementText)
}
Replace21(InputText, PatternText, ReplacementText) {
    #Requires AutoHotkey v2.1-alpha.1
    return RegExReplace(InputText, PatternText, ReplacementText)
}

FileAppend "pass", "*"
