type build_info =
  {entryPoint: string, output: string, additional: string list, debug: bool}
exception Compile of string

