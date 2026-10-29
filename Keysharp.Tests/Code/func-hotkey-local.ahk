#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
#Include <assert>

fixture := Gui(, "Keysharp hotkey fixture")
fired := 0

try {
	fixture.Show("w180 h80")
	WinActivate(fixture)
	if !WinWaitActive(fixture, , 3)
		throw Error("The hotkey fixture did not become active.")
	SendLevel(1)
	SendEvent("{F12}")
	deadline := A_TickCount + 3000
	while !fired && A_TickCount < deadline
		Sleep(10)
	AssertEq(fired, 1, A_LineNumber)
} finally
	fixture.Destroy()

FileAppend "pass", "*"
ExitApp

#HotIf IsSet(fixture) && WinActive("ahk_id " fixture.Hwnd)
F12::{
	testupdate() {
		return 1
	}
	global fired := testupdate()
}
#HotIf
