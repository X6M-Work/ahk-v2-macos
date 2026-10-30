#Requires AutoHotkey v2.0
#SingleInstance Force

; ==============================================================================
; AHK v2 on macOS - Window Management Example
; Use keyboard shortcuts to snap, center, maximize, or minimize the active window.
; Requires macOS Accessibility permission granted in System Settings.
; ==============================================================================

TrayTip("Window Manager", "Shortcuts active: Ctrl+Alt+Arrows", 2)

; Snap Active Window to Left Half (Ctrl + Option + Left)
^!Left:: {
    if !WinExist("A")
        return
    MonitorGetWorkArea(, &monLeft, &monTop, &monRight, &monBottom)
    halfWidth := (monRight - monLeft) // 2
    fullHeight := monBottom - monTop
    WinMove(monLeft, monTop, halfWidth, fullHeight, "A")
    ToolTip("Snapped Left")
    SetTimer(ToolTip, -1000)
}

; Snap Active Window to Right Half (Ctrl + Option + Right)
^!Right:: {
    if !WinExist("A")
        return
    MonitorGetWorkArea(, &monLeft, &monTop, &monRight, &monBottom)
    halfWidth := (monRight - monLeft) // 2
    fullHeight := monBottom - monTop
    WinMove(monLeft + halfWidth, monTop, halfWidth, fullHeight, "A")
    ToolTip("Snapped Right")
    SetTimer(ToolTip, -1000)
}

; Maximize Active Window (Ctrl + Option + Up)
^!Up:: {
    if !WinExist("A")
        return
    MonitorGetWorkArea(, &monLeft, &monTop, &monRight, &monBottom)
    WinMove(monLeft, monTop, monRight - monLeft, monBottom - monTop, "A")
    ToolTip("Maximized")
    SetTimer(ToolTip, -1000)
}

; Center Active Window at 1000x700 (Ctrl + Option + Down)
^!Down:: {
    if !WinExist("A")
        return
    MonitorGetWorkArea(, &monLeft, &monTop, &monRight, &monBottom)
    w := 1000
    h := 700
    x := monLeft + ((monRight - monLeft - w) // 2)
    y := monTop + ((monBottom - monTop - h) // 2)
    WinMove(x, y, w, h, "A")
    ToolTip("Centered")
    SetTimer(ToolTip, -1000)
}

; Minimize Active Window (Ctrl + Option + M)
^!m:: {
    if WinExist("A")
        WinMinimize("A")
}

; Close Active Window (Ctrl + Option + W)
^!w:: {
    if WinExist("A")
        WinClose("A")
}

; Exit this script (Ctrl + Option + Escape)
^!Esc::ExitApp()
