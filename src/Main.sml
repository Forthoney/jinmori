val cmdName = "jinmori"
val version = "0.1.0"
val break = ""

val _ =
  let
    fun err msg =
      ( TextIO.output (TextIO.stdErr, msg ^ "\n")
      ; OS.Process.exit OS.Process.failure
      )
  in
    (case CommandLine.arguments () of
       "add" :: args => Add.run args
     | "new" :: args => New.run args
     | "build" :: args => Build.run args
     | "--help" :: args => print "Available subcommands: add, new, build\n"
     | [] => print "Available subcommands: add, new, build\n"
     | unknown :: args => err ("Unknown subcommand: " ^ unknown ^ "\n"))
    handle
      Package.NotFound pkg =>
        err ("Package " ^ Package.toString pkg ^ " not found")
    | Package.Tag remote =>
        err ("Failed to retrieve the latest tag from remote " ^ remote)
    | Path.Command s => err ("Command \"" ^ s ^ "\" not found in $PATH")
    | Path.Home =>
        err ("Jinmori home directory (~/.jinmori by default) not found")
    | Path.Root => err ("Jinmori root (Jinmori.json) not found")
  end
