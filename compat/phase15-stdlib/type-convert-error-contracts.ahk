#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

lines.Push("int=" Integer("42") "|" Integer("-7") "|" Integer("0x1A") "|" Integer(3.9) "|" Integer(-3.9))
lines.Push("flt=" Float("3.5") "|" Float("-0.25") "|" Float("1e2") "|" Float(7))
lines.Push("num=" Type(Number("42")) "|" Type(Number("3.5")) "|" Type(Number("0x10")) "|" Number("  -5  "))
lines.Push("str=" String(42) "|" String(-3.5) "|" String(""))

errs := ""
for fn in [Integer, Float, Number] {
	try fn("not_a_num")
	catch TypeError
		errs .= "T|"
	catch ValueError
		errs .= "V|"
	catch Error
		errs .= "E|"
}
lines.Push("errs=" errs)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
