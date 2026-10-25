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
    for Count in [-1, 0, 1, 2, 3] {
        Loop 5 {
            Function := MakeEnumerator(Kind, Count)
            ArgumentCount := A_Index - 1
            First := "first", Second := "second", Third := "third", Fourth := "fourth"
            try {
                switch ArgumentCount {
                    case 0: Result := Function()
                    case 1: Result := Function(&First)
                    case 2: Result := Function(&First, &Second)
                    case 3: Result := Function(&First, &Second, &Third)
                    case 4: Result := Function(&First, &Second, &Third, &Fourth)
                }
                Write(Kind "/" Count "/" ArgumentCount ":" Result "|" First "|" Second "|" Third "|" Fourth)
            } catch Error as Failure
                Write(Kind "/" Count "/" ArgumentCount ":" Type(Failure))
        }
    }
}
