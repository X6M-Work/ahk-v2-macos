#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
#Include <assert>

#Include <disposablevolume>

root := _TestDisposableVolume()
scratch := root "KeysharpRecycleEmpty-" ProcessExist() "-" A_TickCount
if DirExist(scratch)
    throw Error("Recycle fixture already exists.")
DirCreate(scratch)
try {
    FileAppend("one", scratch "\file1.txt")
    FileAppend("two", scratch "\file2.txt")
    FileAppend("three", scratch "\file3txt")
    FileRecycle(scratch "\*")
    Assert(!FileExist(scratch "\file1.txt"), A_LineNumber)
    Assert(!FileExist(scratch "\file2.txt"), A_LineNumber)
    Assert(!FileExist(scratch "\file3txt"), A_LineNumber)
    info := Buffer(24, 0)
    NumPut("UInt", 24, info, 0)
    AssertEq(DllCall("shell32\SHQueryRecycleBinW", "WStr", root, "Ptr", info, "Int"), 0, A_LineNumber)
    Assert(NumGet(info, 16, "Int64") >= 3, A_LineNumber)
    FileRecycleEmpty(root)
    AssertEq(DllCall("shell32\SHQueryRecycleBinW", "WStr", root, "Ptr", info, "Int"), 0, A_LineNumber)
    AssertEq(NumGet(info, 16, "Int64"), 0, A_LineNumber)
} finally
    if DirExist(scratch)
        DirDelete(scratch, true)

FileAppend "pass", "*"
