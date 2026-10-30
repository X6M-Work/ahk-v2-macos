#Requires AutoHotkey v2.0
#SingleInstance Force

; ==============================================================================
; AHK v2 on macOS - Live Screen Color & Coordinate Picker
; Demonstrates MouseGetPos, PixelGetColor, and Clipboard management.
; Requires macOS Screen Recording permission for PixelGetColor.
; ==============================================================================

active := false

ToolTip("Press F7 to toggle live color inspection under mouse`nPress F8 to exit", 100, 100)
SetTimer(() => ToolTip(), -3000)

F7:: {
    global active
    active := !active
    if active {
        SetTimer(InspectPixel, 50)
    } else {
        SetTimer(InspectPixel, 0)
        ToolTip()
    }
}

InspectPixel() {
    MouseGetPos(&x, &y)
    try {
        color := PixelGetColor(x, y)
        ToolTip("X: " x " | Y: " y "`nColor: " color "`n(Press Space to copy HEX)", x + 20, y + 20)
    } catch as err {
        ToolTip("Screen capture unavailable: " err.Message, x + 20, y + 20)
    }
}

; Copy current pixel color to clipboard
#HotIf active
Space:: {
    MouseGetPos(&x, &y)
    try {
        color := PixelGetColor(x, y)
        A_Clipboard := color
        ToolTip("Copied " color " to clipboard!", x + 20, y + 20)
        SetTimer(() => ToolTip(), -1500)
    }
}
#HotIf

F8::ExitApp()
