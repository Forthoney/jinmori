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
      fun writeFile (path, content) =
        let val out = TextIO.openOut path
        in TextIO.output (out, content); TextIO.closeOut out
        end
      val touchFile = TextIO.closeOut o TextIO.openOut
      val src = path / "src"
      val tests = path / "tests"
      val build = path / "build"

      val srcMlb = src / ("sources.mlb")
      val mainSml = src / ("Main" ^ ".sml")
      val projMlb = src / (name ^ ".mlb")

      val testSml = tests / ("Test" ^ ".sml")
      val testsMlb = tests / (name ^ ".test.mlb")

      val manifest = path / Path.manifest
      val gitignore = path / ".gitignore"
      val _ =
        if bin then
          ( writeFile (projMlb, String.concatWith "\n" ["src.mlb", "Main.sml"])
          ; writeFile (mainSml, String.concatWith "\n"
              [ "val hello = \"Hello, \""
              , "val world = \"World!\""
              , "val greeting = hello ^ world ^ \"\\n\""
              , "val () = print " ^ "greeting"
              ])
          )
        else
          ()
    in
      ( List.app OS.FileSys.mkDir [path, src, tests, build]
      ; writeFile (testSml, String.concatWith "\n"
          [ "if true = false then"
          , "  raise Fail \"The fabric of reality crumbles...\""
          , "else"
          , "  ()"
          ])
      ; writeFile
          (srcMlb, String.concatWith "\n" ["$(SML_LIB)/basis/basis.mlb"])
      ; writeFile
          (testsMlb, String.concatWith "\n" ["../src/src.mlb", "Test.sml"])
      ; writeFile (gitignore, "lib/\nbuild/")
      ; Manifest.write (manifest, Manifest.default name)
      )
      handle OS.SysErr (msg, _) => raise Create msg
    end

  val bin = ref true
  val path = ref ""
  val pkgName = ref ""

  local
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
  in
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
  end

  fun run args =
    (Command.run args; create {bin = !bin, path = !path, name = !pkgName})
end
