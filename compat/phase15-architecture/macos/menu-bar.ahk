#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#Warn Experimental, Off
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

fileMenu := Menu()
noop := (*) => ""
fileMenu.Add("&Open", noop)
fileMenu.Add("&Save", noop)
fileMenu.Check("&Open")
fileMenu.Uncheck("&Open")
fileMenu.Disable("&Save")
fileMenu.Enable("&Save")
fileMenu.Rename("&Save", "Save &As")
fileMenu.Delete("Save &As")

mb := MenuBar()
mb.Add("&File", fileMenu)

g := Gui()
g.MenuBar := mb
g.Destroy()

FileAppend("menu-bar:ok`n", "*", "UTF-8-RAW")
ExitApp()
