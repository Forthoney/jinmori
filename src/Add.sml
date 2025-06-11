structure Add: COMMAND =
struct
  structure Pkg = Package

  type config = Pkg.t list
  type parser = (string list * config) -> (string list * config)

  fun depParser (args, pkgs) =
    ([], map (Option.valOf o Pkg.fromString) args @ pkgs)

  val parseOrder = [depParser]

  val default = []

  fun updateConfig projDir pkgs =
    let
      val deps = map Pkg.toString pkgs
      val {package, dependencies} = Manifest.read (projDir / Path.manifest)
      fun add acc =
        fn [] => acc
         | (dep :: rest) =>
          case List.find (fn s => s = dep) acc of
            SOME _ => add acc rest
          | NONE => add (dep :: acc) rest
      val dependencies = add dependencies deps
    in
      Manifest.write
        ( projDir / Path.manifest
        , {package = package, dependencies = dependencies}
        )
    end

  fun run pkgs =
    case Path.projectRoot (OS.FileSys.getDir ()) of
      SOME projDir =>
        (List.app (ignore o Pkg.fetch) pkgs; updateConfig projDir pkgs)
    | NONE => raise Path.ProjectRoot
end
