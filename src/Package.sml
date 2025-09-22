structure Package: PACKAGE =
struct
  type t = {source: string, version: string}

  exception NotFound of t
  exception Tag of {remote: string, stderr: string}

  structure FS = OS.FileSys
  structure PFS = Posix.FileSys

  fun selectTag gitCmd remoteAddr =
    let
      open MLton.Process
      open Substring
      val _ = Logger.info ("git ls-remote repo at " ^ remoteAddr)
      val lsRemote = create
        { path = gitCmd
        , args = ["ls-remote", "--tags", "--sort=version:refname", remoteAddr]
        , env = NONE
        , stderr = Param.pipe
        , stdin = Param.null
        , stdout = Param.pipe
        }
      val tags =
        let
          fun loop () =
            case (TextIO.inputLine o Child.textIn o getStdout) lsRemote of
              SOME line => line :: (loop ())
            | NONE => []
          val extractTag =
            string o trimr (String.size "\n") o triml (String.size "refs/tags/")
            o taker (fn c => c <> #"\t") o full
        in
          map extractTag (loop ())
        end

      fun getSelection () =
        let
          val _ = print
            ("Available versions:\n" ^ String.concatWith "\n" tags ^ "\n"
             ^ "Select tag: ")
        in
          case TextIO.inputLine TextIO.stdIn of
            NONE =>
              ( Logger.info "No tag selected. Aborting"
              ; OS.Process.exit OS.Process.success
              ; ""
              )
          | SOME response =>
              let
                val tag =
                  (Substring.string o trimr (String.size "\n") o Substring.full)
                    response
                val _ = Logger.debug ("selected tag: " ^ String.toString tag)
              in
                case List.find (fn t => t = tag) tags of
                  SOME t => t
                | NONE =>
                    ( print
                        "Invalid tag. Please select amongst available options.\n"
                    ; getSelection ()
                    )
              end
        end

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
      case (tags, reap lsRemote) of
        ([], Posix.Process.W_EXITED) => raise Fail "No tags found"
      | (tags, Posix.Process.W_EXITED) => getSelection ()
      | _ => raise Tag {remote = remoteAddr, stderr = stderr}
    end

  fun normalizeRemote remote =
    let
      val l =
        if String.isPrefix "https://" remote then String.size "https://" else 0
      val r =
        if String.isSuffix "@" remote then String.size remote - String.size "@"
        else String.size remote
      val r =
        if String.isSuffix ".git" remote then r - String.size ".git" else r
    in
      String.substring (remote, l, r - l)
    end

  fun fromStringInteractive s =
    let
      open Substring
      val (l, r) = splitr (fn c => c <> #"@") (full s)
    in
      case (string l, string r) of
        (_, "") => NONE
      | ("", source) =>
          let
            val source = normalizeRemote source
            val tag = selectTag (Path.which "git") source
          in
            SOME {source = source, version = tag}
          end
      | (source, tag) => SOME {source = normalizeRemote source, version = tag}
    end

  fun fromString s =
    let
      open Substring
      val (l, r) = splitr (fn c => c <> #"@") (full s)
    in
      case (string l, string r) of
        ("", _) => NONE
      | (source, tag) => SOME {source = normalizeRemote source, version = tag}
    end

  fun toString {source, version} = source ^ "@" ^ version

  fun toURL ({source, ...}: t) = "https://" ^ source ^ ".git"

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

  fun addToDeps dest =
    let
      val projDir = Path.projectRoot (FS.getDir ())
      val depsDir = projDir / "deps"
      val _ = if FS.access (depsDir, []) then () else FS.mkDir depsDir
      val {package = {name, ...}, ...} = Manifest.read (dest / Path.manifest)
      val to = depsDir / name
      val _ = Logger.debug ("symlinking " ^ dest ^ " to " ^ to)
    in
      PFS.symlink {old = dest, new = to}
      handle OS.SysErr (msg, SOME e) =>
        if e = Posix.Error.exist then
          let
            val oldDest = PFS.readlink (depsDir / name)
          in
            if oldDest = dest then
              ()
            else
              ( Logger.debug
                  ("existing link found to " ^ oldDest ^ ". relinking")
              ; PFS.unlink to
              ; PFS.symlink {old = dest, new = to}
              )
          end
        else
          raise Fail ("Failed to symlink " ^ dest ^ " with error: " ^ msg)
    end

  fun fetch (pkg as {source, version}) =
    let
      val _ = Logger.info ("fetching package " ^ toString pkg)
      fun download (git, tag, dest) =
        let
          open MLton.Process
          val url = toURL pkg
          val _ = Logger.info ("git cloning repo at " ^ url)
          val gitClone = create
            { path = git
            , args = ["clone", "--branch", tag, "--depth", "1", url, dest]
            , env = NONE
            , stderr = Param.null
            , stdin = Param.null
            , stdout = Param.null
            }
        in
          case reap gitClone of
            Posix.Process.W_EXITED =>
              let
                val {package, dependencies, ...} =
                  Manifest.read (dest / Path.manifest)
                  handle IO.Io {cause = OS.SysErr _, ...} =>
                    (remove dest; raise Fail "Not a jinmori package")
                val _ = Logger.debug
                  ("found dependencies " ^ String.concatWith "," dependencies)
              in
                List.app (ignore o fetch o Option.valOf o fromString)
                  dependencies
              end
          | _ => raise NotFound pkg
        end
      val dest = OS.Path.concat (Path.home () / "pkg", source ^ "@" ^ version)
      val _ =
        if FS.access (dest, []) then
          Logger.debug ("repo found locally at " ^ dest)
        else
          ( Logger.debug ("repo not found locally at " ^ dest)
          ; download (Path.which "git", version, dest)
          )
    in
      dest
    end
end
