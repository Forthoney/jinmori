signature MANIFEST =
sig
  exception MissingField of string
  type t =
    { package: {name: string, version: string}
    , supportedCompilers: Compiler.t list
    , dependencies: string list
    }
  val default: string -> t
  val toJSON: t -> JSON.value
  val read: string -> t
  val write: string * t -> unit
end
