#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

cf := "/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation"
kCFStringEncodingUTF8 := 0x08000100
cfStr := DllCall(cf "\CFStringCreateWithCString", "Ptr", 0, "AStr", "KeysharpMac", "UInt", kCFStringEncodingUTF8, "Ptr")
len := DllCall(cf "\CFStringGetLength", "Ptr", cfStr, "Ptr")
buf := Buffer(64, 0)
got := DllCall(cf "\CFStringGetCString", "Ptr", cfStr, "Ptr", buf, "Ptr", 64, "UInt", kCFStringEncodingUTF8, "UChar")
DllCall(cf "\CFRelease", "Ptr", cfStr)
s := StrGet(buf, "UTF-8")

ok := (cfStr != 0) && (len == 11) && (got != 0) && (s == "KeysharpMac")
FileAppend("cf-string:" (ok ? "ok" : (cfStr != 0) "|" len "|" got "|" s) "`n", "*", "UTF-8-RAW")
ExitApp()
