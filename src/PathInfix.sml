fun (l / r) = OS.Path.joinDirFile {dir = l, file = r}
infix ext
fun (l ext r) =
  OS.Path.joinBaseExt {base = l, ext = SOME r}
