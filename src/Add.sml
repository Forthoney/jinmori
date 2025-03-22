structure Add: CONFIG =
struct
  open Result
  open Path

  structure Pkg = Package

  type config = Pkg.package list
  type parser = (string list * config) -> (string list * config, string) result

  fun depParser ([], pkgs) = OK ([], pkgs)
    | depParser (addr :: args, pkgs) =
        case Pkg.fromString addr of
          SOME pkg => depParser (args, pkg :: pkgs)
        | NONE => ERR addr

  val parseOrder = [depParser]

  val default = []

  fun run pkgs =
    let
      fun download _ _ [] = OK ()
        | download home proj (p :: pkgs) =
            case Pkg.fetchSrc home p of
              OK path =>
                ( Posix.FileSys.symlink
                    {old = path, new = proj / "lib" / #name p}
                ; download home proj pkgs
                )
            | ERR _ => ERR ("Could not download " ^ Pkg.toString p)
    in
      case (Path.jinmoriHome (), Path.projRoot (OS.FileSys.getDir ())) of
        (SOME home, SOME projDir) => download home projDir pkgs
      | (NONE, _) => ERR "$JINMORI_HOME not found"
      | (_, NONE) => ERR "Could not find project root"
    end
end
