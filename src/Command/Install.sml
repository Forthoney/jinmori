structure Install: COMMAND =
struct
  structure Pkg = Package

  type config = Pkg.t list
  type parser = (string list * config) -> (string list * config)

  val shortHelp = "Install a Jinmori binary"

  fun depParser (args, pkgs) =
    ([], map (Option.valOf o Pkg.fromString) args @ pkgs)

  val parseOrder = [depParser]

  val default = []

  val run =
    case Path.home of
      NONE => raise Path.Home
    | SOME home =>
        List.app (fn pkg => Pkg.build (Pkg.fetch pkg, home / "bin") pkg)
end
