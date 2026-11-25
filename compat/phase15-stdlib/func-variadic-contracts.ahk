#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Optional params, unset, ?? operator, and Func metadata
OptFn(a, b := 10, c?) {
	return a "|" b "|" (IsSet(c) ? c : "unset") "|" (c ?? 99)
}
lines.Push("opt=" OptFn(1) "/" OptFn(1, 2) "/" OptFn(1, , 3))
lines.Push("meta=" OptFn.Name "|" OptFn.MinParams "|" OptFn.MaxParams "|" OptFn.IsVariadic "|" OptFn.IsBuiltIn)

; Variadic function and variadic call
SumAll(head, rest*) {
	total := head
	for idx, v in rest
		total += v
	return total "|" rest.Length
}
vals := [2, 3, 4, 5]
lines.Push("var=" SumAll(1, vals*) "|" SumAll.MinParams "|" SumAll.IsVariadic)

; ByRef + IsSetRef
SwapAndInit(&x, &y, &outVal) {
	hadOut := IsSetRef(&outVal)
	t := x
	x := y
	y := t
	outVal := x + y
	return hadOut ? 1 : 0
}
p := 7, q := 13
had := SwapAndInit(&p, &q, &res)
lines.Push("byref=" had "|" p "|" q "|" res)

; Nested closures mutating captured outer variable
MakeCounter(start) {
	n := start
	inc := (step := 1) => (n += step)
	peek := () => n
	return [inc, peek]
}
ctr := MakeCounter(10)
incFn := ctr[1], peekFn := ctr[2]
lines.Push("closure=" incFn() "|" incFn(5) "|" peekFn())

; Chained BoundFunc
Fmt3(a, b, c) => a "-" b "-" c
b1 := Fmt3.Bind("X")
b2 := b1.Bind("Y")
lines.Push("bind=" b2("Z") "|" Fmt3.Bind(, "M")("L", "R"))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
