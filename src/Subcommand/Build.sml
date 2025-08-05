structure Build =
struct
  exception Compile of string

  val debugMode = ref true
  val compilerFlags = ref []

  local
    val debug =
      { usage =
          { name = "debug"
          , desc =
              "Build with debug mode, with stack traces attached to uncaught exceptions"
          }
      , arg = Argument.None (fn _ => debugMode := true)
      }
    val release =
      { usage = {name = "release", desc = "Build with release mode"}
      , arg = Argument.None (fn _ => debugMode := false)
      }
  in
    structure Command =
      CommandFn
        (structure Parser = Parser_PrefixFn(val prefix = "--")
         type action = unit
         val desc = "Build a Jinmori executable"
         val flags = [debug, release]
         val anonymous = Argument.Any
           { action = fn flags => compilerFlags := flags
           , metavar = "COMPILER_FLAG"
           })
  end
  structure FS = OS.FileSys

  fun run args =
    let
      val _ = Command.run args
      val projectDir = Path.projectRoot (FS.getDir ())
      val {package = {name, ...}, dependencies} =
        Manifest.read (projectDir / Path.manifest)
      val main = projectDir / "src" / (name ^ ".mlb")
      val output = projectDir / "build"
      fun mltonArgs {ext, options} =
        ["-output", output / (name ^ ext)] @ options @ !compilerFlags @ [main]
        handle IO.Io {cause = OS.SysErr _, ...} =>
          raise Fail "Not a Jinmori project"
      val mlton = Path.which "mlton"
      val _ = if FS.access (output, []) then () else FS.mkDir output
      val args =
        if !debugMode then
          mltonArgs
            {ext = ".dbg", options = ["-const", "'Exn.keepHistory true'"]}
        else
          mltonArgs {ext = "", options = []}
      open MLton.Process
      val mlton = create
        { path = mlton
        , args = args
        , env = NONE
        , stderr = Param.pipe
        , stdin = Param.null
        , stdout = Param.self
        }
      val stderr =
        let
          val strm = Child.textIn (getStderr mlton)
          fun loop () =
            case TextIO.inputLine strm of
              SOME s => s ^ loop ()
            | NONE => ""
        in
          loop ()
        end
    in
      case reap mlton of
        Posix.Process.W_EXITED => ()
      | _ => raise Compile stderr
    end
end
