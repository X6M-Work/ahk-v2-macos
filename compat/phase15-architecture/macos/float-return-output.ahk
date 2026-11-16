#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

cSource := A_ScriptDir "/parse-float.c"
if !FileExist(cSource)
    throw Error("Missing C fixture source: " cSource)

workDir := A_Temp "/keysharp-float-output-" ProcessExist()
DirCreate(workDir)
dylibPath := workDir "/libparse_float.dylib"

try {
    compilerArgs := '-dynamiclib -fPIC -std=c11 -Wall -Wextra -Werror "' cSource '" -o "' dylibPath '"'
    if RunWait("/usr/bin/clang", , "Hide", , compilerArgs) != 0
        throw Error("Could not compile parse-float.c with /usr/bin/clang.")

    value := DllCall("/usr/lib/libSystem.B.dylib\sqrtf", "Float", 2.0, "CDecl Float")
    FileAppend(Format("return|{:.17g}`n", value), "*", "UTF-8-RAW")

    output := 0.0
    count := DllCall(dylibPath "\parse_float", "AStr", "1.2345", "Float*", &output, "CDecl Int")
    FileAppend(Format("output|{}|{:.17g}`n", count, output), "*", "UTF-8-RAW")
} finally {
    DirDelete(workDir, true)
}
ExitApp()
