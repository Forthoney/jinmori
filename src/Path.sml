structure Path =
struct
  exception Home
  exception Root
  exception Command of string

  val manifest = "Jinmori.json"

  fun home () =
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
    if OS.Path.isRoot pwd then raise Root
    else if OS.FileSys.access (pwd / manifest, []) then pwd
    else projectRoot (OS.Path.getParent pwd)

  fun which cmd =
    let
      open OS.Process
      open OS.FileSys
      val path = Option.getOpt (getEnv "PATH", "/bin:/usr/bin")
      val paths = String.fields (fn c => c = #":") path
      fun searchDir [] = raise Command cmd
        | searchDir (dir :: rest) =
            let
              val strm = SOME (openDir dir) handle OS.SysErr _ => NONE
            in
              case strm of
                NONE => searchDir rest
              | SOME strm =>
                  let
                    fun loop () =
                      case readDir strm of
                        NONE => NONE
                      | SOME f =>
                          if f = cmd andalso access (dir / f, [A_EXEC]) then
                            SOME (dir / f)
                          else
                            loop ()
                  in
                    case loop () of
                      SOME path => path
                    | NONE => searchDir rest
                  end
            end
    in
      searchDir paths
    end
end
