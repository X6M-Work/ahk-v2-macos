#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

; 1. Security.framework SecRandomCopyBytes (kSecRandomDefault = 0)
sec := "/System/Library/Frameworks/Security.framework/Security"
rndBuf := Buffer(16, 0)
rcSec := DllCall(sec "\SecRandomCopyBytes", "Ptr", 0, "UPtr", 16, "Ptr", rndBuf, "Int")
nonZero := 0
Loop 16 {
    if (NumGet(rndBuf, A_Index - 1, "UChar") != 0)
        nonZero++
}
secOk := (rcSec == 0) && (nonZero > 0)

; 2. libSystem arc4random_uniform(1000)
u := DllCall("libSystem.B.dylib\arc4random_uniform", "UInt", 1000, "UInt")
arcOk := (u >= 0) && (u < 1000)

; 3. libSystem gettimeofday (struct timeval: Int64 tv_sec, Int tv_usec)
tv := Buffer(16, 0)
rcTv := DllCall("libSystem.B.dylib\gettimeofday", "Ptr", tv, "Ptr", 0, "Int")
tvSec := NumGet(tv, 0, "Int64")
tvUsec := NumGet(tv, 8, "Int")
tvOk := (rcTv == 0) && (tvSec > 1700000000) && (tvUsec >= 0) && (tvUsec < 1000000)

ok := secOk && arcOk && tvOk
FileAppend("sec-random:" (ok ? "ok" : rcSec "|" nonZero "|" u "|" rcTv "|" tvSec "|" tvUsec) "`n", "*", "UTF-8-RAW")
ExitApp()
