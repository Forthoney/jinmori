structure Package:
sig
  type package = {source: string, author: string, name: string}

  datatype download_err = PackageNotFound
  datatype build_err =
    BuildFailed
  | BinaryNotFound
  | InvalidDestination of string
  | Generic of string

  val toString: package -> string
  val fromString: string -> package option

  val fetchSrc: string -> package -> (string, download_err) Result.result
  val build: (string * string) -> package -> (string, build_err) Result.result
end =
struct
  open Path
  open Result

  structure FS = OS.FileSys
  structure Proc = OS.Process

  type package = {source: string, author: string, name: string}

  datatype download_err = PackageNotFound
  datatype build_err =
    BuildFailed
  | BinaryNotFound
  | InvalidDestination of string
  | Generic of string

  fun fromString s =
    case String.tokens (fn c => c = #"/") s of
      [source, author, name] =>
        SOME {source = source, author = author, name = name}
    | _ => NONE

  fun toString {source, author, name} =
    String.concatWith "/" [source, author, name]

  fun build (src, bin) {source, author, name} =
    if Proc.isSuccess (Proc.system ("make --directory=" ^ src)) then
      let
        fun isExec exe =
          FS.access (exe, [FS.A_EXEC])
        val candidates = [src / name, src / "bin" / name, src / "exec" / name]

        fun move (from, to) =
          (FS.rename {old = from, new = to}; OK to)
          handle OS.SysErr (msg, e) =>
            if Option.isSome e andalso Option.valOf e = Posix.Error.noent then
              ERR (InvalidDestination to)
            else
              ERR (Generic msg)
      in
        case List.find isExec candidates of
          SOME exec => move (exec, bin / name)
        | NONE => ERR BinaryNotFound
      end
    else
      ERR BuildFailed

  fun fetchSrc home {source, author, name} =
    let
      val dest = home / "pkgs" / source / author / name
      val addr =
        String.concatWith "/" ["https://" ^ source, author, name ^ ".git"]
      val cloneCmd = String.concatWith " " ["git", "clone", addr, dest]
    in
      if
        FS.access (dest, [FS.A_READ])
        orelse Proc.isSuccess (Proc.system cloneCmd)
      then OK dest
      else ERR PackageNotFound
    end
end
