structure NewCmd = CommandFn(New)
structure AddCmd = CommandFn(Add)
structure InstallCmd = CommandFn(Install)
structure BuildCmd = CommandFn(Build)

val cmdName = "jinmori"
val version = "0.1.0"
val break = ""

val subcommandHelp =
  (String.concatWith "\n" o map (fn (name, desc) => "\t" ^ name ^ "\t" ^ desc))
    [ ("new", NewCmd.shortHelp)
    , ("add", AddCmd.shortHelp)
    , ("install", InstallCmd.shortHelp)
    , ("build", BuildCmd.shortHelp)
    ]

val help = String.concatWith "\n"
  [ "A Standard ML package manager"
  , break
  , String.concatWith " " ["Usage:", cmdName, "[OPTIONS]", "[COMMAND]"]
  , break
  , "Options:"
  , "\t--help\t\tPrint help (this page)"
  , "\t--version\tPrint version info"
  , break
  , subcommandHelp
  , break
  , "See '" ^ cmdName
    ^ " help <command>' for more information on a specific command."
  , break
  ]

fun helpSubcommand "new" =
      String.concatWith "\n"
        [ "Create a new SML project"
        , break
        , "Usage: " ^ cmdName ^ " new <PROJECT>"
        , break
        ]
  | helpSubcommand cmd = "Unknown command " ^ cmd

val () =
  case CommandLine.arguments () of
    "new" :: args => NewCmd.exec args
  | "add" :: args => AddCmd.exec args
  | "install" :: args => InstallCmd.exec args
  | "build" :: args => BuildCmd.exec args
  | [] | ["help"] | "--help" :: _ => print help
  | "--version" :: _ => print version
  | "help" :: cmd :: _ => print (helpSubcommand cmd)
  | cmd :: _ => print ("Unknown command '" ^ cmd ^ "'\n")
