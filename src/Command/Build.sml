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

  fun mltonArgs {extension, options} =
    [ "mlton"
    , "-mlb-path-var 'JINMORI_LIB " ^ Path.home ^ "pkg" ^ "'"
    , "-output"
    , output / (#name package ^ extension)
    ] @ options @ [main]

  fun run mode =
    let
      val root = Path.projectRoot (FS.getDir ())
      val main = root / "src" / "main.mlb"
      val output = root / "build"
      val {package, dependencies} = Manifest.read (root / Path.manifest)
      handle IO.Io {cause=OS.SysErr _, ...} => Fail "Not a Jinmori project"
      val _ =
        if FS.access (output, []) then () else FS.mkDir output
      val cmd =
        case mode of
          Debug => mltonArgs {extention=".dbg", options=["-const 'Exn.keepHistory true'"]}
        | Release => cmdArgs {extention="", options=[]}
    in
      if (OS.Process.isSuccess o OS.Process.system o String.concatWith " ") cmd then
        ()
      else
        raise Fail "Build Failed"
    end
end
