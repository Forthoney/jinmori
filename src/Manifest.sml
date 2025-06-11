structure Manifest =
struct
  exception MissingField of string

  type t = {package: {name: string, version: string}, dependencies: string list}

  fun default name =
    {package = {name = name, version = "0.1.0"}, dependencies = []}

  fun toJSON {package = {name, version}, dependencies} =
    let
      val _ = List.app print dependencies
    in
      JSON.OBJECT
        [ ( "package"
          , JSON.OBJECT
              [("name", JSON.STRING name), ("version", JSON.STRING version)]
          )
        , ("dependencies", JSON.ARRAY (map JSON.STRING dependencies))
        ]
    end


  fun findKey s =
    Option.compose (#2, List.find (fn (k, v) => k = s))

  fun package src =
    case findKey "package" src of
      SOME (JSON.OBJECT pkg) =>
        (case findKey "name" pkg of
           SOME (JSON.STRING name) =>
             (case findKey "version" pkg of
                SOME (JSON.STRING version) => {name = name, version = version}
              | _ => raise MissingField "version")
         | _ => raise MissingField "name")
    | _ => raise MissingField "package"

  fun dependencies src =
    case findKey "dependencies" src of
      SOME (deps as JSON.ARRAY _) => JSONUtil.arrayMap JSONUtil.asString deps
    | _ => raise MissingField "dependencies"

  fun read path =
    let
      val src = JSONParser.openFile path
    in
      case JSONParser.parse src before JSONParser.close src of
        JSON.OBJECT src =>
          {package = package src, dependencies = dependencies src}
      | _ => raise MissingField ""
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
