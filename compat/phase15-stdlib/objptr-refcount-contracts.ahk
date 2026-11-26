#ErrorStdOut
#Warn All, StdOut
#Requires AutoHotkey v2.0
#NoTrayIcon
OnError((err, mode) => (FileAppend("ERR:" err.Message "`n", "**", "UTF-8-RAW"), ExitApp(1)))

lines := []

; ObjPtr / ObjPtrAddRef / ObjFromPtr / ObjFromPtrAddRef
o := { name: "alpha", count: 42 }
p1 := ObjPtr(o)
p2 := ObjPtrAddRef(o)
lines.Push("ptr_eq=" (p1 != 0 ? 1 : 0) "|" (p1 == p2 ? 1 : 0))

; ObjFromPtr consumes the extra reference from ObjPtrAddRef; ObjFromPtrAddRef adds its own ref
oFromAdd := ObjFromPtr(p2)
oFromBorrow := ObjFromPtrAddRef(p1)
lines.Push("from_ptr=" (oFromAdd == o ? 1 : 0) "|" (oFromBorrow == o ? 1 : 0) "|" oFromBorrow.name "|" oFromBorrow.count)

; ObjAddRef / ObjRelease balance on raw pointer
p3 := ObjPtrAddRef(o)
ObjAddRef(p3)
ObjRelease(p3)
ObjRelease(p3)
lines.Push("rel=ok")

out := ""
for _, line in lines
	out .= line "`n"
FileAppend(out, "*", "UTF-8-RAW")
