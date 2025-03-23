signature CONFIG =
sig
  type config
  type parser = (string list * config)
                -> (string list * config, string) Result.result

  val default: config
  val parseOrder: parser list
  val run: config -> (unit, string) Result.result
end

signature COMMAND =
sig
  val exec: string list -> unit
end

functor CommandFn(Config: CONFIG): COMMAND =
struct
  fun eprint msg = TextIO.output (TextIO.stdErr, msg)
  
  fun exec args =
    let
      fun loop [] ([], cfg) = Result.OK cfg
        | loop [] (unmatched, cfg) = Result.ERR "Too many arguments"
        | loop (p :: ps) state =
            case p state of
              Result.OK state => loop ps state
            | Result.ERR s => Result.ERR s
    in
      case loop Config.parseOrder (args, Config.default) of
        Result.OK cfg =>
          (case Config.run cfg of
             Result.OK _ => ()
           | Result.ERR e => print e)
      | Result.ERR e => (eprint e; OS.Process.exit OS.Process.failure)
    end
end
