#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

cv1 := ComValue(3, 42)
t1 := ComObjType(cv1)
v1 := ComObjValue(cv1)

cv2 := ComValue("TEXT", "hello")
t2 := cv2.VarType
v2 := cv2[]

badErr := 0
try {
	ComObjActive("com.keysharp.nonexistent.app.999999")
} catch Error {
	badErr := 1
}

ok := (t1 == 3) && (v1 == 42) && (t2 == "TEXT") && (v2 == "hello") && (badErr == 1)
FileAppend("apple-events:" (ok ? "ok" : t1 "|" v1 "|" t2 "|" v2 "|" badErr) "`n", "*", "UTF-8-RAW")
ExitApp()
