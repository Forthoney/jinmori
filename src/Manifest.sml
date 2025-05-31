structure Manifest = 
struct
  exception NExist
  exception Format

  structure Pkg = Package
  type t = {deps: Pkg.t list, self: Pkg.t}

  fun fromFile fileName =
    let
      val file = TextIO.openIn fileName handle Io => raise NExist
    in
      case TOML.parse file of 
        NONE => raise Format
      | SOME doc =>
        case (TOML.get "dependencies" doc, TOML.get "package" doc) of
          (SOME (TOML.Table deps), SOME (TOML.Table tbl)) => 
        | _ => raise Format
    end
end
