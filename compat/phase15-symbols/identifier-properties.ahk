#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(ReportFailure)
ReportFailure(err, mode) {
    FileAppend(err.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
o := {õ: 1, Õ: 2, σ: 3, ς: 4, Mixed: 5}
o.MIXED += 1
name := "Õ"
o.%name% += 10
FileAppend(Format("{}|{}|{}|{}|{}|{}`n", o.õ, o.Õ, o.σ, o.ς, o.mixed, ObjOwnPropCount(o)), "*", "UTF-8-RAW")
c := o.Clone()
c.DefineProp("Õ", {Value: 22})
c.DeleteProp("σ")
FileAppend(Format("{}|{}|{}|{}|{}|{}`n", c.õ, c.Õ, c.ς, c.HasOwnProp("σ"), c.HasOwnProp("ς"), o.GetOwnPropDesc("Õ").Value), "*", "UTF-8-RAW")
p := {}
p.DefineProp("õ", {Get: (*) => 10})
p.DefineProp("Õ", {Get: (*) => 20})
FileAppend(p.õ "|" p.Õ "`n", "*", "UTF-8-RAW")
