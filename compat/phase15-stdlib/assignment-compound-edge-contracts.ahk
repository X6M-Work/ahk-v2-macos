#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Prefix/postfix ++/-- and chained assignment
a := b := c := 5
p1 := ++a
p2 := b++
p3 := --c
lines.Push("inc=" p1 "|" a "|" p2 "|" b "|" p3 "|" c)

; Compound assignments on local, object prop, array elem, map elem
x := 20
x += 5
x -= 3
x *= 2
x //= 5
x &= 0xFF
x |= 0x10
x ^= 0x03
x <<= 1
x >>= 1
lines.Push("comp_v=" x)

o := { n: 10 }
o.n += 7
arr := [4, 5]
arr[1] *= 3
m := Map("s", "hi")
m["s"] .= "!"
lines.Push("comp_c=" o.n "|" arr[1] "|" m["s"])

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
