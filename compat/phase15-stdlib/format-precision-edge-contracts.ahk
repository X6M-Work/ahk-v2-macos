#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

lines.Push("z0=" Format("{:.0d}|{:#.0o}|{:#.0x}|{:+04.0d}|{:5.0d}|{:.0u}", 0, 0, 0, 0, 0, 0))
lines.Push("pz=" Format("{:06.3d}|{:06.3x}|{:06.3o}|{:06.3u}", 42, 42, 42, 42))
lines.Push("np=" Format("{:.4d}|{:06.4d}", -42, -42))
lines.Push("min=" Format("{:d}|{:i}", -9223372036854775808, -9223372036854775808))
lines.Push("galt=" Format("{:#g}|{:#.4g}|{:#.4G}|{:#.4g}|{:#.4g}", 5.0, 5.0, 12.0, 0.0012, 0.0))
lines.Push("ver=" VerCompare("1.0+build1", "1.0+build2") "|" VerCompare("1.0+b1", "=1.0+b2") "|" VerCompare("1.0-alpha+1", "1.0-alpha+2"))
lines.Push("mix=" Format("{2} {} {1} {}", "a", "b", "c"))
bInf := Buffer(8, 0)
NumPut("Int64", 0x7FF0000000000000, bInf), pInf := NumGet(bInf, 0, "Double")
NumPut("Int64", 0xFFF0000000000000, bInf), nInf := NumGet(bInf, 0, "Double")
NumPut("Int64", 0x7FF8000000000000, bInf), qNan := NumGet(bInf, 0, "Double")
lines.Push("nonfin=" Format("{:f}|{:f}|{:f}|{:G}|{:G}|{:G}|{:06f}|{:06f}|{:+f}", pInf, nInf, qNan, pInf, nInf, qNan, pInf, nInf, qNan))
lines.Push("fdef=" Format("{:f}|{:f}|{:+f}", 3.5, -0.0, -0.0))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
