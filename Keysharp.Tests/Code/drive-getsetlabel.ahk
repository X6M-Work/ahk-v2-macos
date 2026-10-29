#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
#Include <assert>

#Include <disposablevolume>

root := _TestDisposableVolume()
original := DriveGetLabel(root)
try {
    DriveSetLabel(root, "KS_TEST_TMP")
    AssertEq(DriveGetLabel(root), "KS_TEST_TMP", A_LineNumber)
} finally
    DriveSetLabel(root, original)
AssertEq(DriveGetLabel(root), original, A_LineNumber)

FileAppend "pass", "*"
