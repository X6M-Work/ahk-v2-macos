#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

s := "caf" Chr(0xE9) " " Chr(0x20AC)
u8Bytes := StrPut(s, "UTF-8")
u16Bytes := StrPut(s, "UTF-16")
lines.Push("sizes=" u8Bytes "|" u16Bytes)

b8 := Buffer(u8Bytes, 0)
w8 := StrPut(s, b8, "UTF-8")
lines.Push("u8=" w8 "|" (StrGet(b8, "UTF-8") == s) "|" StrGet(b8, 3, "UTF-8"))

b16 := Buffer(u16Bytes, 0)
w16 := StrPut(s, b16, "UTF-16")
lines.Push("u16=" w16 "|" (StrGet(b16, "UTF-16") == s) "|" StrGet(b16, 4, "UTF-16"))

bLim := Buffer(16, 0x41)
limErr := ""
try StrPut("hello", bLim, 3, "UTF-8")
catch Error
	limErr := "Error"
wExact := StrPut("abc", bLim, 3, "UTF-8")
lines.Push("lim=" limErr "|" wExact "|" StrGet(bLim, 4, "UTF-8"))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
