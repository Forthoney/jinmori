structure Build =
struct
  val debug = ref true
  val additionalOpts = ref []
  val binary = ref ""

  local
    val dbg =
      { usage =
          { name = "debug"
          , desc =
              "Build with debug mode, with stack traces attached to uncaught exceptions"
          }
      , arg = Argument.None (fn _ => debug := true)
      }
    val release =
      { usage = {name = "release", desc = "Build with release mode"}
      , arg = Argument.None (fn _ => debug := false)
      }
    val bin =
      { usage = {name = "bin", desc = "Specify binary to build"}
      , arg = Argument.One {action = fn s => binary := s, metavar = "NAME"}
      }
  in
    structure Command =
      CommandFn
        (structure Parser = Parser_PrefixFn(val prefix = "--")
         type action = unit
         val desc = "Build a Jinmori executable"
         val flags = [dbg, release, bin, Shared.verbosity]
         val anonymous = Argument.Any
           { action = fn flags => additionalOpts := flags
           , metavar = "COMPILER_FLAG"
           })
  end

  structure MLton = CompileFn(Compiler.MLton)

  structure FS = OS.FileSys

  fun run args =
    let
      val _ = Command.run args
      val projectDir = Path.projectRoot (FS.getDir ())
      val {package = {name, ...}, dependencies} =
        Manifest.read (projectDir / Path.manifest)
      val _ = app (Package.addToDeps o Package.fetch o Package.fromString) dependencies
      val entryPoint =
        case ! binary of
          "" => projectDir / "src" / (name ^ ".mlb")
        | filename => projectDir / "src" / (filename ^ ".mlb")
      val buildDir = projectDir / "build"
      val _ = if FS.access (buildDir, []) then () else FS.mkDir buildDir
    in
      MLton.compile
        { entryPoint = entryPoint
        , output = buildDir / name
        , additional = !additionalOpts
        , debug = !debug
        }
    end
end
