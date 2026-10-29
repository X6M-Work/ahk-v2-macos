#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#Warn LocalSameAsGlobal, Off
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message ":" err.Line "`n", "**", "UTF-8-RAW"), ExitApp(1)))
Check(actual, expected, tag) {
    if actual != expected {
        FileAppend("FAIL:" tag ":" actual ":" expected "`n", "*", "UTF-8-RAW")
        ExitApp(1)
    }
}
trace := ""
class FailedNew {
    __New() {
        throw Error("expected")
    }
    __Delete() {
        global trace
        trace .= "new|"
    }
}
try FailedNew()
catch {
    trace .= "catch|"
}
Check(trace, "new|catch|", "failed __New releases before catch")
trace := ""
FailInitializer() {
    throw Error("expected")
}
class FailedInit {
    Field := FailInitializer()
    __Delete() {
        global trace
        trace .= "init|"
    }
}
try FailedInit()
catch {
    trace .= "catch|"
}
Check(trace, "init|catch|", "failed __Init releases before catch")
trace := ""
class MissingArgument {
    __New(required) {
    }
    __Delete() {
        global trace
        trace .= "argument|"
    }
}
try MissingArgument()
catch {
    trace .= "catch|"
}
Check(trace, "argument|catch|", "failed argument binding releases instance")
trace := ""
saved := 0
class SavedBeforeFailure {
    __New() {
        global saved
        saved := this
        throw Error("expected")
    }
    __Delete() {
        global trace
        trace .= "saved|"
    }
}
try SavedBeforeFailure()
catch {
}
Check(trace, "", "retained failed instance survives")
saved := 0
Check(trace, "saved|", "retained failed instance releases once")
trace := ""
deletes := 0
class ResurrectFailed {
    __New() {
        throw Error("expected")
    }
    __Delete() {
        global trace, deletes, saved
        deletes += 1
        trace .= deletes "|"
        if deletes = 1
            saved := this
    }
}
try ResurrectFailed()
catch {
}
Check(trace, "1|", "failed constructor destructor can resurrect")
saved := 0
Check(trace, "1|2|", "resurrected failed instance releases again")
FileAppend("pass`n", "*", "UTF-8-RAW")
ExitApp()
