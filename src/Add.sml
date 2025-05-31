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
      val pkgs = map Pkg.toString pkgs
      val file = TextIO.openAppend (projDir / Path.manifest)
      val _ = TextIO.output (file, String.concatWith "\n" pkgs ^ "\n")
    in
      TextIO.flushOut file
    end

  fun run pkgs =
    case Path.projectRoot (OS.FileSys.getDir ()) of
      SOME projDir => (List.app (ignore o Pkg.fetch) pkgs; updateConfig projDir pkgs)
    | NONE => raise Path.ProjectRoot
end
