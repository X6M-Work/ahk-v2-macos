#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(FatalError)
class TextObject
{
    ToString() => "123"
}
for Name in ["IsAlnum", "IsAlpha", "IsDigit", "IsLower", "IsUpper", "IsSpace", "IsXDigit", "IsTime", "IsInteger", "IsFloat", "IsNumber"]
{
    Predicate := %Name%
    for Value in [123, 1.5, "", "123", "١٢٣", "0x", "0xFF", "1e2", "`n12`n", [], TextObject()]
    {
        try
            FileAppend(Name ":" Type(Value) ":" Predicate(Value) "`n", "*", "UTF-8-RAW")
        catch Error as Failure
            FileAppend(Name ":" Type(Value) ":" Type(Failure) "`n", "*", "UTF-8-RAW")
    }
}

FatalError(UnhandledError, ErrorMode)
{
    FileAppend("unhandled:" Type(UnhandledError) ":" UnhandledError.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
