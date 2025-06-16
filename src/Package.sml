structure Package:
sig
  exception Destination of string
  exception NotFound
  exception Build

  type t = {source: string, author: string, repo: string}

  val toString: t -> string
  val fromString: string -> t option

  (*!
   * Fetch the path to a package, downloading the package if necessary
   *)
  val fetch: t -> unit
end =
struct
  exception Destination of string
  exception NotFound
  exception Build

  structure FS = OS.FileSys
  structure Proc = OS.Process

  type t = {source: string, author: string, repo: string}

  fun fromString s =
    case String.tokens (fn c => c = #"/") s of
      [source, author, repo] =>
        SOME {source = source, author = author, repo = repo}
    | _ => NONE

  fun toString {source, author, repo} =
    String.concatWith "/" [source, author, repo]

  fun fetch {source, author, repo} =
    let
      val dest = Path.home / "pkgs" / source / author / repo
    in
      if FS.access (dest, []) then
        ()
      else
        let
          val addr =
            String.concatWith "/" ["https://" ^ source, author, repo ^ ".git"]
          val cloneCmd = String.concatWith " " ["git", "clone", addr, dest]
        in
          if Proc.isSuccess (Proc.system cloneCmd) then
            let
              val {package, dependencies} =
                Manifest.read (dest / "Jinmori.json")
              val dependencies =
                map (Option.valOf o fromString) dependencies
            in
              List.app fetch dependencies
            end
          else
            raise NotFound
        end
    end
end
