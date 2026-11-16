#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

cSource := A_ScriptDir "/mixed-abi.c"
if !FileExist(cSource)
    throw Error("Missing C fixture source: " cSource)

workDir := A_Temp "/keysharp-mixed-abi-" ProcessExist()
DirCreate(workDir)
dylibPath := workDir "/libmixed_abi.dylib"
cb := 0
cbLine := ""

MixedCb(x, y, z, w) {
    global cbLine
    cbLine := Format("cb_arg|{}|{:.17g}|{:.17g}|{}", x, y, z, w)
    return (x - 3000000000) * 10 + y + z - w * 0.5
}

try {
    compilerArgs := '-dynamiclib -fPIC -std=c11 -Wall -Wextra -Werror "' cSource '" -o "' dylibPath '"'
    if RunWait("/usr/bin/clang", , "Hide", , compilerArgs) != 0
        throw Error("Could not compile mixed-abi.c with /usr/bin/clang.")

    cb := CallbackCreate(MixedCb, "Fast", [Int64, Float64, Float32, Int32, Float64])
    sum := 0
    prod := 0.0
    ret := DllCall(dylibPath "\mix_and_invoke",
        "Int64", 3000000000,
        "Double", 2.5,
        "Float", 1.25,
        "AStr", "mac",
        "Int", -7,
        "Double", 4.0,
        "Int64*", &sum,
        "Double*", &prod,
        "Ptr", cb,
        "CDecl Double")

    FileAppend(cbLine "`n", "*", "UTF-8-RAW")
    FileAppend(Format("return|{:.17g}`n", ret), "*", "UTF-8-RAW")
    FileAppend(Format("sum|{}`n", sum), "*", "UTF-8-RAW")
    FileAppend(Format("prod|{:.17g}`n", prod), "*", "UTF-8-RAW")
} finally {
    if cb
        CallbackFree(cb)
    DirDelete(workDir, true)
}
ExitApp()
