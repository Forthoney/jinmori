structure Scaffold =
struct
  fun write (path, content) =
    let val out = TextIO.openOut path
    in TextIO.output (out, content); TextIO.closeOut out
    end

  structure Filename =
  struct
    val main = "Main" ext "sml"
    fun mainMlb name = name ext "mlb"
    val test = "Test" ext "sml"
    fun testMlb name =
      (name ^ ".test") ext "mlb"
    val sources = "sources" ext "mlb"
  end

  fun main path =
    write (path / "src" / Filename.main, String.concatWith "\n"
      [ "val hello = \"Hello, \""
      , "val world = \"World!\""
      , "val greeting = hello ^ world ^ \"\\n\""
      , "val () = print " ^ "greeting"
      ])

  fun mainMlb name path =
    write (path / "src" / Filename.mainMlb name, String.concatWith "\n"
      [ "local"
      , "\t$(SML_LIB)/basis/basis.mlb"
      , "\t" ^ Filename.sources
      , "in"
      , Filename.main
      , "end"
      ])

  fun test path =
    write (path / "test" / Filename.test, String.concatWith "\n"
      [ "if true = false then"
      , "  raise Fail \"The fabric of reality crumbles...\""
      , "else"
      , "  ()"
      ])

  fun testMlb name path =
    write
      ( path / "test" / Filename.testMlb name
      , "../src" / Filename.sources ^ "\n" ^ Filename.test
      )

  fun sources path =
    write (path / "src" / Filename.sources, String.concatWith "\n"
      ["local", "\t$(SML_LIB)/basis/basis.mlb", "in", "end"])

  fun gitignore path =
    write (path / ".gitignore", "deps/\nbuild/")

  fun manifest name path =
    Manifest.write (path / Path.manifest, Manifest.default name)
end
