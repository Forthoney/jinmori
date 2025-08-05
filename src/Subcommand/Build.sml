structure Build =
struct
  val debug = ref true
  val additionalOpts = ref []

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
  in
    structure Command =
      CommandFn
        (structure Parser = Parser_PrefixFn(val prefix = "--")
         type action = unit
         val desc = "Build a Jinmori executable"
         val flags = [dbg, release]
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
      val entryPoint = projectDir / "src" / (name ^ ".mlb")
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
