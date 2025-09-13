val _ = Logger.level := Level.FATAL

structure Shared =
struct
  val verbosity =
    let
      val convert =
        fn "debug" => Level.DEBUG
         | "info" => Level.INFO
         | "warn" => Level.WARN
         | "error" => Level.ERROR
         | "fatal" => Level.FATAL
         | _ => raise Fail "unreachable"
    in
      { usage =
        { name = "verbose"
        , desc = "Set verbosity level"
        }
      , arg = Argument.One {
          action = fn s =>
            let
              val s = Argument.includedIn ["debug", "info", "warn", "error", "fatal"] s
              val level = convert s
            in
              Logger.level := level
            end,
          metavar = "LEVEL"
        }
      }
    end
end
