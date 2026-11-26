#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

; CoreAudio device query: succeeds with valid values when audio hardware exists,
; or raises TargetError/OSError cleanly on headless CI VMs with no audio device.
audioOk := 0
try {
	name := SoundGetName()
	vol := SoundGetVolume()
	mute := SoundGetMute()
	if (StrLen(name) > 0 && vol >= 0 && vol <= 100 && (mute == 0 || mute == 1))
		audioOk := 1
} catch TargetError {
	audioOk := 1
} catch OSError {
	audioOk := 1
}

FileAppend("sound-audio:" (audioOk ? "ok" : "fail") "`n", "*", "UTF-8-RAW")
ExitApp()
