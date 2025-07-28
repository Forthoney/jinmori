val cmdName = "jinmori"
val version = "0.1.0"
val break = ""

val _ =
  case CommandLine.arguments () of
    "add" :: args => Add.run args
  | "new" :: args => New.run args
  | "build" :: args => Build.run args
  | "--help" :: args => print "Available subcommands: add, new, build\n"
  | [] => print "Available subcommands: add, new, build\n"
  | unknown :: args =>
      TextIO.output (TextIO.stdErr, "Unknown subcommand: " ^ unknown ^ "\n");
