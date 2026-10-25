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
        First := {__Value: "first"}, Second := {__Value: "second"}
        Function := MakeEnumerator(Kind, Count)
        try {
            Result := Function(First, Second)
            Write(Kind "/" Count "/objects:" Result "|" First.__Value "|" Second.__Value)
        } catch Error as Failure
            Write(Kind "/" Count "/objects:" Type(Failure))
        Output := "output"
        Function := MakeEnumerator(Kind, Count)
        try {
            Result := Function(123, &Output)
            Write(Kind "/" Count "/scalar:" Result "|" Output)
        } catch Error as Failure
            Write(Kind "/" Count "/scalar:" Type(Failure))
    }
}
