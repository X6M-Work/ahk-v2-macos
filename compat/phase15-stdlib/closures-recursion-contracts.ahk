#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Recursive function & mutual recursion
Fact(n) => n <= 1 ? 1 : n * Fact(n - 1)
IsEven(n) => n == 0 ? 1 : IsOdd(n - 1)
IsOdd(n) => n == 0 ? 0 : IsEven(n - 1)
lines.Push("rec=" Fact(6) "|" IsEven(8) "|" IsOdd(7) "|" IsEven(5))

; Closures created in a loop via helper factory capture distinct values
MakeAdder(k) => (x) => x + k
adders := []
Loop 4
	adders.Push(MakeAdder(A_Index * 10))
sum := 0
for _, fn in adders
	sum += fn(1)
lines.Push("loop_clos=" sum "|" adders[3](5))

; Closure mutating shared state across two returned closures + Bind with holes
MakeAcc(init) {
	total := init
	add := (a, b := 0) => (total += a + b)
	get := () => total
	return [add, get]
}
acc := MakeAcc(5)
addFn := acc[1], getFn := acc[2]
addTen := addFn.Bind(10)
lines.Push("bind_clos=" addTen(2) "|" addTen() "|" getFn())

; Function object reflection
lines.Push("fn_ref=" IsObject(Fact) "|" (Fact is Func) "|" (addTen is BoundFunc) "|" HasMethod(Fact, "Call") "|" HasMethod(addTen, "Call"))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
