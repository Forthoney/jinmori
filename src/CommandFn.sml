signature COMMAND =
sig
  type config
  type parser = (string list * config) -> string list * config

  val default: config
  val parseOrder: parser list
  val run: config -> unit
end

exception Args

functor CommandFn(Command: COMMAND):
sig
  val exec: string list -> unit
end =
struct
  fun eprint msg = TextIO.output (TextIO.stdErr, msg)

  fun exec args =
    let
      fun loop [] ([], cfg) = cfg
        | loop [] (unmatched, cfg) = raise Args
        | loop (parser :: ps) state =
            loop ps (parser state)
    in
      Command.run (loop Command.parseOrder (args, Command.default))
    end
end
