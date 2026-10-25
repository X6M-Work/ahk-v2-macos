#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(ReportFailure)
ReportFailure(err, mode) {
    FileAppend(err.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
class Counter {
    static Created := 0
    __New(Value := 2) {
        this.Value := Value
        Counter.Created += 1
    }
    Add(Amount := 1) {
        this.Value += Amount
        return this.Value
    }
    Doubled {
        get => this.Value * 2
    }
}
First := Counter()
Second := Counter(10)
FileAppend(Format("{}|{}|{}|{}`n", First.Add(), First.Doubled, Second.Add(5), Counter.Created), "*", "UTF-8-RAW")
