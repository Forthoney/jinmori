structure New: COMMAND =
struct
  exception Name of string
  exception Create of string

  type config = {proj: string, main: string, mltonFlags: string}
  type parser = (string list * config) -> (string list * config)

  fun writeFile (path, content) =
    let val out = TextIO.openOut path
    in TextIO.output (out, content); TextIO.closeOut out
    end

  val touchFile = TextIO.closeOut o TextIO.openOut

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

  fun nameParser ([path], {proj, main, mltonFlags}) =
        if validate path then
          ([], {proj = path, main = path, mltonFlags = mltonFlags})
        else
          raise (Name path)
    | nameParser (_, _) =
        raise (Name "")

  val default =
    {proj = "", main = "", mltonFlags = "-mlb-path-var PKGS $JINMORI_HOME/pkgs"}
  val parseOrder = [nameParser]

  fun run {proj, main, mltonFlags} =
    let
      val src = proj / "src"
      val tests = proj / "tests"
      val bin = proj / "bin"

      val srcMlb = src / ("src.mlb")
      val mainSml = src / ("Main" ^ ".sml")
      val projMlb = src / (proj ^ ".mlb")

      val testSml = tests / ("Test" ^ ".sml")
      val testsMlb = tests / (proj ^ ".test.mlb")

      val makefile = proj / "Makefile"
      val manifest = proj / Path.manifest
      val gitignore = proj / ".gitignore"
    in
      ( List.app OS.FileSys.mkDir [proj, src, tests, bin]
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
          [ "(* $(PKGS)/github.com/author/pkgName *)"
          , "$(SML_LIB)/basis/basis.mlb"
          ])
      ; writeFile (projMlb, String.concatWith "\n" ["src.mlb", "Main.sml"])
      ; writeFile
          (testsMlb, String.concatWith "\n" ["../src/src.mlb", "Test.sml"])
      ; writeFile (makefile, String.concatWith "\n"
          [ "RELEASE := " ^ ("bin" / proj)
          , "DBG := " ^ ("bin" / (proj ^ ".dbg"))
          , "TESTER := " ^ ("bin" / "tester")
          , ""
          , "BUILD_FLAGS := " ^ mltonFlags
          , "DBG_FLAGS := -const 'Exn.keepHistory true'"
          , ""
          , "SOURCE := "
            ^ (String.concatWith " " ["src" / "*.sml", "src" / "*.mlb"])
          , "TESTS := "
            ^ (String.concatWith " " ["tests" / "*.sml", "tests" / "*.mlb"])
          , ""
          , "all: $(RELEASE) $(DBG) $(TESTER)"
          , ""
          , ".PHONY: test"
          , ""
          , "$(RELEASE): $(SOURCE)"
          , "\tmlton $(BUILD_FLAGS) -output $@ " ^ ("src" / proj ^ ".mlb")
          , ""
          , "$(DBG): $(SOURCE)"
          , "\tmlton $(BUILD_FLAGS) $(DBG_FLAGS) -output $@ "
            ^ ("src" / proj ^ ".mlb")
          , ""
          , "$(TESTER): $(SOURCE) $(TESTS)"
          , "\tmlton $(MLTON_FLAGS) $(DBG_FLAGS) -output $@ "
            ^ ("tests" / proj ^ ".test.mlb")
          , ""
          , "test: $(TESTER)"
          , "\t$(TESTER)"
          , ""
          , "clean:"
          , "\trm -f $(BIN)/*"
          , ""
          , "deps:"
          , "\tjinmori add -r " ^ Path.manifest
          ])
      ; writeFile (gitignore, "lib/\nbin/")
      ; touchFile manifest
      )
      handle OS.SysErr (msg, _) => raise Create msg
    end
end
