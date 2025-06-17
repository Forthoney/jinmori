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
  val fetchLatest: t -> unit
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

  fun latestTag gitCmd remoteAddr =
    let
      open MLton.Process
      open Substring
      val lsRemote = create
        { path = gitCmd
        , args = ["ls-remote", "--tags", "--sort=version:refname", remoteAddr]
        , env = NONE  
        , stderr = Param.null
        , stdin = Param.null
        , stdout = Param.pipe
        }
      val tag =
        Option.compose
          ( string o trimr (String.size "\n") o triml (String.size "refs/tags/") o taker (fn c => c <> #"\t") o full
          , TextIO.inputLine o Child.textIn o getStdout
          ) lsRemote
    in
      case (tag, reap lsRemote) of
        (SOME tag, Posix.Process.W_EXITED) => tag
      | _ => raise Fail "Failed to retrieve tag"
    end

  fun fetch gitCmd remoteAddr tag dest =
    if FS.access (dest, []) then
      ()
    else
      let
        open MLton.Process
        val gitClone = create
          { path = gitCmd
          , args =
              ["clone", "--branch", tag, "--depth", "1", remoteAddr, dest]
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
            in
              List.app (fetchLatest o Option.valOf o fromString) dependencies 
            end
        | _ => raise NotFound
      end
  and fetchLatest {source, author, repo} =
    let
      val remoteAddr =
        String.concatWith "/" ["https://" ^ source, author, repo ^ ".git"]
    in
      case Path.which "git" of
        NONE => raise Fail "git command not found in PATH"
      | SOME git =>
        let
          val tag = latestTag git remoteAddr
          val dest =
            Path.home / "pkg" / source / author / (repo ^ "-" ^ tag)
        in
          fetch git remoteAddr tag dest
        end
    end
end
