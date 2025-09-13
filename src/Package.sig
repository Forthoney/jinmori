signature PACKAGE =
sig
  type t

  exception NotFound of t
  exception Tag of {remote: string, stderr: string}

  val toString: t -> string
  val fromString: string -> t option

  (* Fetch a package, downloading the package if necessary
     Returns the path to the package's root directory *)
  val fetch: t -> string

  (* Adds a package at the provided path as a dependency for the current project *)
  val addToDeps: string -> unit
end
