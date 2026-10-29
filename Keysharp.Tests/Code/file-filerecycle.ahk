#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
#Include <assert>

scratch := A_Temp "/KeysharpRecycle-" ProcessExist() "-" A_TickCount
if DirExist(scratch)
    throw Error("Recycle fixture already exists.")
DirCreate(scratch)
try {
    FileAppend("one", scratch "/file1.txt")
    FileAppend("two", scratch "/file2.txt")
    FileAppend("three", scratch "/file3txt")
    quoted := scratch "/file with ' quote-é.txt"
    FileAppend("argument safety", quoted)
    FileRecycle(quoted)
    Assert(!FileExist(quoted), A_LineNumber)
    FileRecycle(scratch "/file1.txt")
    Assert(!FileExist(scratch "/file1.txt"), A_LineNumber)
    Assert(FileExist(scratch "/file2.txt"), A_LineNumber)
    Assert(FileExist(scratch "/file3txt"), A_LineNumber)
    FileRecycle(scratch "/*.txt")
    Assert(!FileExist(scratch "/file2.txt"), A_LineNumber)
    Assert(FileExist(scratch "/file3txt"), A_LineNumber)
    DirCreate(scratch "/nested folder")
    FileAppend("nested", scratch "/nested folder/child.txt")
    FileRecycle(scratch "/*")
    Assert(!FileExist(scratch "/file3txt"), A_LineNumber)
    Assert(!DirExist(scratch "/nested folder"), A_LineNumber)
    Throws(() => FileRecycle(""), A_LineNumber, ValueError)
    Throws(() => FileRecycle(scratch "/nosuch.txt"), A_LineNumber, OSError)
    FileRecycle(scratch "/*.none")
} finally
    if DirExist(scratch)
        DirDelete(scratch, true)

FileAppend "pass", "*"
