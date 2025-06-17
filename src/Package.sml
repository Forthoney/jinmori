structure Package:
sig
  exception Destination of string
  exception NotFound
  exception Build

  type t

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

  type t =
    {source: string, author: string, repo: string, version: string option}

  fun fromString s =
    case String.tokens (fn c => c = #"/") s of
      [source, author, repo] =>
        let
          val (repo', maybeTag) =
            Substring.splitr (fn c => c <> #"@") (Substring.full repo)
          val (repo, version) =
            if Substring.isEmpty maybeTag then (repo, NONE)
            else (Substring.string (Substring.trimr 1 repo'), SOME (Substring.string maybeTag))
        in
          SOME
            {source = source, author = author, repo = repo, version = version}
        end
    | _ => NONE

  fun toString {source, author, repo, version} =
    let
      val version =
        case version of
          SOME v => "@" ^ v
        | NONE => ""
    in
      String.concatWith "/" [source, author, repo] ^ version
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
          ( string o trimr (String.size "\n") o triml (String.size "refs/tags/")
            o taker (fn c => c <> #"\t") o full
          , TextIO.inputLine o Child.textIn o getStdout
          ) lsRemote
    in
      case (tag, reap lsRemote) of
        (SOME tag, Posix.Process.W_EXITED) => tag
      | _ => raise Fail "Failed to retrieve tag"
    end

  fun fetch {source, author, repo, version} =
    let
      val remoteAddr =
        String.concatWith "/" ["https://" ^ source, author, repo ^ ".git"]
    in
      case Path.which "git" of
        NONE => raise Fail "git command not found in PATH"
      | SOME git =>
          let
            val tag =
              case version of
                SOME v => v
              | NONE => latestTag git remoteAddr
            val dest = Path.home / "pkg" / source / author / (repo ^ "-" ^ tag)
          in
            if FS.access (dest, []) then
              ()
            else
              let
                open MLton.Process
                val gitClone = create
                  { path = git
                  , args =
                      [ "clone"
                      , "--branch"
                      , tag
                      , "--depth"
                      , "1"
                      , remoteAddr
                      , dest
                      ]
                  , env = NONE
                  , stderr = Param.self
                  , stdin = Param.null
                  , stdout = Param.null
                  }
              (* val errMsg = *)
              (* TextIO.inputAll o Child.textIn o getStdout gitClone *)
              in
                case reap gitClone of
                  Posix.Process.W_EXITED =>
                    let
                      val {package, dependencies} =
                        Manifest.read (dest / "Jinmori.json")
                        handle IO.Io {cause = OS.SysErr _, ...} =>
                          (unfetch dest; raise Fail "Not a jinmori package")
                    in
                      List.app (fetch o Option.valOf o fromString) dependencies
                    end
                | _ => raise NotFound
              end
          end
    end
end
