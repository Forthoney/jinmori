exception TestFail of string

val passed = ref 0
val failed = ref 0

fun fail msg = raise TestFail msg

fun assertTrue msg cond =
	if cond then () else fail msg

fun assertEqual (msg, expected, actual) =
	if expected = actual then ()
	else fail (msg ^ " (expected: " ^ expected ^ ", actual: " ^ actual ^ ")")

fun assertOptionSome msg opt =
	case opt of
		SOME v => v
	| NONE => fail msg

fun run name thunk =
	( thunk ()
	; passed := !passed + 1
	; print ("[PASS] " ^ name ^ "\n")
	)
	handle
		TestFail msg =>
			( failed := !failed + 1
			; print ("[FAIL] " ^ name ^ ": " ^ msg ^ "\n")
			)
	| exn =>
			( failed := !failed + 1
			; print
					("[FAIL] " ^ name ^ ": unexpected exception "
					 ^ General.exnMessage exn ^ "\n")
			)

fun mkTempDir prefix =
	let
		val path = OS.FileSys.tmpName ()
		val dir = path ^ "-" ^ prefix
		val _ = OS.FileSys.mkDir dir
	in
		dir
	end

fun writeText (path, content) =
	let
		val out = TextIO.openOut path
		val _ = TextIO.output (out, content)
		val _ = TextIO.closeOut out
	in
		()
	end

fun testManifestDefault () =
	let
		val {package = {name, version}, supportedCompilers, dependencies, ...} =
			Manifest.default "demo"
		val _ = assertEqual ("default package name", "demo", name)
		val _ = assertEqual ("default version", "0.1.0", version)
		val _ = assertTrue "default compiler list has one entry"
				(List.length supportedCompilers = 1)
		val compiler = hd supportedCompilers
		val _ = assertEqual
				("default compiler is mlton", "mlton", Compiler.toString compiler)
		val _ = assertTrue "default dependencies are empty" (List.null dependencies)
	in
		()
	end

fun testManifestRoundTrip () =
	let
		val dir = mkTempDir "manifest-roundtrip"
		val path = dir / "Jinmori.json"
		val manifest =
			{ package = {name = "roundtrip", version = "1.2.3"}
			, supportedCompilers = [Compiler.MLTON]
			, dependencies = ["github.com/example/pkg@v1", "github.com/me/lib@v2"]
            , description = ""
            , license = ""
            , repository = "github.com/example/repo"
			}
		val _ = Manifest.write (path, manifest)
		val parsed = Manifest.read path
		val {package = {name, version}, supportedCompilers, dependencies, ...} = parsed
		val _ = assertEqual ("roundtrip name", "roundtrip", name)
		val _ = assertEqual ("roundtrip version", "1.2.3", version)
		val _ = assertTrue "roundtrip keeps compiler" (supportedCompilers = [Compiler.MLTON])
		val _ = assertTrue "roundtrip keeps dependencies"
				(dependencies = ["github.com/example/pkg@v1", "github.com/me/lib@v2"])
	in
		()
	end

fun testManifestMissingField () =
	let
		val dir = mkTempDir "manifest-missing"
		val path = dir / "Jinmori.json"
		val _ = writeText (path, "{\"package\":{\"name\":\"x\",\"version\":\"0.1.0\"},\"dependencies\":[]}")
		val _ =
			( Manifest.read path
			; fail "Manifest.read should fail when supportedCompilers is missing"
			)
			handle Manifest.MissingField "supportedCompilers" => ()
					 | exn => fail ("wrong exception: " ^ General.exnMessage exn)
	in
		()
	end

fun testPackageFromString () =
	let
		val pkg = assertOptionSome "expected SOME for valid package"
				(Package.fromString "github.com/Forthoney/dummy@v0.1.0")
		val _ = assertEqual
				("package toString", "github.com/Forthoney/dummy@v0.1.0", Package.toString pkg)
		val none1 = Package.fromString "@v1"
		val none2 = Package.fromString ""
		val _ = assertTrue "invalid leading @ returns NONE" (none1 = NONE)
		val _ = assertTrue "empty package string returns NONE" (none2 = NONE)
	in
		()
	end

fun testPackageNormalizeURLForms () =
	let
		val p1 = assertOptionSome "url form should parse"
				(Package.fromString "https://github.com/Forthoney/dummy.git@v1")
		val p2 = assertOptionSome "normalized form should parse"
				(Package.fromString "github.com/Forthoney/dummy@v1")
		val _ = assertEqual
				("normalized sources should match", Package.toString p2, Package.toString p1)
	in
		()
	end

fun testPathProjectRoot () =
	let
		val root = mkTempDir "project-root"
		val nested = root / "a" / "b"
		val _ = writeText (root / "Jinmori.json", "{}")
		val _ = OS.FileSys.mkDir (root / "a")
		val _ = OS.FileSys.mkDir nested
		val found = Path.projectRoot nested
		val _ = assertEqual ("find project root from nested path", root, found)
	in
		()
	end

fun testPathHomeFromEnv () =
	let
		val _ = MLton.ProcEnv.setenv {name = "JINMORI_HOME", value = "/tmp/jinmori-home"}
		val home = Path.home ()
		val _ = assertEqual ("Path.home uses JINMORI_HOME", "/tmp/jinmori-home", home)
	in
		()
	end

fun summary () =
	let
		val total = !passed + !failed
		val _ = print ("\nSummary: " ^ Int.toString (!passed) ^ "/" ^ Int.toString total ^ " tests passed\n")
	in
		if !failed = 0 then OS.Process.exit OS.Process.success
		else OS.Process.exit OS.Process.failure
	end

val _ =
	( run "Manifest.default" testManifestDefault
	; run "Manifest.read/write roundtrip" testManifestRoundTrip
	; run "Manifest.read missing field" testManifestMissingField
	; run "Package.fromString basics" testPackageFromString
	; run "Package.fromString normalization" testPackageNormalizeURLForms
	; run "Path.projectRoot" testPathProjectRoot
	; run "Path.home from env" testPathHomeFromEnv
	; summary ()
	)
