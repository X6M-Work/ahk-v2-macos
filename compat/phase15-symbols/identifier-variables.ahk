#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(ReportFailure)
ReportFailure(err, mode) {
    FileAppend(err.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
õ := 1
Õ := 2
σ := 3
ς := 4
MixedASCII := 5
mixedascii += 1
name := "Õ"
%name% += 10
FileAppend(Format("{}|{}|{}|{}|{}`n", õ, Õ, σ, ς, MIXEDASCII), "*", "UTF-8-RAW")
LocalNames(õ, Õ, σ, ς) {
    õ += 10
    Õ += 20
    σ += 30
    ς += 40
    selector := "õ"
    %selector% += 100
    MixedLocal := 7
    MIXEDLOCAL += 1
    return Format("{}|{}|{}|{}|{}", õ, Õ, σ, ς, mixedlocal)
}
FileAppend(LocalNames(1, 2, 3, 4) "`n", "*", "UTF-8-RAW")
State() {
    static õ := 0, Õ := 10
    õ += 1
    Õ += 2
    return õ "|" Õ
}
FileAppend(State() "|" State() "`n", "*", "UTF-8-RAW")
ClosureNames() {
    local õ := 1, Õ := 2, σ := 3, ς := 4
    return () => õ "|" Õ "|" σ "|" ς
}
FileAppend(ClosureNames()() "`n", "*", "UTF-8-RAW")
