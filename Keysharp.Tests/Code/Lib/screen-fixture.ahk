ScreenTestFixture() {
    window := Gui("+AlwaysOnTop", "Keysharp screen fixture")
    pixelMode := A_CoordModePixel
    try {
        window.BackColor := "112233"
        swatch := window.AddText("x40 y50 w100 h80 BackgroundCC5533", "")
        window.Show("NoActivate w320 h220")
        CoordMode("Pixel", "Screen")
        deadline := A_TickCount + 3000
        swatchColor := backgroundColor := "unavailable"
        Loop {
            WinGetPos(&swatchX, &swatchY, &swatchWidth, &swatchHeight, swatch.Hwnd)
            if swatchWidth > 0 && swatchHeight > 0 {
                swatchColor := PixelGetColor(swatchX + swatchWidth // 2, swatchY + swatchHeight // 2)
                backgroundColor := PixelGetColor(swatchX - 10, swatchY + 10)
                if swatchColor = "0xCC5533" && backgroundColor = "0x112233"
                    return {Window: window, X: swatchX, Y: swatchY, Width: swatchWidth, Height: swatchHeight}
            }
            if A_TickCount >= deadline
                throw Error("The screen fixture did not render its expected colors. Swatch: " swatchColor ", background: " backgroundColor)
            Sleep(10)
        }
    } catch {
        window.Destroy()
        throw
    } finally
        CoordMode("Pixel", pixelMode)
}
