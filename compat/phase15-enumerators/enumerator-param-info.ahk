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
    for Count in [-2, -1, 0, 1, 2, 3] {
        Function := MakeEnumerator(Kind, Count)
        for Method in ["IsOptional", "IsByRef"] {
            try
                Write(Kind "/" Count "/" Method "():" Function.%Method%())
            catch Error as Failure
                Write(Kind "/" Count "/" Method "():" Type(Failure))
            for Param in [0, 1, 2, 3, 4] {
                try
                    Write(Kind "/" Count "/" Method "(" Param "):" Function.%Method%(Param))
                catch Error as Failure
                    Write(Kind "/" Count "/" Method "(" Param "):" Type(Failure))
            }
        }
    }
}
