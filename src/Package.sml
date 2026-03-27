structure Package: PACKAGE =
struct
  datatype source = S of string
  datatype remote = R of string
  
  type t = {source: source, version: string}
  (* the path of the installed package *)
  type installed = string

  exception NotFound of t
  exception Tag of {remote: string, stderr: string}

  structure FS = OS.FileSys
  structure PFS = Posix.FileSys

  fun selectTag gitCmd (R remoteAddr) =
    let
      open MLton.Process
      open Substring
      open Combinators.Base

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

      val op>>= = Combinators.Monadic.Option.>>=
      fun getSelection () =
        ( print (String.concatWith "\n" (("Available versions at " ^ remoteAddr ^ ":") :: tags))
        ; print "\nSelect tag: "
        ; TextIO.inputLine TextIO.stdIn
          |> Option.map (string o trimr (String.size "\n") o full)          
          >>= Option.filter (fn tag => List.exists (fn t => t = tag) tags)
          |> (fn SOME t => t
               | NONE =>
                 ( print "Invalid tag. Please select amongst available options.\n"
                 ; getSelection ()
                 ))
        )

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

  fun normalizeSource s =
    let
      open Substring
      open Combinators.Base
      val s =
        Option.filter (isPrefix "https://") s
        |> Option.map (triml (String.size "https://"))
        |> (fn s' => Option.getOpt (s', s))
      val s =
        Option.filter (isSuffix "@") s
        |> Option.map (trimr (String.size "@"))
        |> (fn s' => Option.getOpt (s', s))
      val s =
        Option.filter (isSuffix ".git") s
        |> Option.map (trimr (String.size ".git"))
        |> (fn s' => Option.getOpt (s', s))
        |> string
    in
      S s
    end

  fun toRemote (S s) = R ("https://" ^ s ^ ".git")

  fun fromStringInteractive s =
    let
      open Substring
      val (l, r) = splitr (fn c => c <> #"@") (full s)
    in
      if isEmpty r then NONE
      else if isEmpty l then
        let
          val source = normalizeSource r
          val tag = selectTag (Path.which "git") (toRemote source)
        in
          SOME {source = source, version = tag}
        end
      else
        SOME {source = normalizeSource l, version = string r}
    end

  fun fromString s =
    let
      open Substring
      open Combinators.Base
      val (l, r) = splitr (fn c => c <> #"@") (full s)
    in
      if isEmpty l orelse isEmpty r orelse not (isSuffix "@" l) then NONE
      else
        let
          val source = trimr (String.size "@") l
        in
          if isEmpty source then NONE
          else SOME {source = normalizeSource source, version = (string r)}
        end
    end

  fun toString {source = S s, version} = s ^ "@" ^ version

  fun toURL ({source = S s, ...}: t) = "https://" ^ s ^ ".git"

  fun remove dest =
    let
      open OS.FileSys
      open Combinators.Base

      fun recursiveRm strm =
        readDir strm
        |> Option.app 
          (fn path => 
            ( if isDir path then (recursiveRm (openDir path); rmDir path)
              else remove path
            ; recursiveRm strm
            ))
    in
      recursiveRm (openDir dest)
    end

  fun addToDeps projDir target =
    let
      val depsDir = projDir / "deps"
      val _ = if FS.access (depsDir, []) then () else FS.mkDir depsDir
      val {package = {name, ...}, ...} = Manifest.read (target / Path.manifest)
      val to = depsDir / name
      val _ = Logger.debug ("symlinking " ^ target ^ " to " ^ to)
    in
      PFS.symlink {old = target , new = to}
      handle OS.SysErr (msg, SOME e) =>
        if e = Posix.Error.exist then
          let
            val oldDest = PFS.readlink (depsDir / name)
          in
            if oldDest = target then ()
            else
              ( Logger.debug
                  ("existing link found to " ^ oldDest ^ ". relinking")
              ; PFS.unlink to
              ; PFS.symlink {old = target, new = to}
              )
          end
        else
          raise Fail ("Failed to symlink " ^ target ^ " with error: " ^ msg)
    end

  fun fetch (pkg as {source = S source, version}) =
    let
      val _ = Logger.info ("fetching package " ^ toString pkg)
      fun validate {supportedCompilers = depCompilers, ...} =
        let
          val cwd = OS.FileSys.getDir ()
          val {supportedCompilers = projCompilers, ...} = 
            Manifest.read (Path.projectRoot cwd / Path.manifest)
        in
          List.exists (fn c => List.exists (fn d => c = d) depCompilers) projCompilers
        end
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
          if reap gitClone <> Posix.Process.W_EXITED then 
            raise NotFound pkg
          else
            let
              val manifest as {dependencies, ...} = 
                Manifest.read (dest / Path.manifest)
                handle IO.Io {cause = OS.SysErr _, ...} => (remove dest; raise Fail "Not a jinmori pacage")
            in
              if validate manifest then ()
              else
                  raise Fail "Dependency compiler support does not overlap with project. Aborting.";
              Logger.debug ("found dependencies " ^ String.concatWith "," dependencies);
              List.app (ignore o fetch o Option.valOf o fromString) dependencies
            end
        end
      val dest = OS.Path.concat (Path.home () / "pkg", source ^ "@" ^ version)
    in
      if FS.access (dest, []) then
        let
          val manifest = Manifest.read (dest / Path.manifest)
        in
          if validate manifest then 
            Logger.debug ("repo found locally at " ^ dest)
          else
            raise Fail "Dependency compiler support does not overlap with project. Aborting."
        end
      else
        ( Logger.debug ("repo not found locally at " ^ dest)
        ; download (Path.which "git", version, dest)
        );
      dest
    end
end
