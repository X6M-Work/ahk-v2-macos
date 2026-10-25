#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
OnError(FatalError)
FatalError(UnhandledError, ErrorMode) {
    FileAppend("unhandled:" Type(UnhandledError) ":" UnhandledError.Message "`n", "**", "UTF-8-RAW")
    ExitApp(1)
}
MakeEnumerator(Kind, Count?) {
    switch Kind {
        case "Array": Source := [20, 30]
        case "Map": Source := Map(2, "two", 3, "three")
        case "Regex": RegExMatch("abc", "(a)(?<Named>b)(c)", &Source)
        case "OwnProps": Source := {Alpha: 20, Beta: 30}
    }
    return Kind == "OwnProps" ? Source.OwnProps() : IsSet(Count) ? Source.__Enum(Count) : Source.__Enum()
}
Write(Text) => FileAppend(Text "`n", "*", "UTF-8-RAW")
ProbeGetters()
ProbeGetters() {
    Loop 8 {
        Calls := 0
        Source := {}.DefineProp("Value", {Get: (*) => (++Calls, 10)})
        Function := Source.OwnProps()
        Key := "key", Value := "value"
        Variant := A_Index - 1
        switch Variant {
            case 0: Result := Function()
            case 1: Result := Function(&Key)
            case 2: Result := Function(&Key,)
            case 3: Result := Function(&Key, 123)
            case 4: Result := Function(, &Value)
            case 5: Result := Function(&Key, &Value)
            case 6: Result := Function(123, &Value)
            case 7: Result := Function({__Value: "x"}, {__Value: "y"})
        }
        Write(Variant ":" Result "|" Calls "|" Key "|" Value)
    }
}
