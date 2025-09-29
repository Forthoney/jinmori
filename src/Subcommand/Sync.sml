structure Sync: SUBCOMMAND =
struct
  val path = ref NONE
  structure Command =
    CommandFn
      (structure Parser = Parser_PrefixFn(val prefix = "--")
       type action = unit
       val desc = "Sync dependencies with a project"
       val flags = [Shared.verbosity ()]
       val anonymous = Argument.Optional
         { action = fn v => path := v
         , metavar = "PATH"
         })
  
  fun run args =
    let
      val path =
        case ! path of
          SOME path => path
        | NONE => Path.projectRoot (OS.FileSys.getDir ()) / Path.manifest
      val {dependencies, supportedCompilers, ...} = Manifest.read path
    in
      List.app (Package.addToDeps (OS.Path.getParent path) o Package.fetch o Option.valOf o Package.fromString) dependencies
    end
end
