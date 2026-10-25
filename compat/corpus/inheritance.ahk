#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(ReportFailure)
ReportFailure(err, mode) {
    FileAppend(err.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
class Parent {
    __New(Name) {
        this.Name := Name
    }
    Describe() => "base"
}
class Child extends Parent {
    __New(Name) {
        super.__New(Name)
        this.Number := 4
    }
    Describe() => super.Describe() ":child"
}
Value := Child("sample")
FileAppend(Format("{}|{}|{}|{}`n", Value.Name, Value.Number, Value.Describe(), Value is Parent), "*", "UTF-8-RAW")
