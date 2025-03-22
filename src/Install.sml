structure Install: CONFIG =
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
      fun loop home [] = OK ()
        | loop home (p :: pkgs) =
            case Pkg.fetchSrc home p of
              ERR _ => ERR ("Could not find package " ^ Package.toString p)
            | OK dest =>
                (case Pkg.build (dest, home / "bin") p of
                   OK _ => loop home pkgs
                 | ERR _ =>
                     ERR ("Could not build package " ^ Package.toString p))
    in
      case Path.jinmoriHome () of
        SOME home => loop home pkgs
      | NONE => ERR "Could not find project root"
    end
end
