#Requires AutoHotkey v2.0
#ErrorStdOut
#Warn All, StdOut

arr := ["a", "b", "c", "d", "e"]
r1 := arr.RemoveAt(2)
r2 := arr.RemoveAt(-1)
r3 := arr.RemoveAt(1, "2")
FileAppend("remove|" r1 "|" r2 "|" r3 "|" arr.Length "|" arr[1] "`n", "*", "UTF-8-RAW")

t1 := 0
t2 := 0
t3 := 0
try arr.RemoveAt(1, "x")
catch TypeError
    t1 := 1
try arr.RemoveAt(1, "")
catch TypeError
    t2 := 1
try arr.RemoveAt(1, {})
catch TypeError
    t3 := 1

v1 := 0
v2 := 0
try arr.RemoveAt(5)
catch ValueError
    v1 := 1
try arr.RemoveAt(1, 2)
catch ValueError
    v2 := 1
FileAppend("errors|" t1 "|" t2 "|" t3 "|" v1 "|" v2 "`n", "*", "UTF-8-RAW")

cv := ComValue(3, 42)
ct1 := ComObjType(cv)
ct2 := ComObjType(cv, "Name")
ct3 := ComObjType(cv, "IID")
ct4 := ComObjType(123)
ct5 := ComObjType("abc")
ct6 := ComObjType({})
ct7 := ComObjType([1, 2])
FileAppend("comtype|" ct1 "|<" ct2 ">|<" ct3 ">|<" ct4 ">|<" ct5 ">|<" ct6 ">|<" ct7 ">`n", "*", "UTF-8-RAW")
