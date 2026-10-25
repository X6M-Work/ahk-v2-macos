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
    for Count in [0, 1, 2, 3] {
        Loop 5 {
            Function := MakeEnumerator(Kind, Count)
            Variant := A_Index - 1
            First := "first", Second := "second", Third := "third"
            try {
                switch Variant {
                    case 0: Bound := Function.Bind()
                    case 1: Bound := Function.Bind(&First)
                    case 2: Bound := Function.Bind(&First, &Second)
                    case 3: Bound := Function.Bind(, &Second)
                    case 4: Bound := Function.Bind(&First, &Second, &Third)
                }
                Write(Kind "/" Count "/" Variant ":" Type(Bound) "|" Bound.MinParams "|" Bound.MaxParams "|" Bound.IsVariadic)
            } catch Error as Failure
                Write(Kind "/" Count "/" Variant ":" Type(Failure))
        }
    }
}
