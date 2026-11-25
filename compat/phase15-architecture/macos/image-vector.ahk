#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#Warn Experimental, Off
#NoTrayIcon
#Import Ks { Image }
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

img := Image.Create(24, 12)
img.Transform := { OffsetX: 2 }
img.FillRect(0, 0, 4, 4, "Red")
img.Transform := { OffsetX: 12 }
img.FillRect(0, 0, 4, 4, "Blue")
pRed := img.GetPixel(3, 2)
pBlue := img.GetPixel(13, 2)

saved := img.SaveState()
img.Transform := { ScaleX: 1, ScaleY: 1, OffsetX: 0, OffsetY: 0 }
img.Clip(Image.Path().AddRect(0, 6, 8, 6))
img.FillRect(0, 6, 20, 6, "Lime")
img.RestoreState(saved)
pClipIn := img.GetPixel(4, 8)
pClipOut := img.GetPixel(12, 8)

ok := (pRed == 0xFFFF0000) && (pBlue == 0xFF0000FF) && (pClipIn == 0xFF00FF00) && (pClipOut == 0)
FileAppend("vector:" (ok ? "ok" : Format("{:X}|{:X}|{:X}|{:X}", pRed, pBlue, pClipIn, pClipOut)) "`n", "*", "UTF-8-RAW")
ExitApp()
