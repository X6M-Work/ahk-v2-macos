#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

cSource := A_ScriptDir "/stack-abi.c"
if !FileExist(cSource)
    throw Error("Missing C fixture source: " cSource)

workDir := A_Temp "/keysharp-stack-abi-" ProcessExist()
DirCreate(workDir)
dylibPath := workDir "/libstack_abi.dylib"
cb := 0
cbLine := ""

SpilledCb(i0, i1, i2, i3, i4, i5, i6, i7, i8, s9, c10, u11) {
    global cbLine
    cbLine := Format("cb_spilled|{}|{}|{}|{}", i8, s9, c10, u11)
    return i0 + i8 * 10 + s9 + c10 + u11
}

try {
    compilerArgs := '-dynamiclib -fPIC -std=c11 -Wall -Wextra -Werror "' cSource '" -o "' dylibPath '"'
    if RunWait("/usr/bin/clang", , "Hide", , compilerArgs) != 0
        throw Error("Could not compile stack-abi.c with /usr/bin/clang.")

    cb := CallbackCreate(SpilledCb, "Fast", [Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int32, Int16, Int8, UInt8, Int64])
    cbRet := 0
    ret := DllCall(dylibPath "\sum_spilled_args",
        "Int", 1, "Int", 2, "Int", 3, "Int", 4, "Int", 5, "Int", 6, "Int", 7, "Int", 8,
        "Int", -9, "Short", -10, "Char", -11, "UChar", 200,
        "Float", 0.25, "Float", 0.5, "Float", 0.75, "Float", 1.0,
        "Float", 1.25, "Float", 1.5, "Float", 1.75, "Float", 2.0,
        "Float", 2.25, "Double", 0.5,
        "Ptr", cb, "Int64*", &cbRet,
        "CDecl Float")

    FileAppend(cbLine "`n", "*", "UTF-8-RAW")
    FileAppend(Format("cb_ret|{}`n", cbRet), "*", "UTF-8-RAW")
    FileAppend(Format("sum_ret|{:.17g}`n", ret), "*", "UTF-8-RAW")
} finally {
    if cb
        CallbackFree(cb)
    DirDelete(workDir, true)
}
ExitApp()
