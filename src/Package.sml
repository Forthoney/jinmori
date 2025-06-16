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

  fun commitHash addr =
    let
      open MLton.Process
      open Substring
      val gitLs = create
        { path = "/bin/sh"
        , args = ["-c", String.concatWith " " ["git ls-remote", addr, "HEAD"]]
        , env = NONE
        , stderr = Param.self
        , stdin = Param.null
        , stdout = Param.pipe
        }
      val commitHash =
        Option.compose
          ( string o takel (fn c => c <> #"\t") o full
          , TextIO.inputLine o Child.textIn o getStdout
          ) gitLs
    in
      case (commitHash, reap gitLs) of
        (SOME hash, Posix.Process.W_EXITED) => hash
      | _ => raise Fail "Failed to retrieve commit hash"
    end

  fun unfetch dest =
    let
      open OS.FileSys
      fun recursiveRm strm =
        case readDir strm of
          SOME path =>
            ( if isDir path then (recursiveRm (openDir path); rmDir path)
              else remove path
            ; recursiveRm strm
            )
        | NONE => ()
    in
      recursiveRm (openDir dest)
    end

  fun fetch {source, author, repo} =
    let
      val remoteAddr =
        String.concatWith "/" ["https://" ^ source, author, repo ^ ".git"]
      val dest =
        Path.home / "pkg" / source / author
        / (repo ^ "-" ^ commitHash remoteAddr)
    in
      if FS.access (dest, []) then
        ()
      else
        let
          open MLton.Process
          val gitClone = create
            { path = "/bin/sh"
            , args =
                ["-c", String.concatWith " " ["git", "clone", remoteAddr, dest]]
            , env = NONE
            , stderr = Param.null
            , stdin = Param.null
            , stdout = Param.null
            }
        in
          case reap gitClone of
            Posix.Process.W_EXITED =>
              let
                val {package, dependencies} =
                  Manifest.read (dest / "Jinmori.json")
                  handle IO.Io {cause = OS.SysErr _, ...} =>
                    (unfetch dest; raise Fail "Not a jinmori package")
                val dependencies = map (Option.valOf o fromString) dependencies
              in
                List.app fetch dependencies
              end
          | _ => raise NotFound
        end
    end
end
