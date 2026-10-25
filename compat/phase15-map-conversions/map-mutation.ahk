#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(FatalError)
for Action in ["insert", "delete-current", "delete-earlier", "delete-later", "update", "clear", "insert-before"]
{
    Values := Map(1, "a", 3, "c", 5, "e")
    Result := ""
    Steps := 0
    for Key, Value in Values
    {
        Result .= Key ":" Value ","
        Steps += 1
        if Steps > 8
            break
        if Steps = 1
        {
            switch Action
            {
                case "insert": Values[2] := "b", Values[7] := "g"
                case "delete-current": Values.Delete(1)
                case "delete-later": Values.Delete(3)
                case "update": Values[3] := "changed"
                case "clear": Values.Clear()
                case "insert-before": Values[0] := "z"
            }
        }
        else if Steps = 2 && Action = "delete-earlier"
            Values.Delete(1)
    }
    FileAppend(Action ":" Result "`n", "*", "UTF-8-RAW")
}
Values := Map(1, "a", 3, "c")
Enumeration := Values.__Enum(2)
Values[2] := "b"
while Enumeration(&Key, &Value)
    FileAppend(Key ":" Value ",", "*", "UTF-8-RAW")
FileAppend("`n", "*", "UTF-8-RAW")

FatalError(UnhandledError, ErrorMode)
{
    FileAppend("unhandled:" Type(UnhandledError) ":" UnhandledError.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
