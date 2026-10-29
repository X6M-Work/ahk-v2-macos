_TestDisposableVolume()
{
#if WINDOWS
    _root := EnvGet("KEYSHARP_TEST_VOLUME")
    if !RegExMatch(_root, "i)^[a-z]:\\$") || StrLower(_root) = StrLower(EnvGet("SystemDrive") "\")
        throw Error("Requires a disposable non-system drive root in KEYSHARP_TEST_VOLUME.")
    if DriveGetLabel(_root) != "KEYSHARP_TEST"
        throw Error("Disposable test volume must be labeled KEYSHARP_TEST.")
    if FileRead(_root ".keysharp-disposable-test-volume") != "Keysharp disposable test volume"
        throw Error("Disposable test volume marker is missing or invalid.")
    return _root
#else
    throw Error("Requires an isolated OS account/volume; do not empty the session trash.")
#endif
}
