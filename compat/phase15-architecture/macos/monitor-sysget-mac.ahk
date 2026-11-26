#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

cnt := MonitorGetCount()
pri := MonitorGetPrimary()
MonitorGet(pri, &ml, &mt, &mr, &mb)
MonitorGetWorkArea(pri, &wl, &wt, &wr, &wb)
mname := MonitorGetName(pri)
vsw := SysGet(78)
vsh := SysGet(79)

ok := (cnt >= 1) && (pri >= 1) && (mr > ml) && (mb > mt) && (wr > wl) && (wb > wt) && (StrLen(mname) > 0) && (vsw > 0) && (vsh > 0) && (A_ScreenWidth > 0) && (A_ScreenHeight > 0)
FileAppend("monitor-sysget:" (ok ? "ok" : cnt "|" pri "|" (mr - ml) "x" (mb - mt) "|" vsw "x" vsh "|" mname) "`n", "*", "UTF-8-RAW")
ExitApp()
