#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

Emit(line) => FileAppend(line "`n", "*", "UTF-8-RAW")

; Format specifiers and positional reuse
Emit("fmt_int|" Format("{:05d}|{:X}|{:x}", 42, 255, 255))
Emit("fmt_flt|" Format("{:.2f}|{:+.1f}", 3.14159, 2.5))
Emit("fmt_case|" Format("{:U}|{:L}|{:T}", "aBc", "XyZ", "hello world"))
Emit("fmt_pos|" Format("{2}-{1}-{2}|{{ok}}", "A", "B"))

; Math functions
Emit("math_basic|" Abs(-7) "|" Floor(2.9) "|" Floor(-2.1) "|" Ceil(2.1) "|" Ceil(-2.9))
Emit("math_round|" Round(3.14159, 2) "|" Round(125, -1) "|" Round(2.5) "|" Round(-2.5))
Emit("math_mod|" Mod(7, 3) "|" Mod(-7, 3) "|" Format("{:.2f}", Mod(5.5, 2.0)))
Emit("math_minmax|" Min(3, -1, 5, 2) "|" Max(3, -1, 5, 2))
Emit("math_trig|" Format("{:.4f}|{:.4f}|{:.4f}", Sqrt(9), Log(100), Exp(0)))

; Bitwise operators (64-bit)
Emit("bit_ops|" (0xF0 & 0x3C) "|" (0xF0 | 0x0F) "|" (0xFF ^ 0x0F) "|" (~0) "|" (1 << 10) "|" (-16 >> 2))
Emit("bit_ushr|" (-1 >>> 60))

; Type & character classification
Emit("types|" Type(1) "|" Type(1.5) "|" Type("x") "|" IsInteger("42") "|" IsFloat("3.5") "|" IsNumber("1e2") "|" IsNumber("abc"))
Emit("chars|" IsAlnum("Ab1") "|" IsAlpha("Ab") "|" IsDigit("123") "|" IsXDigit("0x1F") "|" IsLower("abc") "|" IsUpper("ABC") "|" IsSpace(" `t`r`n"))

; Ord / Chr including supplementary plane Unicode
smiley := Chr(0x1F600)
Emit("unicode|" Ord("A") "|" Chr(65) "|" Ord(smiley) "|" StrLen(smiley))
