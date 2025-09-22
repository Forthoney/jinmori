signature COMPILER_STRUCT =
sig
  val name: string
  val options: build_info -> string list
end

