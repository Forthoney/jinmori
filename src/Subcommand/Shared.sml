val _ = Logger.level := Level.FATAL

structure Shared =
struct
  fun verbosity ret =
    let
      val convert =
        fn "debug" => Level.DEBUG
         | "info" => Level.INFO
         | "warn" => Level.WARN
         | "error" => Level.ERROR
         | "fatal" => Level.FATAL
         | _ => raise Fail "unreachable"
    in
      { usage = {name = "verbose", desc = "Set verbosity level"}
      , arg = Argument.One
          { action = fn s =>
              let
                val s =
                  Argument.includedIn
                    ["debug", "info", "warn", "error", "fatal"] s
                val level = convert s
                val _ = Logger.level := level
              in
                ret
              end
          , metavar = "LEVEL"
          }
      }
    end
end
