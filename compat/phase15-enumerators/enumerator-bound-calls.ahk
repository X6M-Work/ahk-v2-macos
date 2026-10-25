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
    for Count in [1, 2] {
        Loop 6 {
            Function := MakeEnumerator(Kind, Count)
            Variant := A_Index
            First := "first", Second := "second", Third := "third"
            try {
                switch Variant {
                    case 1: Bound := Function.Bind(), Result := Bound(&First, &Second)
                    case 2: Bound := Function.Bind(&First), Result := Bound(&Second)
                    case 3: Bound := Function.Bind(, &Second), Result := Bound(&First)
                    case 4: Bound := Function.Bind(&First, &Second), Result := Bound()
                    case 5: Bound := Function.Bind().Bind(&First), Result := Bound(&Second)
                    case 6: Bound := Function.Bind(&First, &Second, &Third), Result := Bound()
                }
                Write(Kind "/" Count "/" Variant ":" Result "|" First "|" Second "|" Third)
            } catch Error as Failure
                Write(Kind "/" Count "/" Variant ":" Type(Failure))
        }
    }
}
