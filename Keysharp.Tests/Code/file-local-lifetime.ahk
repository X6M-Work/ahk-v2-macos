#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))
root := A_Temp "/Keysharp-FileLifetime-" ProcessExist() "-" A_TickCount
DirCreate(root)
retained := 0
originalWrite := 0
Check(actual, expected, label) {
    if actual !== expected
        throw Error(label ": got <" actual "> expected <" expected ">")
}
WriteLocal(path) {
    stream := FileOpen(path, "w-rwd", "UTF-8-RAW")
    stream.Write("sealed")
}
WriteAlias(path) {
    stream := FileOpen(path, "w-rwd", "UTF-8-RAW")
    other := stream
    other.Write("alias")
}
WriteEarly(path) {
    stream := FileOpen(path, "w-rwd", "UTF-8-RAW")
    stream.Write("early")
    return 17
}
WriteThrow(path) {
    stream := FileOpen(path, "w-rwd", "UTF-8-RAW")
    stream.Write("throw")
    throw Error("expected")
}
WritePair(firstPath, secondPath) {
    first := FileOpen(firstPath, "w-rwd", "UTF-8-RAW")
    second := FileOpen(secondPath, "w-rwd", "UTF-8-RAW")
    first.Write("first")
    second.Write("second")
}
WriteLoop(path) {
    stream := FileOpen(path, "w-rwd", "UTF-8-RAW")
    Loop 3
        stream.Write("x")
}
WriteNamed(path) {
    KS_localFiles := FileOpen(path, "w-rwd", "UTF-8-RAW")
    KS_localFiles_ := KS_localFiles
    KS_localFiles_.Write("named")
}
WriteFinally(path) {
    stream := FileOpen(path, "w-rwd", "UTF-8-RAW")
    try {
        stream.Write("body")
        return 19
    } finally {
        stream.Write("finally")
    }
}
ReturnFile(path) {
    stream := FileOpen(path, "w-rwd", "UTF-8-RAW")
    return stream
}
ReturnArray(path) {
    stream := FileOpen(path, "w-rwd", "UTF-8-RAW")
    return [stream]
}
ReturnMap(path) {
    stream := FileOpen(path, "w-rwd", "UTF-8-RAW")
    return Map("file", stream)
}
ReturnObject(path) {
    stream := FileOpen(path, "w-rwd", "UTF-8-RAW")
    return {file: stream}
}
SaveGlobal(path) {
    global retained
    stream := FileOpen(path, "w-rwd", "UTF-8-RAW")
    retained := stream
}
ReturnClosure(path) {
    stream := FileOpen(path, "w-rwd", "UTF-8-RAW")
    return () => stream
}
ReturnReference(path) {
    stream := FileOpen(path, "w-rwd", "UTF-8-RAW")
    return &stream
}
Borrow(stream) => stream.Write("borrowed")
ReadReference(&value) => value
KeepWriter(this, text) {
    global retained, originalWrite
    retained := this
    return originalWrite.Call(this, text)
}
WriteConsole() {
    stream := FileOpen("*", "w", "UTF-8-RAW")
    stream.Write("")
    stream.Write("pa")
}
try {
    path := root "/local.txt"
    WriteLocal(path)
    Check(FileRead(path, "UTF-8"), "sealed", "local flush and close")
    path := root "/alias.txt"
    WriteAlias(path)
    Check(FileRead(path, "UTF-8"), "alias", "local alias")
    path := root "/early.txt"
    Check(WriteEarly(path), 17, "early return value")
    Check(FileRead(path, "UTF-8"), "early", "early return close")
    path := root "/throw.txt"
    try WriteThrow(path)
    catch Error as err
        Check(err.Message, "expected", "original exception")
    Check(FileRead(path, "UTF-8"), "throw", "exception close")
    WritePair(root "/first.txt", root "/second.txt")
    Check(FileRead(root "/first.txt", "UTF-8"), "first", "first file")
    Check(FileRead(root "/second.txt", "UTF-8"), "second", "second file")
    path := root "/loop.txt"
    WriteLoop(path)
    Check(FileRead(path, "UTF-8"), "xxx", "loop writes")
    path := root "/named.txt"
    WriteNamed(path)
    Check(FileRead(path, "UTF-8"), "named", "generated name collision")
    path := root "/finally.txt"
    Check(WriteFinally(path), 19, "finally return")
    Check(FileRead(path, "UTF-8"), "bodyfinally", "cleanup follows user finally")
    returnedFile := ReturnFile(root "/return.txt")
    Check(returnedFile.Write("returned"), 8, "returned file stays open")
    returnedFile.Close()
    files := ReturnArray(root "/array.txt")
    Check(files[1].Write("array"), 5, "array escape")
    files[1].Close()
    files := ReturnMap(root "/map.txt")
    Check(files["file"].Write("map"), 3, "map escape")
    files["file"].Close()
    files := ReturnObject(root "/object.txt")
    Check(files.file.Write("object"), 6, "property escape")
    files.file.Close()
    SaveGlobal(root "/global.txt")
    Check(retained.Write("global"), 6, "global escape")
    retained.Close()
    reader := ReturnClosure(root "/closure.txt")
    returnedFile := reader()
    Check(returnedFile.Write("closure"), 7, "closure escape")
    returnedFile.Close()
    reference := ReturnReference(root "/reference.txt")
    returnedFile := ReadReference(reference)
    Check(returnedFile.Write("reference"), 9, "VarRef escape")
    returnedFile.Close()
    returnedFile := ReturnFile(root "/borrow.txt")
    Borrow(returnedFile)
    Check(returnedFile.Write("!"), 1, "borrowed file stays open")
    returnedFile.Close()
    descriptor := File.Prototype.GetOwnPropDesc("Write")
    originalWrite := descriptor.Call
    try {
        File.Prototype.DefineProp("Write", {Call: KeepWriter})
        WriteLocal(root "/callback.txt")
    } finally {
        File.Prototype.DefineProp("Write", descriptor)
    }
    Check(retained.Write("!"), 1, "rebound method retains receiver")
    retained.Close()
    WriteConsole()
    FileAppend("", "*", "UTF-8-RAW")
} finally {
    for name in ["local", "alias", "early", "throw", "first", "second", "loop", "named", "finally", "return", "array", "map", "object", "global", "closure", "reference", "borrow", "callback"] {
        path := root "/" name ".txt"
        if FileExist(path)
            FileDelete(path)
    }
    DirDelete(root)
}
FileAppend("ss`n", "*", "UTF-8-RAW")
