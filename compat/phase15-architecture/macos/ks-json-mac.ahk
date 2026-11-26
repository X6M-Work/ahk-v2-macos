#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
#Import Ks { Json }
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

src := Map("name", "Keysharp", "nums", [1, 2, 3], "ok", true, "uni", "café")
txt := Json.Encode(src)
parsed := Json.Decode(txt)
ok := (parsed["name"] == "Keysharp") && (parsed["nums"].Length == 3) && (parsed["nums"][2] == 2) && (parsed["uni"] == "café")
FileAppend("ks-json:" (ok ? "ok" : txt) "`n", "*", "UTF-8-RAW")
ExitApp()
