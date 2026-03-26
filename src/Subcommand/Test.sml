structure Test: SUBCOMMAND =
struct
  val additionalOpts = ref []
  val compiler = ref NONE
  val compilerPath = ref NONE

  local
    val compiler =
      { usage = {name = "compiler", desc = "Specify compiler to test with"}
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
         val desc = "Build and run project tests"
         val flags = [compiler, compilerPath, Shared.verbosity ()]
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
      val
        { package = {name, ...}
        , dependencies
        , supportedCompilers
        , ...
        } =
        Manifest.read (projectDir / Path.manifest)

      val selectedCompiler =
        case !compiler of
          SOME c =>
            if List.exists (fn c' => c = c') supportedCompilers then c
            else raise Fail "unsupported compiler"
        | NONE => List.hd supportedCompilers
      val entryPoint = projectDir / "test" / (name ^ ".tests.mlb")
      val buildDir = projectDir / "build"
      val output = buildDir / (name ^ "-tests")
      val executable = output ^ ".dbg"
      val _ =
        app
          (Package.addToDeps projectDir o Package.fetch o Option.valOf o Package.fromString)
          dependencies
      val _ = if FS.access (buildDir, []) then () else FS.mkDir buildDir
      val _ =
        Compiler.compileWith selectedCompiler
          (!compilerPath)
          { entryPoint = entryPoint
          , output = output
          , additional = !additionalOpts
          , debug = true
          }
      val status =
        OS.Process.system (concat ["\"", executable, "\""])
    in
      if OS.Process.isSuccess status then () else raise Fail "tests failed"
    end
end
