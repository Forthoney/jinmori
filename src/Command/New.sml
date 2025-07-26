structure New =
struct
  exception Create of string
  val bin = ref true 
  val name = ref ""

  fun writeFile (path, content) =
    let val out = TextIO.openOut path
    in TextIO.output (out, content); TextIO.closeOut out
    end
  fun validate s =
    Option.getOpt
      ( Option.compose
          ( fn (c, rest) =>
              Char.isAscii c andalso Char.isAlpha c
              andalso List.all Char.isAlphaNum (Substring.explode rest)
          , Substring.getc o Substring.full
          ) s
      , false
      )

  val touchFile = TextIO.closeOut o TextIO.openOut
  fun create {proj, main} =
    let
      val src = proj / "src"
      val tests = proj / "tests"
      val build = proj / "build"

      val srcMlb = src / ("sources.mlb")
      val mainSml = src / ("Main" ^ ".sml")
      val projMlb = src / (main ^ ".mlb")

      val testSml = tests / ("Test" ^ ".sml")
      val testsMlb = tests / (proj ^ ".test.mlb")

      val manifest = proj / Path.manifest
      val gitignore = proj / ".gitignore"
    in
      ( List.app OS.FileSys.mkDir [proj, src, tests, build]
      ; writeFile (mainSml, String.concatWith "\n"
          [ "structure " ^ main ^ ":"
          , "sig"
          , "  val greeting: string"
          , "end ="
          , "struct"
          , "  val hello = \"Hello, \""
          , "  val world = \"World!\""
          , "  val greeting = hello ^ world ^ \"\\n\""
          , "end"
          , "val () = print " ^ main ^ ".greeting"
          ])
      ; writeFile (testSml, String.concatWith "\n"
          [ "if true = false then"
          , "  raise Fail \"The fabric of reality crumbles...\""
          , "else"
          , "  ()"
          ])
      ; writeFile (srcMlb, String.concatWith "\n"
          [ "$(SML_LIB)/basis/basis.mlb"
          ])
      ; writeFile (projMlb, String.concatWith "\n" ["src.mlb", "Main.sml"])
      ; writeFile
          (testsMlb, String.concatWith "\n" ["../src/src.mlb", "Test.sml"])
      ; writeFile (gitignore, "lib/\nbuild/")
      ; Manifest.write (manifest, Manifest.default proj)
      )
      handle OS.SysErr (msg, _) => raise Create msg
    end

  structure Command =
    CommandFn
      (structure Parser = Parser_PrefixFn (val prefix = "--")
       type action = unit
       val desc = "Create a new SML project"
       val flags = [
        {usage = {name = "lib", desc = "Use a library template"}, arg = Argument.None (fn _ => bin := false)}
      ]
       val anonymous =
        Argument.One {action = fn arg => if validate arg then name := arg else raise Fail ("invalid project name: " ^ ! name),
        metavar = "PATH"}
      )

  fun run args =
    let
      val _ = Command.run args
    in
      create {proj = ! name, main = ! name}
    end
end
