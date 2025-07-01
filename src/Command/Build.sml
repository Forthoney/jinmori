structure Build: COMMAND =
struct
  datatype mode = Debug | Release

  type config = mode
  type parser = (string list * config) -> (string list * config)

  val shortHelp = "Build a Jinmori executable"

  fun parser ("--debug" :: args, _) = (args, Debug)
    | parser ("--release" :: args, _) = (args, Release)
    | parser ([], mode) = ([], mode)
    | parser _ = raise Fail "unknown arg"

  val parseOrder = [parser]

  val default = Debug

  structure FS = OS.FileSys

  fun run mode =
    let
      val projectDir = Path.projectRoot (FS.getDir ())
      val {package = {name, ...}, dependencies} = Manifest.read (projectDir / Path.manifest)
      val main = projectDir / "src" / (name ^ ".mlb")
      val output = projectDir / "build"
      fun mltonArgs {ext, options} =
        [ "-output"
        , output / (name ^ ext)
        ] @ options @ [main]
        handle IO.Io {cause = OS.SysErr _, ...} =>
          raise Fail "Not a Jinmori project"
    in
      case Path.which "mlton" of
        NONE => raise Fail "mlton command was not found in PATH"
      | SOME mlton =>
        let
          val _ = if FS.access (output, []) then () else FS.mkDir output
          val args =
            case mode of
              Debug =>
                mltonArgs
                  {ext = ".dbg", options = ["-const", "'Exn.keepHistory true'"]}
            | Release => mltonArgs {ext = "", options = []}
          open MLton.Process
          val mlton = create
            { path = mlton
            , args = args 
            , env = NONE
            , stderr = Param.pipe
            , stdin = Param.null
            , stdout = Param.self
            }
          val stderr = Child.textIn (getStderr mlton)
        in
          case reap mlton of
            Posix.Process.W_EXITED => ()
          | _ => raise Fail "Build Failed"
        end
    end
end
