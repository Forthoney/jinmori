functor CompileFn(C: COMPILER_STRUCT) =
struct
  fun compile opts =
    let
      open MLton.Process
      val child = create
        { path = Path.which C.name
        , args = C.options opts
        , env = NONE
        , stderr = Param.pipe
        , stdin = Param.null
        , stdout = Param.self
        }
      val stderr =
        let
          val strm = Child.textIn (getStderr child)
          fun loop () =
            case TextIO.inputLine strm of
              SOME s => s ^ loop ()
            | NONE => ""
        in
          loop ()
        end
    in
      case reap child of
        Posix.Process.W_EXITED => (TextIO.output (TextIO.stdErr, stderr); TextIO.flushOut TextIO.stdErr)
      | _ => raise Compile stderr
    end
end
