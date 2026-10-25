#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))
Compare(left, right) => NumGet(left, 0, "Int") - NumGet(right, 0, "Int")
values := Buffer(12, 0)
NumPut("Int", 9, "Int", 2, "Int", 5, values)
callback := CallbackCreate(Compare, "C", 2)
try {
    DllCall("/usr/lib/libSystem.B.dylib\qsort", "Ptr", values, "UPtr", 3, "UPtr", 4, "Ptr", callback)
    FileAppend("sorted:" NumGet(values, 0, "Int") "," NumGet(values, 4, "Int") "," NumGet(values, 8, "Int") "`n", "*", "UTF-8-RAW")
} finally {
    CallbackFree(callback)
}
ExitApp()
