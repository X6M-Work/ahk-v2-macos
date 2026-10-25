#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(FatalError)
class TextObject
{
    ToString() => "text"
}
class IntegerText
{
    ToString() => 42
}
class ObjectText
{
    ToString() => {}
}
class EmptyText
{
    ToString()
    {
        return
    }
}
for Value in [[], Map(), {}, TextObject(), IntegerText(), ObjectText(), EmptyText()]
{
    Probe(Type(Value) ":String", () => String(Value))
    Probe(Type(Value) ":concat", () => "x" Value)
    Probe(Type(Value) ":StrLen", () => StrLen(Value))
    Probe(Type(Value) ":Format", () => Format("{}", Value))
}
Probe(Label, Callback)
{
    try
    {
        Result := Callback()
        FileAppend(Label ":" Type(Result) (IsObject(Result) ? "" : "=" Result) "`n", "*", "UTF-8-RAW")
    }
    catch Error as Failure
        FileAppend(Label ":" Type(Failure) "`n", "*", "UTF-8-RAW")
}

FatalError(UnhandledError, ErrorMode)
{
    FileAppend("unhandled:" Type(UnhandledError) ":" UnhandledError.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
