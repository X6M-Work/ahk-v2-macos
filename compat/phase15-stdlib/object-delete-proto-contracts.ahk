#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; DeleteProp returns removed value; OwnProps skips inherited properties
baseObj := { inherited: 100 }
child := { base: baseObj, own1: 10, own2: 20 }
removed := child.DeleteProp("own1")
ownKeys := ""
for k, v in child.OwnProps()
	ownKeys .= k "=" v ","
lines.Push("del_own=" removed "|" ownKeys "|" child.inherited)

; Built-in Prototype reflection
lines.Push("proto=" HasMethod([], "Push") "|" HasMethod(Map(), "Set") "|" HasProp([], "Length") "|" HasProp(Map(), "Count"))

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
