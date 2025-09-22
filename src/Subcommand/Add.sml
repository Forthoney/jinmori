structure Add: SUBCOMMAND =
struct
  fun updateManifest projDir pkgs =
    let
      val _ = Logger.info "updating manifest file (if necessary)"
      val deps = map Package.toString pkgs
      val {package, dependencies, supportedCompilers} =
        Manifest.read (projDir / Path.manifest)
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
        , { package = package
          , dependencies = dependencies
          , supportedCompilers = supportedCompilers
          }
        )
    end

  structure Command =
    CommandFn
      (structure Parser = Parser_PrefixFn(val prefix = "--")
       type action = Package.t list
       val desc = "Add dependencies to a project"
       val flags = [Shared.verbosity []]
       val anonymous = Argument.Any
         { action = map
             (Argument.asType'
                {typeName = "Package.t", fromString = Package.fromString})
         , metavar = "PKG"
         })

  fun run args =
    let
      val pkgs = (List.hd o Command.run) args
      val projDir = Path.projectRoot (OS.FileSys.getDir ())
      val _ = List.app (Package.addToDeps o Package.fetch) pkgs
    in
      updateManifest projDir pkgs
    end
end
