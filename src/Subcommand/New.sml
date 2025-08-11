structure New: SUBCOMMAND =
struct
  exception Create of string

  fun validate s =
    case Substring.getc (Substring.full s) of
      NONE => false
    | SOME (c, rest) =>
        Char.isAscii c andalso Char.isAlpha c
        andalso List.all Char.isAlphaNum (Substring.explode rest)

  fun create {bin, path, name} =
    let
      val _ = List.app OS.FileSys.mkDir [path, path / "src", path / "test"]
      val _ =
        if bin then
          ( OS.FileSys.mkDir (path / "build")
          ; Scaffold.mainMlb name path
          ; Scaffold.main path
          )
        else
          ()
    in
      ( Scaffold.test path
      ; Scaffold.sources path
      ; Scaffold.testMlb name path
      ; Scaffold.gitignore path
      ; Scaffold.manifest name path
      )
      handle OS.SysErr (msg, _) => raise Create msg
    end

  val bin = ref true
  val path = ref ""
  val pkgName = ref ""

  val lib =
    { usage = {name = "lib", desc = "Use a library template"}
    , arg = Argument.None (fn _ => bin := false)
    }
  val name =
    { usage =
        { name = "name"
        , desc =
            "Set the resulting package name, defaults to the directory name"
        }
    , arg = Argument.One
        { action = fn s =>
            pkgName
            :=
            Argument.satisfies "Expected valid SML structure name" validate s
        , metavar = "NAME"
        }
    }
  structure Command =
    CommandFn
      (structure Parser = Parser_PrefixFn(val prefix = "--")
       type action = unit
       val desc = "Create a new SML project"
       val flags = [lib, name]
       val anonymous = Argument.One
         { action = fn s =>
             case (!pkgName, (rev o #arcs o OS.Path.fromString) s) of
               ("", name' :: _) =>
                 ( pkgName
                   :=
                   Argument.satisfies "Expected valid SML structure name"
                     validate name'
                 ; path := s
                 )
             | ("", _) => raise Fail ("Invalid path: " ^ s)
             | _ => path := s
         , metavar = "PATH"
         })

  fun run args =
    (Command.run args; create {bin = !bin, path = !path, name = !pkgName})
end
