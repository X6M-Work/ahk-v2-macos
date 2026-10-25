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
for Kind in ["Array", "Map", "Regex", "OwnProps"] {
    for Count in [0, 1, 2] {
        Loop 6 {
            Function := MakeEnumerator(Kind, Count)
            First := "first", Second := "second"
            Variant := A_Index
            try {
                switch Variant {
                    case 1: Result := Function(123)
                    case 2: Result := Function(&First, 123)
                    case 3: Result := Function(&First, &Second, 123)
                    case 4: Result := Function(, &Second)
                    case 5: Result := Function(&First,)
                    case 6: Result := Function(,, &Second)
                }
                Write(Kind "/" Count "/" Variant ":" Result "|" First "|" Second)
            } catch Error as Failure
                Write(Kind "/" Count "/" Variant ":" Type(Failure))
        }
    }
}
