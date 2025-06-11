structure New: COMMAND =
struct
  exception Name of string
  exception Create of string

  type config = {proj: string, main: string, mltonFlags: string}
  type parser = (string list * config) -> (string list * config)

  val shortHelp = "Create a new SML project"

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
      val build = proj / "build"

      val srcMlb = src / ("src.mlb")
      val mainSml = src / ("Main" ^ ".sml")
      val projMlb = src / ("main.mlb")

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
          [ "(* $(PKGS)/github.com/author/pkgName *)"
          , "$(SML_LIB)/basis/basis.mlb"
          ])
      ; writeFile (projMlb, String.concatWith "\n" ["src.mlb", "Main.sml"])
      ; writeFile
          (testsMlb, String.concatWith "\n" ["../src/src.mlb", "Test.sml"])
      ; writeFile (gitignore, "lib/\nbuild/")
      ; Manifest.write (manifest, Manifest.default proj)
      )
      handle OS.SysErr (msg, _) => raise Create msg
    end
end
