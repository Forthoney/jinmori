structure Install: CONFIG =
struct
  structure Pkg = Package

  type config = Pkg.package list
  type parser = (string list * config) -> (string list * config)

  fun depParser (args, pkgs) =
    ([], map (Option.valOf o Pkg.fromString) args @ pkgs)

  val parseOrder = [depParser]

  val default = []

  val run = List.app (fn pkg => Pkg.build (Pkg.fetch pkg, Path.home / "bin") pkg)
end
