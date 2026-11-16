#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

Emit(line) => FileAppend(line "`n", "*", "UTF-8-RAW")

Emit("add_days|" DateAdd("20240228230000", 2, "Days"))
Emit("add_hours|" DateAdd("20240228230000", 2, "Hours"))
Emit("diff_hours|" DateDiff("20240301010000", "20240228230000", "Hours"))
Emit("diff_secs|" DateDiff("20240101000105", "20240101000000", "Seconds"))
Emit("fmt_iso|" FormatTime("20240229090807", "yyyy-MM-dd HH:mm:ss"))
Emit("fmt_compact|" FormatTime("20240229090807", "yyyyMMddHHmmss"))

Emit("cmp_ci|" StrCompare("Alpha", "alpha", 0))
Emit("cmp_cs_diff|" (StrCompare("apple", "APPLE", 1) != 0 ? 1 : 0))
Emit("cmp_cs_ord|" (StrCompare("apple", "banana", 1) < 0 ? -1 : 1))
Emit("cmp_num|" (StrCompare("file2", "file10", "Logical") < 0 ? -1 : 1))

Emit("sort_nu|" Sort("10,2,1,2,3", "N U D,"))
Emit("sort_nur|" Sort("10,2,1,2,3", "N U R D,"))
Emit("sort_cs|" Sort("c,a,b", "C D,"))
Emit("sort_ci|" Sort("B,a,C", "D,"))
Emit("sort_custom|" Sort("ccc,a,bb", "D,", (x, y, *) => StrLen(x) - StrLen(y)))
