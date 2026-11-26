#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; 64-bit bitwise operations
lines.Push("bit=" (~0) "|" (~1) "|" (0xF0 & 0x3C) "|" (0xF0 | 0x0F) "|" (0xFF ^ 0xAA))
lines.Push("bit64=" (1 << 40) "|" ((1 << 40) >> 38) "|" (-1 >>> 56))

; Numeric string classification & coercion
lines.Push("is_hex=" IsInteger("0x1A") "|" IsInteger("-0x10") "|" IsNumber("0x1A") "|" IsFloat("0x1A"))
lines.Push("is_sci=" IsFloat("1.5e2") "|" IsNumber("1.5e2") "|" IsFloat("-3.5e-2"))
lines.Push("coerce=" Integer("0x1A") "|" Format("{:.2f}", Float("-3.5e2")))

; Format unsigned 64-bit & hex
lines.Push("fmt_u=" Format("{:u}|{:X}", 0xFFFFFFFF, 0xCAFEBABE))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
