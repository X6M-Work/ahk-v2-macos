#NoTrayIcon

#import KS { FileFullPath }
#Include <assert>
#Include <testpaths>
; #Include %A_ScriptDir%/header.ahk

if (DirExist("./FileGetShortcut"))
	DirDelete("./FileGetShortcut", true)

if (FileExist("./testshortcut.lnk"))
	FileDelete("./testshortcut.lnk")

path := A_ScriptDir . "/"
dir := path . "DirCopy"
DirCopy(dir, "./FileGetShortcut/")
SplitPath(FileFullPath("./FileGetShortcut/file1.txt"), , &fullpath)

#if LINUX || OSX
	FileCreateShortcut("./FileGetShortcut/file1.txt", "./testshortcut.lnk")
	FileGetShortcut("./testshortcut.lnk",
												&outTarget,
												&outDir,
												&outArgs,
												&outDescription,
												&outIcon,
												&outIconNum,
												&outRunState)

AssertEq(StrLower(FileFullPath("./FileGetShortcut/file1.txt")), StrLower(outTarget), A_LineNumber)

AssertEq(fullpath, outDir, A_LineNumber)

Assert(outDescription == "" &&
	outArgs == "" &&
	outIcon == "" &&
	outIconNum == "" &&
	outRunState == ""
, A_LineNumber)

if (FileExist("./testshortcut.lnk"))
	FileDelete("./testshortcut.lnk")

#endif

#if WINDOWS
	FileCreateShortcut("./FileGetShortcut/file1.txt", "./testshortcut.lnk", fullpath, "", "TestDescription", _TestFixturePath("../../assets/Keysharp.ico"), "")
#else
	FileCreateShortcut("./FileGetShortcut/file1.txt", "./testshortcut.lnk", fullpath, "", "TestDescription", _TestFixturePath("../../assets/Keysharp.ico"), 2)
#endif

Assert(FileExist("./testshortcut.lnk"), A_LineNumber)

outTarget :=
outDir :=
outArgs :=
outDescription :=
outIcon :=
outIconNum :=
outRunState := ""
FileGetShortcut("./testshortcut.lnk",
	&outTarget,
	&outDir,
	&outArgs,
	&outDescription,
	&outIcon,
	&outIconNum,
	&outRunState)

AssertEq(StrLower(FileFullPath("./FileGetShortcut/file1.txt")), StrLower(outTarget), A_LineNumber)

AssertEq(fullpath, outDir, A_LineNumber)

AssertEq("TestDescription", outDescription, A_LineNumber)

AssertEq("", outArgs, A_LineNumber)

expectedIcon := _TestFixturePath("../../assets/Keysharp.ico")
#if LINUX || OSX
expectedIcon := FileFullPath(expectedIcon)
#endif

AssertEq(expectedIcon, outIcon, A_LineNumber)

#if WINDOWS
	AssertEq("1", outIconNum, A_LineNumber)

	AssertEq("1", outRunState, A_LineNumber)
#else
	AssertEq("Link", outIconNum, A_LineNumber)

	AssertEq("", outRunState, A_LineNumber)

	FileCreateShortcut("./FileGetShortcut/file1.txt", "./testshortcut_multi.lnk", fullpath, '--flag=1 --name "a b"', "MultiArgDesc", "", 2)
	FileGetShortcut("./testshortcut_multi.lnk", &multiTarget, &multiDir, &multiArgs, &multiDesc, &multiIcon, &multiType)
	AssertEq(StrLower(FileFullPath("./FileGetShortcut/file1.txt")), StrLower(multiTarget), A_LineNumber)
	AssertEq(fullpath, multiDir, A_LineNumber)
	AssertEq('--flag=1 --name "a b"', multiArgs, A_LineNumber)
	AssertEq("MultiArgDesc", multiDesc, A_LineNumber)
	AssertEq("", multiIcon, A_LineNumber)
	AssertEq("Link", multiType, A_LineNumber)
	FileDelete("./testshortcut_multi.lnk")
#endif

if (DirExist("./FileGetShortcut"))
	DirDelete("./FileGetShortcut", true)

if (FileExist("./testshortcut.lnk"))
	FileDelete("./testshortcut.lnk")

FileAppend "pass", "*"
