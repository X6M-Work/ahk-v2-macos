#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(FatalError)
Probe("omitted", () => Map(1, "a").__Enum())
for Count in [-1, 0, 1, 2, 3, 1.9, "1", "bad"]
{
    try
    {
        Enumeration := Map(1, "a").__Enum(Count)
        FileAppend(Count ":" Enumeration.MinParams "|" Enumeration.MaxParams "|" Enumeration.IsVariadic "`n", "*", "UTF-8-RAW")
    }
    catch Error as Failure
        FileAppend(Count ":" Type(Failure) "`n", "*", "UTF-8-RAW")
}
for Count in [1, 2]
{
    Loop 4
    {
        ArgumentCount := A_Index - 1
        Enumeration := Map(1, "a").__Enum(Count)
        Key := "k"
        Value := "v"
        Extra := "e"
        try
        {
            switch ArgumentCount
            {
                case 0: Result := Enumeration()
                case 1: Result := Enumeration(&Key)
                case 2: Result := Enumeration(&Key, &Value)
                case 3: Result := Enumeration(&Key, &Value, &Extra)
            }
            FileAppend(Count "/" ArgumentCount ":" Result "|" Key "|" Value "|" Extra "`n", "*", "UTF-8-RAW")
        }
        catch Error as Failure
            FileAppend(Count "/" ArgumentCount ":" Type(Failure) "`n", "*", "UTF-8-RAW")
    }
}
Probe(Label, Callback)
{
    try
    {
        ProbeResult := Callback()
        FileAppend(Label ":" Type(ProbeResult) ":" ProbeResult.MinParams "|" ProbeResult.MaxParams "|" ProbeResult.IsVariadic "`n", "*", "UTF-8-RAW")
    }
    catch Error as ProbeFailure
        FileAppend(Label ":" Type(ProbeFailure) "`n", "*", "UTF-8-RAW")
}

FatalError(UnhandledError, ErrorMode)
{
    FileAppend("unhandled:" Type(UnhandledError) ":" UnhandledError.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
