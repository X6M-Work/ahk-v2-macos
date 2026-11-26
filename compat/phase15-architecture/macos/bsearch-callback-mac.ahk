#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

; Native libSystem.B.dylib bsearch with CallbackCreate comparator
CmpInt(aPtr, bPtr) {
	a := NumGet(aPtr, 0, "Int")
	b := NumGet(bPtr, 0, "Int")
	return a < b ? -1 : a > b ? 1 : 0
}

arr := Buffer(20, 0)
NumPut("Int", 10, "Int", 20, "Int", 30, "Int", 40, "Int", 50, arr)
key := Buffer(4, 0)
NumPut("Int", 40, key)

cb := CallbackCreate(CmpInt, "F", 2)
try {
	foundPtr := DllCall("/usr/lib/libSystem.B.dylib\bsearch", "Ptr", key, "Ptr", arr, "UPtr", 5, "UPtr", 4, "Ptr", cb, "Ptr")
	foundVal := foundPtr ? NumGet(foundPtr, 0, "Int") : 0
	foundIdx := foundPtr ? ((foundPtr - arr.Ptr) // 4) : -1
} finally {
	CallbackFree(cb)
}

ok := (foundVal == 40) && (foundIdx == 3)
FileAppend("bsearch-cb:" (ok ? "ok" : foundVal "|" foundIdx) "`n", "*", "UTF-8-RAW")
ExitApp()
