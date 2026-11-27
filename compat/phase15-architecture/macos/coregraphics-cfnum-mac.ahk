#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

; 1. CoreGraphics main display dimensions
cg := "/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics"
disp := DllCall(cg "\CGMainDisplayID", "UInt")
pw := DllCall(cg "\CGDisplayPixelsWide", "UInt", disp, "UPtr")
ph := DllCall(cg "\CGDisplayPixelsHigh", "UInt", disp, "UPtr")
cgOk := (disp != 0) && (pw > 0) && (ph > 0)

; 2. CoreFoundation CFNumberCreate / CFNumberGetValue (kCFNumberSInt64Type = 4)
cf := "/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation"
inVal := 0x123456789ABCDEF
inBuf := Buffer(8, 0)
NumPut("Int64", inVal, inBuf)
cfNum := DllCall(cf "\CFNumberCreate", "Ptr", 0, "Int", 4, "Ptr", inBuf, "Ptr")
outBuf := Buffer(8, 0)
got := DllCall(cf "\CFNumberGetValue", "Ptr", cfNum, "Int", 4, "Ptr", outBuf, "UChar")
outVal := NumGet(outBuf, 0, "Int64")
DllCall(cf "\CFRelease", "Ptr", cfNum)
cfOk := (cfNum != 0) && (got == 1) && (outVal == inVal)

ok := cgOk && cfOk
FileAppend("cg-cfnum:" (ok ? "ok" : disp "|" pw "x" ph "|" got "|" outVal) "`n", "*", "UTF-8-RAW")
ExitApp()
