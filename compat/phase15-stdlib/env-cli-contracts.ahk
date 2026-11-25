#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; EnvGet / EnvSet round-trip, overwrite, and clear
envName := "KS_COMPAT_ENV_TEST_42"
EnvSet(envName, "alpha=beta")
lines.Push("env1=" EnvGet(envName))
EnvSet(envName, "updated value")
lines.Push("env2=" EnvGet(envName))
EnvSet(envName)
lines.Push("env3=" (EnvGet(envName) == "" ? "empty" : "nonempty"))

; Sort: numeric, reverse, unique, custom delimiter, custom comparator
lines.Push("sort_num=" Sort("10,2,30,2,1", "N U D,"))
lines.Push("sort_rev=" Sort("b|a|c", "R D|"))

LenCmp(a, b, *) {
	d := StrLen(a) - StrLen(b)
	if (d != 0)
		return d
	return StrCompare(a, b)
}
lines.Push("sort_fn=" Sort("pear,fig,apple,ki", "D,", LenCmp))

; StrSplit / Trim / SubStr / InStr / StrReplace
parts := StrSplit("  a , b , c , d  ", ",", " ", 3)
lines.Push("split=" parts.Length ":" parts[1] "|" parts[2] "|" parts[3])
lines.Push("trim=" Trim("  --hi--  ", " -") "|" LTrim("xxab", "x") "|" RTrim("abxx", "x"))
lines.Push("substr=" SubStr("abcdef", -3) "|" SubStr("abcdef", 2, -2))
lines.Push("instr=" InStr("ababa", "ba", false, -1) "|" InStr("ababa", "a", false, 1, 3))

cnt := 0
replaced := StrReplace("one-two-one-three-one", "one", "X", , &cnt, 2)
lines.Push("strrep=" replaced "|" cnt)

; RegExMatch & RegExReplace with named subpatterns
pos := RegExMatch("id=42 name=Keysharp!", "id=(?<id>\d+)\s+name=(?<name>[A-Za-z]+)", &m)
lines.Push("re_match=" pos "|" m["id"] "|" m["name"] "|" m.Pos["name"] "|" m.Len["name"])
reOut := RegExReplace("2026-11-25", "(?<y>\d{4})-(?<m>\d{2})-(?<d>\d{2})", "${d}/${m}/${y}")
lines.Push("re_rep=" reOut)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
