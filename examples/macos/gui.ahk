#Requires AutoHotkey v2.0
#SingleInstance Force

window := Gui(, "AHK v2 on macOS")
name := window.AddEdit("w280", "macOS")
button := window.AddButton("Default w280", "Say hello")
button.OnEvent("Click", (*) => MsgBox("Hello, " name.Value "!"))
window.OnEvent("Close", (*) => ExitApp())
window.Show()
