structure Install: SUBCOMMAND =
struct
  structure Command =
    CommandFn
      (structure Parser = Parser_PrefixFn(val prefix = "--")
       type action = Package.t list
       val desc = "Build and install a Jinmori binary"
       val flags = [Shared.verbosity []]
       val anonymous =
        Argument.Any {action = map Package.fromString, metavar = "PKG"})

  structure MLton = CompileFn(Compiler.MLton)

  structure FS = OS.FileSys
  
  fun run args =
    let
      val _ = Command.run args
      val [[], pkgs] = Command.run args
      fun install pkgPath =
        let
          val _ = Logger.info "installing package"
          val projectDir = Path.projectRoot pkgPath
          val {package = {name, ...}, dependencies} =
            Manifest.read (projectDir / Path.manifest)
          val entryPoint = projectDir / "src" / (name ^ ".mlb")
          val buildDir = Path.home () / "bin"
          val _ =
            if FS.access (buildDir, []) then Logger.debug "found build directory"
            else (Logger.debug "did not find build directory, creating one"; FS.mkDir buildDir)
        in
          MLton.compile
            { entryPoint = entryPoint
            , output = buildDir / name
            , additional = []
            , debug = false
            }
        end
    in
      List.app (install o Package.fetch) pkgs
    end
end
