#Requires AutoHotkey v2.0

; ==============================================================================
; macOS Apple Events, AppleScript & JXA Automation Example (Keysharp)
; ==============================================================================
; Demonstrates the three macOS automation bridges available in Keysharp:
;   1. ComObject("AppName") : Direct native Apple Events (AEDesc / sdef bridge)
;   2. Ks.AppleScript(...)  : Inline AppleScript via /usr/bin/osascript
;   3. Ks.Jxa(...)          : Inline JavaScript for Automation (JXA)
; ==============================================================================

if (A_OS != "Darwin") {
    MsgBox("This example requires macOS (Darwin). Current OS: " A_OS, "macOS Only", "Icon!")
    ExitApp()
}

; ------------------------------------------------------------------------------
; 1. Native Apple Events via ComObject (Finder & System Events)
; ------------------------------------------------------------------------------
finder := ComObject("Finder.app")
finderVersion := finder.version
desktopPath := finder.desktop.url

; ------------------------------------------------------------------------------
; 2. Inline AppleScript via Ks.AppleScript()
; ------------------------------------------------------------------------------
appleScriptResult := Ks.AppleScript('
(
    on run argv
        set greetingPrefix to item 1 of argv
        tell application "System Events"
            set frontApp to name of first application process whose frontmost is true
        end tell
        return greetingPrefix & ": Frontmost app is " & frontApp
    end run
)', "AppleScript")

; ------------------------------------------------------------------------------
; 3. Inline JavaScript for Automation (JXA) via Ks.Jxa()
; ------------------------------------------------------------------------------
jxaResult := Ks.Jxa('
(
    function run(argv) {
        const se = Application("System Events");
        const procCount = se.applicationProcesses.length;
        return argv[0] + ": " + procCount + " active GUI/background processes";
    }
)', "JXA")

summary := "macOS Automation Bridge Summary`n"
    . "----------------------------------------`n"
    . "Finder version (Apple Events): " finderVersion "`n"
    . "Desktop URL (Apple Events): " desktopPath "`n"
    . appleScriptResult "`n"
    . jxaResult

MsgBox(summary, "Keysharp macOS Apple Events & osascript", "Iconi")
