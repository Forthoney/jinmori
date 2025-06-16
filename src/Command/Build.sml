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

  fun run mode =
    let
      val root = Path.projectRoot (OS.FileSys.getDir ())
      val {package, dependencies} = Manifest.read (root / Path.manifest)
      val main = root / "src" / "main.mlb"
      val output = root / "build"
      val _ =
        if OS.FileSys.access (output, []) then () else OS.FileSys.mkDir output
      fun cmdArgs extension options =
        [ "mlton"
        , "-mlb-path-var 'JINMORI_LIB " ^ Path.home ^ "pkg" ^ "'"
        , "-output"
        , output / (#name package ^ extension)
        ] @ options @ [main]
      val cmd =
        case mode of
          Debug => cmdArgs ".dbg" ["-const 'Exn.keepHistory true'"]
        | Release => cmdArgs "" []
    in
      if (OS.Process.isSuccess o OS.Process.system o String.concatWith " ") cmd then
        ()
      else
        raise Fail "Build Failed"
    end
end
