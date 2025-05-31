fun (l / r) = OS.Path.joinDirFile {dir = l, file = r}

structure Path =
struct
  exception Home
  exception ProjectRoot

  val manifest = "Jinmori.toml"

  val home =
    case OS.Process.getEnv "JINMORI_HOME" of
      SOME dir => dir
    | NONE =>
        (case OS.Process.getEnv "HOME" of
           SOME dir => dir / ".jinmori"
         | NONE =>
             (case OS.Process.getEnv "USERPROFILE" of
                SOME dir => dir / ".jinmori"
              | NONE => raise Home))

  fun projectRoot pwd =
    if OS.Path.isRoot pwd then NONE
    else if OS.FileSys.access (pwd / manifest, []) then SOME pwd
    else projectRoot (OS.Path.getParent pwd)
end
