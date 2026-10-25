#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(ReportFailure)
ReportFailure(err, mode) {
    FileAppend(err.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
values := ["", "2", "20", "200", "2004", "20041", "200401", "2004010", "20040101", "200401010", "2004010100", "20040101000", "200401010000", "2004010100000", "20040101000000", "200401010000000", "1600", "1601", "9999", "0001", "19000229", "20000229", "16040229", "20040230", "200400", "200413", "20040100", "20040101240000", "20040101235960", "20040101235959", " 2004", "2004 ", "2004`n", "２００４", "2004.0", 2004, 2004.0, {}, []]
for index, value in values {
    try FileAppend(index "|" IsTime(value) "`n", "*", "UTF-8-RAW")
    catch as err
        FileAppend(index "|" Type(err) "`n", "*", "UTF-8-RAW")
}
