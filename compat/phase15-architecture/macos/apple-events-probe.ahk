#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

cv1 := ComValue(3, 42)
t1 := ComObjType(cv1)
vt1 := cv1.VarType

valErr := 0
try {
	ComObjValue(cv1)
} catch Error {
	valErr := 1
}

cv2 := ComValue("TEXT", "hello")
t2 := cv2.VarType

badErr := 0
try {
	ComObjActive("com.keysharp.nonexistent.app.999999")
} catch Error {
	badErr := 1
}

ok := (t1 == 3) && (vt1 == 3) && (valErr == 1) && (t2 == "TEXT") && (badErr == 1)
FileAppend("apple-events:" (ok ? "ok" : t1 "|" vt1 "|" valErr "|" t2 "|" badErr) "`n", "*", "UTF-8-RAW")
ExitApp()
