#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
#if OSX
#Import Ks { RequestCapabilities }
if RequestCapabilities().ScreenCapture != "Granted"
    throw Error("PixelSearch requires Screen Recording permission for the native Keysharp host.")
#endif
#Include screen-pixelsearch.ahk
