#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut

n := GetKeyState("16JoyName")
x := GetKeyState("16JoyX")
pov := GetKeyState("16JoyPOV")
b1 := GetKeyState("16Joy1")
info := GetKeyState("16JoyInfo")
btns := GetKeyState("16JoyButtons")
axes := GetKeyState("16JoyAxes")
FileAppend("unattached|<" n ">|<" x ">|<" pov ">|<" b1 ">|<" info ">|" btns "|" axes "`n", "*", "UTF-8-RAW")

badCount := 0
for badName in ["0Joy1", "00JoyX", "17JoyName", "999999999999Joy1", "Joy33", "JoyXtra"]
{
    try GetKeyState(badName)
    catch ValueError
        badCount += 1
}

hkErr := 0
try Hotkey("0Joy1", (*) => 0)
catch ValueError
    hkErr := 1

FileAppend("invalid|" badCount "|" hkErr "`n", "*", "UTF-8-RAW")
