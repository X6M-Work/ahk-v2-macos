#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#Warn Experimental, Off
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

g := Gui()
wv := g.Add("WebView", "w300 h200")
eng := wv.Engine
t := Type(wv)
url := wv.Url
back := wv.CanGoBack
fwd := wv.CanGoForward
wv.BrowserContextMenuEnabled := false
cm1 := wv.BrowserContextMenuEnabled
wv.BrowserContextMenuEnabled := true
cm2 := wv.BrowserContextMenuEnabled
wv.GoBack()
wv.GoForward()
wv.Stop()
g.Destroy()

ok := (t == "Gui.WebView") && (eng ~= "^(Edge|InternetExplorer|WebKit)$") && (url == "") && !back && !fwd && !cm1 && cm2
FileAppend("webview:" (ok ? "ok" : t "|" eng "|" url "|" back "|" fwd "|" cm1 "|" cm2) "`n", "*", "UTF-8-RAW")
ExitApp()
