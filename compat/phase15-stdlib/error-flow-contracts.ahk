#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; try / catch / else / finally (no throw)
trace := ""
try {
	trace .= "T"
} catch Error as e {
	trace .= "C"
} else {
	trace .= "E"
} finally {
	trace .= "F"
}
lines.Push("tcf_ok=" trace)

; try / catch / else / finally (throw)
trace := ""
try {
	trace .= "T"
	throw ValueError("bad arg", -1, "x")
} catch ValueError as e {
	trace .= "C:" e.Message ":" e.Extra
} else {
	trace .= "E"
} finally {
	trace .= "F"
}
lines.Push("tcf_err=" trace)

; finally runs on early return
EarlyRet(&log) {
	try {
		log .= "in-"
		return 77
	} finally {
		log .= "fin"
	}
}
retLog := ""
retVal := EarlyRet(&retLog)
lines.Push("ret_fin=" retVal "|" retLog)

; Built-in Error hierarchy
errs := [
	ValueError("v"),
	TypeError("t"),
	IndexError("i"),
	UnsetItemError("k"),
	MethodError("m"),
	PropertyError("p"),
	OSError(2),
	TargetError("g")
]
hier := ""
for _, e in errs
	hier .= (e is Error ? "1" : "0")
lines.Push("err_hier=" hier)

; Switch / Case (case-insensitive default vs case-sensitive On)
SwTest(v, sense := "Off") {
	Switch v, sense {
		Case "alpha", "beta":
			return "ab"
		Case "GAMMA":
			return "G"
		Default:
			return "def"
	}
}
lines.Push("sw=" SwTest("ALPHA") "|" SwTest("ALPHA", "On") "|" SwTest("GAMMA", "On") "|" SwTest("zzz"))

; Loop / Until / Else
loopOut := ""
i := 0
Loop {
	i += 1
	loopOut .= i
} Until (i = 3)
lines.Push("until=" loopOut)

elseZero := "no"
Loop 0 {
	elseZero := "body"
} Else {
	elseZero := "else"
}
lines.Push("loop_else0=" elseZero)

elseBreak := "no"
Loop 3 {
	if (A_Index = 2)
		break
} Else {
	elseBreak := "else"
}
lines.Push("loop_else_brk=" elseBreak)

; Labeled Break / Continue
lbl := ""
outer:
Loop 3 {
	oi := A_Index
	Loop 3 {
		if (oi = 2 && A_Index = 2)
			continue outer
		if (oi = 3 && A_Index = 2)
			break outer
		lbl .= oi . A_Index . ","
	}
}
lines.Push("labeled=" lbl)

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
