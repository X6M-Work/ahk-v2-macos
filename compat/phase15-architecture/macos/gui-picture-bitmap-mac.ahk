#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#Warn Experimental, Off
#NoTrayIcon
#Import Ks { Image }
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

tmp := A_Temp "/ks_pic_probe_" A_TickCount "_" Random(1000, 9999) ".png"
ok := false
detail := ""
try {
	img := Image.Create(32, 24)
	img.FillRect(0, 0, 32, 24, "Navy")
	img.Save(tmp)
	g := Gui()
	pic := g.Add("Picture", "", tmp)
	pic.GetPos(&px, &py, &pw, &ph)
	g.Destroy()
	ok := (pw >= 32) && (ph >= 24)
	detail := pw "|" ph
} finally {
	try FileDelete(tmp)
}
FileAppend("gui-picture:" (ok ? "ok" : detail) "`n", "*", "UTF-8-RAW")
ExitApp()
