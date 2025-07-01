structure Package:
sig
  exception Destination of string
  exception NotFound
  exception Build

  type t

  val toString: t -> string
  val fromString: string -> t

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
  structure PFS = Posix.FileSys

  (* NONE indicates latest version *)
  type t = {source: string, version: string option}

  fun fromString s =
    let
      open Substring
      val (source, maybeTag) = splitr (fn c => c <> #"@") (full s)
    in
      if isEmpty source then {source = s, version = NONE}
      else {source = string (trimr 1 source), version = SOME (string maybeTag)}
    end

  fun toString {source, version} =
    case version of
      SOME v => source ^ "@" ^ v
    | NONE => source

  fun remove dest =
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
        , stderr = Param.pipe
        , stdin = Param.null
        , stdout = Param.pipe
        }
      val stdout = Child.textIn (getStdout lsRemote)
      val extractTag = string o trimr (String.size "\n") o triml (String.size "refs/tags/") o taker (fn c => c <> #"\t") o full
      val tag =
        Option.compose (extractTag, TextIO.inputLine o Child.textIn o getStdout) lsRemote
      val stderr = Child.textIn (getStderr lsRemote)
    in
      case (tag, reap lsRemote) of
        (SOME tag, Posix.Process.W_EXITED) => tag
      | _ => raise Fail "Failed to retrieve tag"
    end

  fun organize dest =
    let
      val projDir = Path.projectRoot (FS.getDir ())
      val depsDir = projDir / "deps"
      val _ = if FS.access (depsDir, []) then () else FS.mkDir depsDir
      val {package = {name, ...}, ...} = Manifest.read (dest / Path.manifest)
    in
      PFS.symlink {old = dest, new = depsDir / name}
    end

  fun download (git, tag, remoteAddr, dest) =
    let
      open MLton.Process
      val gitClone = create
        { path = git
        , args = ["clone", "--branch", tag, "--depth", "1", remoteAddr, dest]
        , env = NONE
        , stderr = Param.self
        , stdin = Param.null
        , stdout = Param.null
        }
    in
      case reap gitClone of
        Posix.Process.W_EXITED =>
          let
            val {package, dependencies} =
              Manifest.read (dest / Path.manifest)
              handle IO.Io {cause = OS.SysErr _, ...} =>
                (remove dest; raise Fail "Not a jinmori package")
          in
            List.app (fetch o fromString) dependencies
          end
      | _ => raise NotFound
    end
  and fetch {source, version} =
    let
      val remoteAddr = "https://" ^ source ^ ".git"
    in
      case Path.which "git" of
        NONE => raise Fail "git command not found in PATH"
      | SOME git =>
          let
            val tag =
              case version of
                SOME v => v
              | NONE => latestTag git remoteAddr
            val dest = OS.Path.concat (Path.allPkgs, source ^ "@" ^ tag)
            val _ =
              if FS.access (dest, []) then ()
              else download (git, tag, remoteAddr, dest)
          in
            organize dest
          end
    end
end
