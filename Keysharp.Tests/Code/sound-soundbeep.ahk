#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
#Include <assert>

SoundBeep()
started := A_TickCount
SoundBeep(880, 100)
Assert(A_TickCount - started >= 70, A_LineNumber)
SoundBeep(880, 0)
SoundBeep(36, 1)
SoundBeep(32768, 1)
SoundBeep(0, 0)
Throws(() => SoundBeep({}, 1), A_LineNumber, TypeError)

FileAppend "pass", "*"
