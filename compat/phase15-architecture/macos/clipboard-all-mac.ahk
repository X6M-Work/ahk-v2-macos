#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

saved := ClipboardAll()
try {
	A_Clipboard := "ks_mac_clip_é_42"
	got := A_Clipboard
} finally {
	A_Clipboard := saved
}

ok := (got == "ks_mac_clip_é_42")
FileAppend("clipboard-all:" (ok ? "ok" : got) "`n", "*", "UTF-8-RAW")
ExitApp()
