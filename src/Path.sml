structure Path =
struct
  structure P = OS.Path

  fun (l / r) = P.joinDirFile {dir = l, file = r}

  fun projRoot pwd =
    if P.isRoot pwd then
      NONE
    else
      let
        val target = pwd / "requirements.txt"
      in
        if OS.FileSys.access (target, []) then SOME pwd
        else projRoot (P.getParent pwd)
      end

  fun jinmoriHome () =
    case OS.Process.getEnv "HOME" of
      SOME dir => SOME (dir / ".jinmori")
    | NONE =>
        (case OS.Process.getEnv "USERPROFILE" of
           SOME dir => SOME (dir / ".jinmori")
         | NONE => NONE)
end
