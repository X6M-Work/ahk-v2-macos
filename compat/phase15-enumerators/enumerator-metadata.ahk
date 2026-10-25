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
    Function := MakeEnumerator(Kind)
    Write(Kind "/omitted:" Type(Function) "|" Function.MinParams "|" Function.MaxParams "|" Function.IsVariadic)
    if Kind == "OwnProps"
        continue
    for Count in [-2, -1, 0, 1, 2, 3, 1.9, "2", "bad"] {
        try {
            Function := MakeEnumerator(Kind, Count)
            Write(Kind "/" Count ":" Function.MinParams "|" Function.MaxParams "|" Function.IsVariadic)
        } catch Error as Failure
            Write(Kind "/" Count ":" Type(Failure))
    }
}
