#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

class Calc {
	factor := 3
	Mul(x, y) => (x + y) * this.factor
}
c := Calc()
pName := "factor"
mName := "Mul"
lines.Push("dyn=" c.%pName% "|" c.%mName%(2, 4))

; Higher-order Map / Filter / Reduce
ArrMap(arr, fn) {
	res := []
	for idx, v in arr
		res.Push(fn(v))
	return res
}
ArrReduce(arr, fn, init) {
	acc := init
	for idx, v in arr
		acc := fn(acc, v)
	return acc
}
doubled := ArrMap([1, 2, 3, 4], (x) => x * 2)
sum := ArrReduce(doubled, (a, b) => a + b, 0)
lines.Push("hof=" doubled.Length "|" sum)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
