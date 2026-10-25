#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#Include <assert>

LegacyMap() {
    #Requires AutoHotkey v2.0
    return Map(1.0, "float", 1, "integer")
}
ModernMap() {
    #Requires AutoHotkey v2.1-alpha
    return Map(1.0, "float", 1, "integer")
}
CheckLegacyCaller(items, stringKey) {
    #Requires AutoHotkey v2.0
    AssertEq(items[1.0], "float", A_LineNumber)
    AssertEq(items.Get(1.0), "float", A_LineNumber)
    AssertEq(items.Has(1.0), 1, A_LineNumber)
    AssertEq(items.Has("1.0"), stringKey, A_LineNumber)
    AssertEq(items[1], "integer", A_LineNumber)
    AssertEq(items.Clone()[1.0], "float", A_LineNumber)
}
CheckModernCaller(items, stringKey) {
    #Requires AutoHotkey v2.1-alpha
    AssertEq(items[1.0], "float", A_LineNumber)
    AssertEq(items.Get(1.0), "float", A_LineNumber)
    AssertEq(items.Has(1.0), 1, A_LineNumber)
    AssertEq(items.Has("1.0"), stringKey, A_LineNumber)
    AssertEq(items[1], "integer", A_LineNumber)
    AssertEq(items.Clone()[1.0], "float", A_LineNumber)
    AssertEq(items.Delete(1.0), "float", A_LineNumber)
    items[1.0] := "float"
}
legacy := LegacyMap()
modern := ModernMap()
CheckLegacyCaller(legacy, 1)
CheckModernCaller(legacy, 1)
CheckLegacyCaller(modern, 0)
CheckModernCaller(modern, 0)
FileAppend "pass", "*"
