fun (l / r) = OS.Path.joinDirFile {dir = l, file = r}

structure Path =
struct
  exception Home
  exception ProjectRoot

  val manifest = "Jinmori.json"

  val home =
    case OS.Process.getEnv "JINMORI_HOME" of
      SOME dir => SOME dir
    | NONE =>
        (case OS.Process.getEnv "HOME" of
           SOME dir => SOME (dir / ".jinmori")
         | NONE =>
             (case OS.Process.getEnv "USERPROFILE" of
                SOME dir => SOME (dir / ".jinmori")
              | NONE => NONE))

  fun projectRoot pwd =
    if OS.Path.isRoot pwd then NONE
    else if OS.FileSys.access (pwd / manifest, []) then SOME pwd
    else projectRoot (OS.Path.getParent pwd)
end
