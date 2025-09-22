structure Build =
struct
  val debug = ref true
  val additionalOpts = ref []
  val binary = ref ""
  val compiler = ref NONE
  val compilerPath = ref NONE

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
    val compiler =
      { usage = {name = "compiler", desc = "Specify compiler to build with"}
      , arg = Argument.One
          { action = fn s =>
              compiler
              :=
              SOME
                (Argument.asType'
                   {typeName = "Compiler.t", fromString = Compiler.fromString} s)
          , metavar = "SMLC"
          }
      }
    val compilerPath =
      { usage = {name = "compiler-path", desc = "Manually set the path to the compiler"}
      , arg = Argument.One { action = fn s => compilerPath := SOME s, metavar = "SMLC_PATH" }
      }
  in
    structure Command =
      CommandFn
        (structure Parser = Parser_PrefixFn(val prefix = "--")
         type action = unit
         val desc = "Build a Jinmori executable"
         val flags = [dbg, release, bin, compiler, compilerPath, Shared.verbosity ()]
         val anonymous = Argument.Any
           { action = fn flags => additionalOpts := flags
           , metavar = "COMPILER_FLAG"
           })
  end

  structure FS = OS.FileSys

  fun run args =
    let
      val _ = Command.run args
      val projectDir = Path.projectRoot (FS.getDir ())
      val {package = {name, ...}, dependencies, supportedCompilers} =
        Manifest.read (projectDir / Path.manifest)

      val selectedCompiler =
        case !compiler of
          SOME c =>
            if List.exists (fn c' => c = c') supportedCompilers then c
            else raise Fail "unsupported compiler"
        | NONE => List.hd supportedCompilers
      val entryPoint =
        case !binary of
          "" => projectDir / "src" / (name ^ ".mlb")
        | filename => projectDir / "src" / (filename ^ ".mlb")
      val buildDir = projectDir / "build"
      val _ =
        app
          (Package.addToDeps o Package.fetch o Option.valOf o Package.fromString)
          dependencies
      val _ = if FS.access (buildDir, []) then () else FS.mkDir buildDir
    in
      Compiler.compileWith selectedCompiler
        (! compilerPath)
        { entryPoint = entryPoint
        , output = buildDir / name
        , additional = !additionalOpts
        , debug = !debug
        }
    end
end
