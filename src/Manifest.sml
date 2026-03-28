structure Manifest: MANIFEST =
struct
  exception MissingField of string
  type t =
    { package: {name: string, version: string}
    , description: string
    , license: string
    , repository: string
    , supportedCompilers: Compiler.t list
    , dependencies: string list
    }

  fun default name =
    { package = {name = name, version = "0.1.0"}
    , description = ""
    , license = "UNLICENSED"
    , repository = ""
    , supportedCompilers = [Compiler.MLTON]
    , dependencies = []
    }

  fun toJSON
    { package = {name, version}
    , description
    , license
    , repository
    , supportedCompilers
    , dependencies
    } =
    JSON.OBJECT
      [ ( "package"
        , JSON.OBJECT
            [("name", JSON.STRING name), ("version", JSON.STRING version)]
        )
      , ("description", JSON.STRING description)
      , ("license", JSON.STRING license)
      , ("repository", JSON.STRING repository)
      , ( "supportedCompilers"
        , JSON.ARRAY (map (JSON.STRING o Compiler.toString) supportedCompilers)
        )
      , ("dependencies", JSON.ARRAY (map JSON.STRING dependencies))
      ]

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

  fun supportedCompilers src =
    let
      fun toCompiler c = 
        case Compiler.fromString c of
          SOME c => c
        | NONE => raise Fail ("unknown compiler name " ^ c)
    in
      case findKey "supportedCompilers" src of
        SOME (cs as JSON.ARRAY _) => JSONUtil.arrayMap (toCompiler o JSONUtil.asString) cs
      | _ => raise MissingField "supportedCompilers"
    end

  fun dependencies src =
    case findKey "dependencies" src of
      SOME (deps as JSON.ARRAY _) => JSONUtil.arrayMap JSONUtil.asString deps
    | _ => raise MissingField "dependencies"

  fun optionalString key defaultValue src =
    case findKey key src of
      SOME (JSON.STRING s) => s
    | _ => defaultValue

  fun read path =
    case JSONParser.parseFile path of
      JSON.OBJECT src =>
        { package = package src
        , description = optionalString "description" "" src
        , license = optionalString "license" "UNLICENSED" src
        , repository = optionalString "repository" "" src
        , dependencies = dependencies src
        , supportedCompilers = supportedCompilers src
        }
    | _ => raise MissingField ""

  fun write (path, metadata) =
    let
      val out = TextIO.openOut path
      val manifest = toJSON metadata
      val _ = JSONPrinter.print' {strm = out, pretty = true} manifest
    in
      TextIO.closeOut out
    end
end
