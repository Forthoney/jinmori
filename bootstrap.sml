fun op/ (l, r) = OS.Path.joinDirFile {dir = l, file = r}
infix /

fun yesNo question =
  let
    fun loop () =
      ( print (question ^ " [y/n]\n")
      ; case TextIO.inputLine TextIO.stdIn of
          NONE => loop ()
        | SOME line =>
            (case String.tokens Char.isSpace line of
               ["y"] => true
             | ["n"] => false
             | _ => (print "Invalid answer.\n"; loop ()))
      )
  in
    loop ()
  end

fun run cmd =
  if OS.Process.isSuccess (OS.Process.system cmd) then ()
  else
    ( TextIO.output (TextIO.stdErr, "Command failed: " ^ cmd ^ "\n")
    ; OS.Process.exit OS.Process.failure
    )

fun mkdirP dir =
  if OS.FileSys.access (dir, []) then ()
  else
    ( mkdirP (OS.Path.getParent dir)
    ; OS.FileSys.mkDir dir
    )

fun copyFile {src, dst} =
  let
    val inStream = BinIO.openIn src
    val outStream = BinIO.openOut dst
    fun loop () =
      let val chunk = BinIO.input inStream in
        if Word8Vector.length chunk = 0 then ()
        else (BinIO.output (outStream, chunk); loop ())
      end
  in
    loop () handle e => (BinIO.closeIn inStream; BinIO.closeOut outStream; raise e)
    ; BinIO.closeIn inStream
    ; BinIO.closeOut outStream
  end

fun removeTree path =
  if OS.FileSys.isDir path then
    let
      val dir = OS.FileSys.openDir path
      fun loop () =
        case OS.FileSys.readDir dir of
          NONE => ()
        | SOME entry =>
            (removeTree (path / entry); loop ())
    in
      loop ();
      OS.FileSys.closeDir dir;
      OS.FileSys.rmDir path
    end
  else
    OS.FileSys.remove path

val _ =
  let
    val _ =
      if yesNo "This script must be run in the root directory of Jinmori. Do you want to continue?"
      then ()
      else (print "Aborting.\n"; OS.Process.exit OS.Process.failure)

    val home =
      case OS.Process.getEnv "HOME" of
        SOME h => h
      | NONE =>
          ( TextIO.output (TextIO.stdErr, "HOME environment variable not set\n")
          ; OS.Process.exit OS.Process.failure
          )

    val jinmoriHome = home / ".jinmori"
    val tmpRoot = OS.FileSys.tmpName ()
    val medjoolDest = tmpRoot / "medjool"
    val timberDest = tmpRoot / "timber"
    val dbg = "build/jinmori.dbg"
    val release = ref "build/jinmori"
  in
    mkdirP jinmoriHome;
    mkdirP (jinmoriHome / "pkg");
    mkdirP (jinmoriHome / "bin");
    mkdirP "deps";
    mkdirP "build";

    run ("git clone --branch v0.2.2 --depth 1 https://github.com/Forthoney/medjool.git " ^ medjoolDest);
    Posix.FileSys.symlink {old = medjoolDest, new = "deps/medjool"};

    run ("git clone --branch v0.1.3 --depth 1 https://github.com/Forthoney/timber.git " ^ timberDest);
    Posix.FileSys.symlink {old = timberDest, new = "deps/timber"};

    run ("mlton -output " ^ dbg ^ " -const 'Exn.keepHistory true' src/jinmori.mlb");
    print ("Bootstrapped, debug mode jinmori binary saved at '" ^ dbg ^ "'\n");

    run (dbg ^ " build --release");
    print ("Built release mode jinmori binary at '" ^ !release ^ "'\n");

    removeTree tmpRoot;

    (if yesNo ("Would you like to copy '" ^ !release ^ "' into '" ^ (jinmoriHome / "bin") ^ "'? This is where jinmori will save installed commands by default.")
      then
        let
          val dest = jinmoriHome / "bin" / "jinmori"
        in
          copyFile {src = !release, dst = dest};
          print ("Consider adding '" ^ (jinmoriHome / "bin") ^ "' to your path. ");
          release := dest
        end
      else ());
    print "You can now run jinmori by running\n";
    print (!release ^ " --help\n");
    print "in your shell\n"
  end
