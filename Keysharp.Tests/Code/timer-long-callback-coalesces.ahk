#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
#Include <assert>

ticks := []
finishes := []
running := 0
maxRunning := 0

LongCallback(*)
{
    global ticks, finishes, running, maxRunning
    running += 1
    maxRunning := Max(maxRunning, running)
    ticks.Push(A_TickCount)

    try
        Sleep(140)
    finally
    {
        finishes.Push(A_TickCount)
        running -= 1

        if finishes.Length = 4
            SetTimer(LongCallback, 0)
    }
}

SetTimer(LongCallback, 80)
deadline := A_TickCount + 5000

try
{
    while finishes.Length < 4 && A_TickCount < deadline
        Sleep(10)
}
finally
    SetTimer(LongCallback, 0)

Sleep(-1)
AssertEq(ticks.Length, 4, A_LineNumber)
AssertEq(finishes.Length, 4, A_LineNumber)
AssertEq(maxRunning, 1, A_LineNumber)

Loop Min(ticks.Length, finishes.Length)
{
    Assert(finishes[A_Index] - ticks[A_Index] >= 80, A_LineNumber)

    if A_Index > 1
        Assert(ticks[A_Index] >= finishes[A_Index - 1], A_LineNumber)
}

FileAppend "pass", "*"
