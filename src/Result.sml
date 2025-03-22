structure Result =
struct
  datatype ('a, 'b) result = OK of 'a | ERR of 'b

  fun map f (OK x) =
        OK (f x)
    | map _ err = err

  fun mapErr f (ERR e) =
        ERR (f e)
    | mapErr f ok = ok

  fun bind f (OK x) = f x
    | bind f err = err

  fun bindBind f _ (OK x) = f x
    | bindBind _ g (ERR e) = g e

  fun isOK (OK _) = true
    | isOK _ = false

  fun isErr (ERR _) = true
    | isErr _ = false

  fun getOrElse (OK x) _ = x
    | getOrElse _ default = default
end
