signature COMPILER =
sig
  datatype t = MLTON | MPL | SML_NJ | POLY_ML
  exception Compile of string

  val toString: t -> string
  val fromString: string -> t option

  val compileWith: t -> string option -> build_info -> unit
end
