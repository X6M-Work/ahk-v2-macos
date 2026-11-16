#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

Emit(line) => FileAppend(line "`n", "*", "UTF-8-RAW")

pid := ProcessExist()
ppid := ProcessGetParent()
pname := ProcessGetName(pid)
ppath := ProcessGetPath(pid)

Emit("pid_pos|" (pid > 0 ? 1 : 0))
Emit("ppid_match|" (ppid > 0 && ppid == ProcessGetParent(pid) ? 1 : 0))
Emit("name_nonempty|" (pname != "" ? 1 : 0))
Emit("path_exists|" (ppath != "" && FileExist(ppath) != "" ? 1 : 0))
Emit("path_ends_with_name|" (InStr(ppath, pname) > 0 ? 1 : 0))
Emit("exist_by_name|" (ProcessExist(pname) > 0 ? 1 : 0))
Emit("set_prio_missing|" ProcessSetPriority("H", -1))

for label, fn in Map(
    "parent_missing", () => ProcessGetParent(-1),
    "name_missing", () => ProcessGetName("keysharp-nonexistent-process-probe.exe"),
    "path_missing", () => ProcessGetPath("keysharp-nonexistent-process-probe.exe")
) {
    try {
        fn()
        Emit(label "|UNEXPECTED")
    } catch as e {
        Emit(label "|" Type(e))
    }
}
