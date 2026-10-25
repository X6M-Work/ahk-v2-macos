#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(ReportFailure)
ReportFailure(err, mode) {
    FileAppend(err.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
class õ {
    õ() => 1
    Õ() => 2
    σ() => 3
    ς() => 4
    Mixed() => 5
    static õ() => 11
    static Õ() => 12
    static σ() => 13
    static ς() => 14
}
class Õ {
    Value() => 20
}
class σ {
    Value() => 30
}
class ς {
    Value() => 40
}
o := õ()
method := "Õ"
FileAppend(Format("{}|{}|{}|{}|{}|{}`n", o.õ(), o.Õ(), o.σ(), o.ς(), o.MIXED(), o.%method%()), "*", "UTF-8-RAW")
FileAppend(Format("{}|{}|{}|{}|{}|{}|{}`n", õ.õ(), õ.Õ(), õ.σ(), õ.ς(), Õ().Value(), σ().Value(), ς().Value()), "*", "UTF-8-RAW")
FileAppend(Format("{}|{}`n", HasMethod(o, "Õ"), ObjBindMethod(o, "Õ")()), "*", "UTF-8-RAW")
