structure Package:
sig
  type t
  exception NotFound of t
  exception Tag of {remote: string, stderr: string}

  val toString: t -> string
  val fromString: string -> t

  (* Fetch a package, downloading the package if necessary
     Returns the path to the package's root directory *)
  val fetch: t -> string

  (* Adds a package at the provided path as a dependency for the current project *)
  val addToDeps: string -> unit
end =
struct
  (* NONE indicates latest version *)
  type t = {source: string, version: string option}
  exception NotFound of t
  exception Tag of {remote: string, stderr: string}

  structure FS = OS.FileSys
  structure PFS = Posix.FileSys

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
      val extractTag =
        string o trimr (String.size "\n") o triml (String.size "refs/tags/")
        o taker (fn c => c <> #"\t") o full
      val tag =
        Option.compose (extractTag, TextIO.inputLine o Child.textIn o getStdout)
          lsRemote
      val stderr =
        let
          val strm = Child.textIn (getStderr lsRemote)
          fun loop () =
            case TextIO.inputLine strm of
              SOME s => s ^ loop ()
            | NONE => ""
        in
          loop ()
        end
    in
      case (tag, reap lsRemote) of
        (SOME tag, Posix.Process.W_EXITED) => tag
      | _ => raise Tag {remote = remoteAddr, stderr = stderr}
    end

  fun addToDeps dest =
    let
      val projDir = Path.projectRoot (FS.getDir ())
      val depsDir = projDir / "deps"
      val _ = if FS.access (depsDir, []) then () else FS.mkDir depsDir
      val {package = {name, ...}, ...} = Manifest.read (dest / Path.manifest)
      val to = depsDir / name
    in
      PFS.symlink {old = dest, new = to}
      handle OS.SysErr (msg, SOME e) =>
        if e = Posix.Error.exist then
          if PFS.readlink (depsDir / name) = dest then ()
          else (PFS.unlink to; PFS.symlink {old = dest, new = to})
        else
          raise Fail ("Failed to symlink " ^ dest ^ " with error: " ^ msg)
    end

  fun fetch (pkg as {source, version}) =
    let
      val remoteAddr = "https://" ^ source ^ ".git"
      fun download (git, tag, dest) =
        let
          open MLton.Process
          val gitClone = create
            { path = git
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
                  Manifest.read (dest / Path.manifest)
                  handle IO.Io {cause = OS.SysErr _, ...} =>
                    (remove dest; raise Fail "Not a jinmori package")
              in
                List.app (ignore o fetch o fromString) dependencies
              end
          | _ => raise NotFound pkg
        end
      val git = Path.which "git"
      val tag =
        case version of
          SOME v => v
        | NONE => latestTag git remoteAddr
      val dest = OS.Path.concat (Path.home () / "pkg", source ^ "@" ^ tag)
      val _ = if FS.access (dest, []) then () else download (git, tag, dest)
    in
      dest
    end
end
