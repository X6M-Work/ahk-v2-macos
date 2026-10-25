#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(ReportFailure)
ReportFailure(err, mode) {
    FileAppend(err.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
K := 1
K := 2
baſe := 3
baseValue := 4
FileAppend(K "|" k "|" baſe "|" BASEVALUE "`n", "*", "UTF-8-RAW")
o := {baſe: 5, __Claſſ: 6, K: 7, K: 8}
FileAppend(o.baſe "|" o.__Claſſ "|" o.K "|" o.k "|" ObjOwnPropCount(o) "`n", "*", "UTF-8-RAW")
