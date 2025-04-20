structure Package:
sig
  exception Destination of string
  exception NotFound
  exception Build

  type package = {source: string, author: string, name: string}

  val toString: package -> string
  val fromString: string -> package option

  (*!
   * Fetch the path to a package, downloading the package if necessary
   *)
  val fetch: package -> string

  (*!
   * Build a package at the src path and save the binary at dest
   *)
  val build: (string * string) -> package -> unit
end =
struct
  exception Destination of string
  exception NotFound
  exception Build

  structure FS = OS.FileSys
  structure Proc = OS.Process

  type package = {source: string, author: string, name: string}

  fun fromString s =
    case String.tokens (fn c => c = #"/") s of
      [source, author, name] =>
        SOME {source = source, author = author, name = name}
    | _ => NONE

  fun toString {source, author, name} =
    String.concatWith "/" [source, author, name]

  fun build (src, dest) {source, author, name} =
    if Proc.isSuccess (Proc.system ("make --directory=" ^ src)) then
      let
        fun isExec exe =
          FS.access (exe, [FS.A_EXEC])
        val candidates = [src / name, src / "bin" / name, src / "exec" / name]

        fun move (from, to) =
          FS.rename {old = from, new = to}
          handle OS.SysErr (msg, e) =>
            if Option.isSome e andalso Option.valOf e = Posix.Error.noent then
              raise Destination to
            else
              raise Fail msg
      in
        case List.find isExec candidates of
          SOME exec => move (exec, dest / name)
        | NONE => raise NotFound
      end
    else
      raise Build

  fun fetch {source, author, name} =
    let
      val dest = Path.home / "pkgs" / source / author / name
      val addr =
        String.concatWith "/" ["https://" ^ source, author, name ^ ".git"]
      val cloneCmd = String.concatWith " " ["git", "clone", addr, dest]
    in
      if
        FS.access (dest, [FS.A_READ])
        orelse Proc.isSuccess (Proc.system cloneCmd)
      then dest
      else raise NotFound
    end
end
