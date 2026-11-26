#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; Prototype DefineProp, instance override, DeleteProp fallback, getter-only error
proto := {}
proto.DefineProp("val", { Value: 10 })
proto.DefineProp("ro", { Get: (this) => this.val * 3 })

a := { base: proto }
b := { base: proto }
a.val := 20
lines.Push("inh=" a.val "|" b.val "|" a.ro "|" b.ro)
a.DeleteProp("val")
lines.Push("del=" a.val "|" a.ro)

roErr := 0
try {
	a.ro := 5
} catch Error {
	roErr := 1
}
lines.Push("ro_err=" roErr)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
