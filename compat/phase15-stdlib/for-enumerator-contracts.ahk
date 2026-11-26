#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Custom __Enum supporting both 1-var and 2-var for-loops
class RangeObj {
	__New(start, stop) {
		this.start := start
		this.stop := stop
	}
	__Enum(nVars) {
		cur := this.start
		stop := this.stop
		idx := 0
		Enum1(&v) {
			if (cur > stop)
				return false
			v := cur
			cur += 1
			return true
		}
		Enum2(&k, &v) {
			if (cur > stop)
				return false
			idx += 1
			k := idx
			v := cur
			cur += 1
			return true
		}
		return nVars == 1 ? Enum1 : Enum2
	}
}

r1 := ""
for val in RangeObj(5, 8)
	r1 .= val ","
lines.Push("enum1=" r1)

r2 := ""
for i, val in RangeObj(10, 12)
	r2 .= i ":" val ","
lines.Push("enum2=" r2)

; For ... Else when empty vs non-empty
emptyHit := "no"
for val in RangeObj(5, 3)
	emptyHit := "body"
else
	emptyHit := "else"
lines.Push("enum_empty=" emptyHit)

nonEmptyHit := "no"
for val in RangeObj(1, 2) {
	nonEmptyHit := "body"
	break
} else {
	nonEmptyHit := "else"
}
lines.Push("enum_brk=" nonEmptyHit)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
