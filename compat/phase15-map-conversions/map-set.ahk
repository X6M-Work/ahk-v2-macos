#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(FatalError)
for Arguments in [[], ["orphan"], [1, "a", 2], [[1, "a"]], [Map(1, "a")]]
{
    Values := Map(9, "existing")
    try
    {
        Result := Values.Set(Arguments*)
        FileAppend("ok|" (Result == Values) "|" Values.Count "|" Values.Has(9) "`n", "*", "UTF-8-RAW")
    }
    catch Error as Failure
        FileAppend(Type(Failure) "|" Values.Count "|" Values.Has(9) "`n", "*", "UTF-8-RAW")
}
for Arguments in [[1], [1, "a", 2]]
{
    try
        Values := Map(Arguments*), FileAppend("constructor:ok`n", "*", "UTF-8-RAW")
    catch Error as Failure
        FileAppend("constructor:" Type(Failure) "`n", "*", "UTF-8-RAW")
}

FatalError(UnhandledError, ErrorMode)
{
    FileAppend("unhandled:" Type(UnhandledError) ":" UnhandledError.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
