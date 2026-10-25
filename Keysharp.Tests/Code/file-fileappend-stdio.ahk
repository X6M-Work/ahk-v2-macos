#ErrorStdOut
#Warn All, StdOut
#NoTrayIcon
#CSharp
private static System.IO.TextWriter capturedOutput, capturedError;
private static System.IO.StringWriter outputCapture, errorCapture;
public static object ConfigureConsole() {
    System.Console.OutputEncoding = System.Text.Encoding.Unicode;
    System.Console.OutputEncoding = System.Text.Encoding.GetEncoding(1252);
    return 0L;
}
public static object ConsoleCodePage() => (long)System.Console.OutputEncoding.CodePage;
public static object StartCapture() {
    capturedOutput = System.Console.Out;
    capturedError = System.Console.Error;
    outputCapture = new System.IO.StringWriter();
    errorCapture = new System.IO.StringWriter();
    System.Console.SetOut(outputCapture);
    System.Console.SetError(errorCapture);
    return 0L;
}
public static object FinishCapture() {
    System.Console.SetOut(capturedOutput);
    System.Console.SetError(capturedError);
    return outputCapture.ToString() + "|" + errorCapture.ToString();
}
#EndCSharp
ConfigureConsole()
StartCapture()
FileAppend("capturedé", "*", "UTF-8-RAW")
FileAppend("captured漢", "**", "UTF-16-RAW")
if FinishCapture() != "capturedé|captured漢"
    throw Error("TextWriter capture was bypassed")

FileAppend("é漢😀`n", "*", "UTF-8-RAW")
FileAppend("é漢😀`n", "**", "UTF-8-RAW")
FileEncoding("UTF-8-RAW")
FileAppend("été`n", "*")
FileAppend("été`n", "**")
FileEncoding("CP1252")
FileAppend("é", "*")
FileAppend("é", "**")
FileEncoding("UTF-16")
FileAppend("漢", "*")
FileAppend("漢", "**")
FileAppend("é", "*", "UTF-8")
FileAppend("é", "**", "UTF-8")
FileAppend("x`ny`r`n", "*", "`n UTF-8-RAW")
FileAppend("x`ny`r`n", "**", "`n UTF-8-RAW")
if ConsoleCodePage() != 1252
    throw Error("FileAppend changed Console.OutputEncoding")
FileAppend("pass", "*", "UTF-8-RAW")
