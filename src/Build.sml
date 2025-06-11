structure Build: COMMAND =
struct
  datatype mode = Debug | Release

  type config = mode
  type parser = (string list * config) -> (string list * config)

  fun parser ("--debug"::args, _) = (args, Debug)
    | parser ("--release"::args, _) = (args, Release)
    | parser ([], mode) = ([], mode)
    | parser _ = raise Fail "unknown arg"

  val parseOrder = [parser]

  val default = Debug

  fun run mode =
    let
      val cmd =
        case Path.projectRoot (OS.FileSys.getDir ()) of
          NONE => raise Path.ProjectRoot
        | SOME root => (
          case Path.home of
            NONE => raise Path.Home
          | SOME home =>
            let
              val main = root / "src" / "main.mlb"
              val output = root / "build"
              val _ = if OS.FileSys.access (output, []) then () else OS.FileSys.mkDir output
            in
              case mode of
                Debug => ["mlton",  "-output", output / "main.dbg", "-const 'Exn.keepHistory true'", main]
              | Release => ["mlton", "-output", output / "main", main]
            end
        )
    in
      if (OS.Process.isSuccess o OS.Process.system o String.concatWith " ") cmd then
        ()
      else
        raise Fail "Failed"
    end
end
