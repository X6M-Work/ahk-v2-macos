#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Buffer creation, fillByte, resize, and Ptr
buf := Buffer(40, 0x5A)
lines.Push("buf_init=" buf.Size "|" (buf.Ptr != 0 ? 1 : 0) "|" NumGet(buf, 0, "UChar") "|" NumGet(buf, 39, "UChar"))
buf.Size := 64
lines.Push("buf_grow=" buf.Size "|" NumGet(buf, 0, "UChar"))
buf.Size := 40
lines.Push("buf_shrink=" buf.Size)

; Chained NumPut and exact-offset NumGet
endPtr := NumPut(
	"Char", -12,
	"UChar", 250,
	"Short", -1234,
	"UShort", 54321,
	"Int", -100000,
	"UInt", 3000000000,
	"Int64", -9000000000000,
	"Float", 1.5,
	"Double", 3.25,
	buf
)
lines.Push("numput_len=" (endPtr - buf.Ptr))
lines.Push("numget_i="
	. NumGet(buf, 0, "Char") "|"
	. NumGet(buf, 1, "UChar") "|"
	. NumGet(buf, 2, "Short") "|"
	. NumGet(buf, 4, "UShort") "|"
	. NumGet(buf, 6, "Int") "|"
	. NumGet(buf, 10, "UInt") "|"
	. NumGet(buf, 14, "Int64"))
lines.Push("numget_f=" Format("{:.2f}|{:.2f}", NumGet(buf, 22, "Float"), NumGet(buf, 26, "Double")))

; StrPut / StrGet UTF-8 and UTF-16 with Unicode
sample := "héllo 日本"
u8Bytes := StrPut(sample, "UTF-8")
u8Buf := Buffer(u8Bytes, 0)
written8 := StrPut(sample, u8Buf, "UTF-8")
lines.Push("u8=" u8Bytes "|" written8 "|" StrGet(u8Buf, "UTF-8"))

u16Bytes := StrPut(sample, "UTF-16")
u16Buf := Buffer(u16Bytes, 0)
written16 := StrPut(sample, u16Buf, "UTF-16")
lines.Push("u16=" u16Bytes "|" written16 "|" StrGet(u16Buf, "UTF-16"))

; VarSetStrCapacity
s := "abc"
cap := VarSetStrCapacity(&s, 64)
lines.Push("cap=" (cap >= 64 ? 1 : 0) "|" (VarSetStrCapacity(&s) >= 64 ? 1 : 0))
vsscErr := ""
try VarSetStrCapacity(&s, 0x7FFFFFFF0)
catch Any as e
	vsscErr := Type(e)
cbaErr := ""
try ClipboardAll(Buffer(4), -1)
catch Any as e
	cbaErr := Type(e)
lines.Push("mem_err=" vsscErr "|" cbaErr)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
