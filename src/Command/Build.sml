structure Build: COMMAND =
struct
  datatype mode = Debug | Release

  type config = mode
  type parser = (string list * config) -> (string list * config)

  fun parser ("--debug" :: args, _) = (args, Debug)
    | parser ("--release" :: args, _) = (args, Release)
    | parser ([], mode) = ([], mode)
    | parser _ = raise Fail "unknown arg"

  val parseOrder = [parser]

  val default = Debug

  fun run mode =
    let
      val (root, home) =
        case Path.projectRoot (OS.FileSys.getDir ()) of
          NONE => raise Path.ProjectRoot
        | SOME root =>
            (case Path.home of
               NONE => raise Path.Home
             | SOME home => (root, home))
      val {package, dependencies} = Manifest.read (root / Path.manifest)
      val main = root / "src" / "main.mlb"
      val output = root / "build"
      val _ =
        if OS.FileSys.access (output, []) then () else OS.FileSys.mkDir output
      val cmd =
        case mode of
          Debug =>
            [ "mlton"
            , "-output"
            , output / (#name package ^ ".dbg")
            , "-const 'Exn.keepHistory true'"
            , main
            ]
        | Release => ["mlton", "-output", output / #name package, main]
    in
      if (OS.Process.isSuccess o OS.Process.system o String.concatWith " ") cmd then
        ()
      else
        raise Fail "Build Failed"
    end
end
