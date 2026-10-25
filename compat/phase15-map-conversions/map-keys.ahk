#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(FatalError)
Values := Map(1, "integer", "1", "string", 1.0, "float")
FileAppend(Format("{}|{}|{}|{}|{}|{}`n", Values.Count, Values[1], Values["1"], Values[1.0], Values["1.0"], Values.Has(1.00)), "*", "UTF-8-RAW")
for Key, Value in Values
    FileAppend(Type(Key) ":" Key "=" Value "`n", "*", "UTF-8-RAW")
Values[1.5] := "fraction"
FileAppend(Values.Get("1.5") "|" Values.Delete(1.5) "|" Values.Has("1.5") "`n", "*", "UTF-8-RAW")
Values[true] := "boolean"
FileAppend(Values[1] "|" Values.Count "`n", "*", "UTF-8-RAW")
for NumberValue in [0.0, -0.0, 1.2345678901234567, 1.0e20, 1.0e-7]
{
    Single := Map(NumberValue, "value")
    for Key in Single
        FileAppend(Type(Key) ":" Key "|" String(NumberValue) "|" Single.Has(String(NumberValue)) "`n", "*", "UTF-8-RAW")
}

FatalError(UnhandledError, ErrorMode)
{
    FileAppend("unhandled:" Type(UnhandledError) ":" UnhandledError.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
