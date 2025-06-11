structure Manifest =
struct
  exception Format

  type t = {
    package: {name: string, version: string},
    dependencies: string list
  }

  fun default name = {
    package = { name = name, version = "0.1.0"},
    dependencies = []
  }

  fun toJSON {package = {name, version}, dependencies} =
    JSON.OBJECT [
      ("package", JSON.OBJECT [
        ("name", JSON.STRING name),
        ("version", JSON.STRING version)
      ]),
      ("dependencies", JSON.ARRAY (map JSON.STRING dependencies))
    ]
  

  fun findKey s =
    List.find (fn (k, v) => k = s)

  fun package src =
    case findKey "package" src of
      SOME (_, JSON.OBJECT pkgDetails) => (
        case (findKey "name" pkgDetails, findKey "version" pkgDetails)  of
          (SOME (_, JSON.STRING name), SOME (_, JSON.STRING ver)) => SOME {name=name, version=ver}
        | _ => NONE
      )
    | _ => NONE

  fun dependencies src =
    case findKey "dependencies" src of
      SOME (_, JSON.ARRAY deps) =>
      let
        val rec validate =
          fn (JSON.STRING s::rest) => (
          case validate rest of
            NONE => NONE
          | SOME l => SOME (s::l)
          )
           | (_::rest) => NONE
           | [] => SOME []
      in
        validate deps
      end
    | _ => NONE
    

  fun read path =
    let
      val src = JSONParser.openFile path
    in
      case JSONParser.parse src before JSONParser.close src of
        JSON.OBJECT src => 
        (case (package src, dependencies src) of
            (SOME pkg, SOME deps) => {package=pkg, dependencies=deps}
          | _ => raise Format)
      | _ => raise Format
    end

  fun write (path, metadata) =
    let
      val out = TextIO.openOut path
      val manifest = toJSON metadata
      val _ = JSONPrinter.print' {strm=out, pretty=true} manifest
    in
      TextIO.closeOut out
    end
end
