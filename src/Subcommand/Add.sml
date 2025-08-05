structure Add: SUBCOMMAND =
struct
  fun updateConfig projDir pkgs =
    let
      val deps = map Package.toString pkgs
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

  structure Command =
    CommandFn
      (structure Parser = Parser_PrefixFn(val prefix = "--")
       type action = Package.t list
       val desc = "Add dependencies to a project"
       val flags = []
       val anonymous =
         Argument.Any {action = map Package.fromString, metavar = "PKG"})

  fun run args =
    let
      val [pkgs] = Command.run args
      val projDir = Path.projectRoot (OS.FileSys.getDir ())
    in
      (List.app Package.fetch pkgs; updateConfig projDir pkgs)
    end
end
