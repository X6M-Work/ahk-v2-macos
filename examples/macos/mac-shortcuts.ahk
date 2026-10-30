#Requires AutoHotkey v2.0
#SingleInstance Force

; ==============================================================================
; AHK v2 on macOS - Productivity Hotkeys & Text Expansion
; Demonstrates text expansions (hotstrings), application launch, and sound alerts.
; Requires macOS Accessibility & Input Monitoring permissions.
; ==============================================================================

; --- Text Expansions (Hotstrings) ---
; Type :]d and space to insert current ISO date (YYYY-MM-DD)
:X:]d::SendText(FormatTime(, "yyyy-MM-dd"))

; Type :]dt to insert current date & time
:X:]dt::SendText(FormatTime(, "yyyy-MM-dd HH:mm:ss"))

; Type :]shrug to insert ASCII shrug emoji
::]shrug::¯\_(ツ)_/¯

; --- Quick Application Launchers ---
; Ctrl + Option + T -> Launch or focus Terminal
^!t:: {
    Run("open -a Terminal")
}

; Ctrl + Option + N -> Launch or focus Notes
^!n:: {
    Run("open -a Notes")
}

; Ctrl + Option + C -> Open Calculator
^!c:: {
    Run("open -a Calculator")
}

; --- Audio & Status Feedback ---
; Ctrl + Option + B -> Play a test beep tone
^!b:: {
    SoundBeep(750, 150)
    ToolTip("SoundBeep tested!")
    SetTimer(ToolTip, -1200)
}

; Ctrl + Option + Q -> Exit script
^!q::ExitApp()
