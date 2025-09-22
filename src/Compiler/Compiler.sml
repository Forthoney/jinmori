structure Compiler: COMPILER =
struct
  exception Compile = Compile

  datatype t = MLTON | MPL | SML_NJ | POLY_ML

  val toString =
    fn MLTON => "mlton"
     | MPL => "mpl"
     | SML_NJ => "sml/nj"
     | POLY_ML => "poly/ml"

  val fromString =
    fn "mlton" => SOME MLTON
     | "mpl" => SOME MPL
     | "sml/nj" => SOME SML_NJ
     | "poly/ml" => SOME POLY_ML
     | _ => NONE

  structure MLton: COMPILER_STRUCT =
  struct
    val name = "mlton"
    fun options {entryPoint, output, additional, debug} =
      let
        val shared = additional @ [entryPoint]
      in
        if debug then
          ["-output", output ^ ".dbg", "-const", "Exn.keepHistory true"]
          @ shared
        else
          ["-output", output] @ shared
      end
  end

  structure MPL: COMPILER_STRUCT =
  struct
    val name = "mpl"
    fun options {entryPoint, output, additional, debug} =
      let
        val shared = additional @ [entryPoint]
      in
        if debug then
          ["-output", output ^ ".dbg"] @ shared
        else
          ["-output", output] @ shared
      end
  end

  structure MLtonC = CompileFn(MLton)
  structure MPLC = CompileFn(MPL)

  val compileWith =
    fn MLTON => MLtonC.compile
     | MPL => MPLC.compile
     | _ => raise Fail "Not yet supported"
end
