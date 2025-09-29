signature PACKAGE =
sig
  type t
  type installed

  exception NotFound of t
  exception Tag of {remote: string, stderr: string}

  val toString: t -> string
  val fromString: string -> t option
  val fromStringInteractive: string -> t option

  (* Fetch a package, downloading the package if necessary
     Returns the path to the package's root directory *)
  val fetch: t -> installed

  (* addToDeps proj target adds the (installed) package located at target to the project located at proj *)
  val addToDeps: string -> installed -> unit
end
