#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERROR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

Emit(line) => FileAppend(line "`n", "*", "UTF-8-RAW")

; SplitPath contracts
SplitPath("C:\Folder\Sub\archive.tar.gz", &name, &dir, &ext, &noext, &drive)
Emit("sp_win|" name "|" dir "|" ext "|" noext "|" drive)

SplitPath("https://example.com/a/b/index.html", &name, &dir, &ext, &noext, &drive)
Emit("sp_url|" name "|" dir "|" ext "|" noext "|" drive)

SplitPath("plainfile", &name, &dir, &ext, &noext, &drive)
Emit("sp_bare|" name "|" dir "|" ext "|" noext "|" drive)

; File/Dir lifecycle on relative working-directory paths
workDir := "ks_pathops_root"
movedDir := "ks_pathops_moved"
copiedDir := "ks_pathops_copied"
srcFile := "ks_pathops_root/alpha.txt"
copyFile := "ks_pathops_root/beta.txt"
moveFile := "ks_pathops_root/gamma.txt"

try {
    DirCreate(workDir)
    Emit("dir_exist|" (InStr(DirExist(workDir), "D") > 0 ? 1 : 0))

    FileAppend("hello world", srcFile, "UTF-8-RAW")
    Emit("file_exist|" (FileExist(srcFile) != "" ? 1 : 0))
    Emit("file_size|" FileGetSize(srcFile))

    FileCopy(srcFile, copyFile, true)
    Emit("copy_read|" FileRead(copyFile, "UTF-8-RAW"))

    FileMove(copyFile, moveFile, true)
    Emit("move_old|" (FileExist(copyFile) == "" ? 1 : 0))
    Emit("move_new|" FileRead(moveFile, "UTF-8-RAW"))

    DirCopy(workDir, copiedDir, true)
    Emit("dircopy_ok|" (FileExist(copiedDir "/alpha.txt") != "" ? 1 : 0))

    DirMove(copiedDir, movedDir, "R")
    Emit("dirmove_old|" (DirExist(copiedDir) == "" ? 1 : 0))
    Emit("dirmove_new|" (FileExist(movedDir "/gamma.txt") != "" ? 1 : 0))

    FileDelete(moveFile)
    Emit("filedel_ok|" (FileExist(moveFile) == "" ? 1 : 0))
} finally {
    try DirDelete(workDir, true)
    try DirDelete(copiedDir, true)
    try DirDelete(movedDir, true)
}

Emit("cleanup_ok|" ((DirExist(workDir) == "" && DirExist(movedDir) == "") ? 1 : 0))
