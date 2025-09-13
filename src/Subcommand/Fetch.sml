structure Fetch =
struct
  structure Command =
    CommandFn
      (structure Parser = Parser_PrefixFn(val prefix = "--")
       type action = unit
       val desc = "Fetch dependencies for a Jinmori project"
       val flags = [Shared.verbosity ()]
       val anonymous = Argument.None (fn () => ())
      )

  fun run args =
    let
      val _ = Command.run args
      val projectDir = Path.projectRoot (OS.FileSys.getDir ())
      val {dependencies, ...} = Manifest.read (projectDir / Path.manifest)
    in
      app (Package.addToDeps o Package.fetch o Package.fromString) dependencies
    end
end
