#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

acc := ""
Loop 3 {
	outer := A_Index
	Loop 3 {
		if (outer == 2 && A_Index == 2)
			continue 2
		if (outer == 3 && A_Index == 2)
			break 2
		acc .= outer "." A_Index ","
	}
}
lines.Push("nest=" acc)

zeroHit := 0
Loop 0 {
	zeroHit := 1
} else {
	zeroHit := 2
}

p := ""
Loop Parse, "a,b,c", "," {
	p .= A_Index ":" A_LoopField ";"
}
lines.Push("zero=" zeroHit "|parse=" p)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
