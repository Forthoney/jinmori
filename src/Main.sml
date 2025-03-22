structure NewCmd = CommandFn(New)
structure AddCmd = CommandFn(Add)
structure InstallCmd = CommandFn(Install)

val cmdName = "jinmori"
val break = ""

val subcommandHelp =
  (String.concatWith "\n" o map (fn (name, desc) => "\t" ^ name ^ "\t" ^ desc))
    [ ("new", "Create a new SML project")
    , ("add", "Add dependencies to a Jinmori project")
    , ("install", "Install a MLton binary")
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
  | [] | ["help"] | "--help" :: _ => print help
  | "help" :: cmd :: _ => print (helpSubcommand cmd)
  | cmd :: _ => print ("Unknown command '" ^ cmd ^ "'\n")
