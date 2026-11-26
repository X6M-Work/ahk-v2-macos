#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

objc := "/usr/lib/libobjc.dylib"
cls := DllCall(objc "\objc_getClass", "AStr", "NSString", "Ptr")
selNew := DllCall(objc "\sel_registerName", "AStr", "stringWithUTF8String:", "Ptr")
selLen := DllCall(objc "\sel_registerName", "AStr", "length", "Ptr")
selUtf8 := DllCall(objc "\sel_registerName", "AStr", "UTF8String", "Ptr")

nsStr := DllCall(objc "\objc_msgSend", "Ptr", cls, "Ptr", selNew, "AStr", "HelloObjC", "Ptr")
nLen := DllCall(objc "\objc_msgSend", "Ptr", nsStr, "Ptr", selLen, "Ptr")
cPtr := DllCall(objc "\objc_msgSend", "Ptr", nsStr, "Ptr", selUtf8, "Ptr")
text := StrGet(cPtr, "UTF-8")

ok := (cls != 0) && (nsStr != 0) && (nLen == 9) && (text == "HelloObjC")
FileAppend("objc-nsstring:" (ok ? "ok" : (cls != 0) "|" (nsStr != 0) "|" nLen "|" text) "`n", "*", "UTF-8-RAW")
ExitApp()
