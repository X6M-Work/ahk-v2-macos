#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(ReportFailure)
ReportFailure(err, mode) {
    FileAppend(err.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
class Properties {
    õ := 1
    Õ := 2
    σ := 3
    ς := 4
    static õ := 11
    static Õ := 12
    Readõ {
        get => this.õ
    }
    ReadÕ {
        get => this.Õ
    }
    class σ {
        static Value := 30
    }
    class ς {
        static Value := 40
    }
}
class Derived extends Properties {
}
o := Derived()
FileAppend(o.Readõ "|" o.ReadÕ "|" o.σ "|" o.ς "`n", "*", "UTF-8-RAW")
FileAppend(Properties.õ "|" Properties.Õ "|" Properties.σ.Value "|" Properties.ς.Value "`n", "*", "UTF-8-RAW")
