structure Compiler =
struct
  exception Compile of string

  structure MLton: COMPILER_INFO =
  struct
    val name = "mlton"
    fun options {entryPoint, output, additional, debug} =
      let
        val shared = additional @ [entryPoint]
      in
        if debug then
          ["-output", output ^ ".dbg", "-const", "'Exn.keepHistory true'"]
          @ shared
        else
          ["-output", output] @ shared
      end
  end
end
