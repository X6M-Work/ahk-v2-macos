#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#Include <assert>

õ := 1, Õ := 2, σ := 3, ς := 4
MixedASCII := 5
mixedascii += 1
selector := "Õ"
%selector% += 10
AssertEq(õ "|" Õ "|" σ "|" ς "|" MIXEDASCII, "1|12|3|4|6", A_LineNumber)

LocalNames(õ, Õ, σ, ς) {
    õ += 10, Õ += 20, σ += 30, ς += 40
    localSelector := "õ"
    %localSelector% += 100
    MixedLocal := 7
    MIXEDLOCAL += 1
    return õ "|" Õ "|" σ "|" ς "|" mixedlocal
}
AssertEq(LocalNames(1, 2, 3, 4), "111|22|33|44|8", A_LineNumber)
State() {
    static õ := 0, Õ := 10
    õ += 1, Õ += 2
    return õ "|" Õ
}
AssertEq(State() "|" State(), "1|12|2|14", A_LineNumber)
ClosureNames() {
    local õ := 1, Õ := 2, σ := 3, ς := 4
    return () => õ "|" Õ "|" σ "|" ς
}
AssertEq(ClosureNames()(), "1|2|3|4", A_LineNumber)

Fõ() => 1
FÕ() => 2
Fσ() => 3
Fς() => 4
MiXeD() => 5
AssertEq(Fõ() "|" FÕ() "|" Fσ() "|" Fς() "|" mixed(), "1|2|3|4|5", A_LineNumber)
funcSelector := "FÕ"
AssertEq(%funcSelector%(), 2, A_LineNumber)

class Cõ {
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
class CÕ {
    Value() => 20
}
class Cσ {
    Value() => 30
}
class Cς {
    Value() => 40
}
o := Cõ()
AssertEq(o.õ() "|" o.Õ() "|" o.σ() "|" o.ς() "|" o.MIXED(), "1|2|3|4|5", A_LineNumber)
AssertEq(Cõ.õ() "|" Cõ.Õ() "|" Cõ.σ() "|" Cõ.ς(), "11|12|13|14", A_LineNumber)
AssertEq(CÕ().Value() "|" Cσ().Value() "|" Cς().Value(), "20|30|40", A_LineNumber)
methodSelector := "Õ"
AssertEq(o.%methodSelector%(), 2, A_LineNumber)
AssertEq(ObjBindMethod(o, "Õ")(), 2, A_LineNumber)

p := {õ: 1, Õ: 2, σ: 3, ς: 4, Mixed: 5}
p.MIXED += 1
p.%selector% += 10
AssertEq(p.õ "|" p.Õ "|" p.σ "|" p.ς "|" p.mixed, "1|12|3|4|6", A_LineNumber)
AssertEq(ObjOwnPropCount(p), 5, A_LineNumber)
c := p.Clone()
c.DefineProp("Õ", {Value: 22})
c.DeleteProp("σ")
AssertEq(c.õ "|" c.Õ "|" c.ς, "1|22|4", A_LineNumber)
AssertEq(c.HasOwnProp("σ"), 0, A_LineNumber)
AssertEq(c.HasOwnProp("ς"), 1, A_LineNumber)
AssertEq(p.GetOwnPropDesc("Õ").Value, 12, A_LineNumber)
getters := {}
getters.DefineProp("õ", {Get: (*) => 10})
getters.DefineProp("Õ", {Get: (*) => 20})
AssertEq(getters.õ "|" getters.Õ, "10|20", A_LineNumber)

class DeclaredProperties {
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
}
declared := DeclaredProperties()
AssertEq(declared.Readõ "|" declared.ReadÕ "|" declared.σ "|" declared.ς, "1|2|3|4", A_LineNumber)
AssertEq(DeclaredProperties.õ "|" DeclaredProperties.Õ, "11|12", A_LineNumber)

K := 1
K := 2
special := {baſe: 5, __Claſſ: 6, K: 7, K: 8}
AssertEq(K "|" k, "1|2", A_LineNumber)
AssertEq(special.baſe "|" special.__Claſſ "|" special.K "|" special.k, "5|6|7|8", A_LineNumber)
AssertEq(ObjOwnPropCount(special), 4, A_LineNumber)

labelSelector := "LÕ"
Goto(labelSelector)
Lõ:
Assert(false, A_LineNumber)
Goto finish
LÕ:
AssertEq(IsLabel("Lõ") "|" IsLabel("LÕ") "|" IsLabel("mixedlabel"), "1|1|1", A_LineNumber)
Goto mIxEdLaBeL
MixedLabel:
AssertEq(1, 1, A_LineNumber)
finish:
FileAppend "pass", "*"
