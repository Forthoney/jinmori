signature COMPILER_INFO =
sig
  val name: string
  val options:
    {entryPoint: string, output: string, additional: string list, debug: bool}
    -> string list
end
