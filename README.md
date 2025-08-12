# Jinmori
Jinmori is a one-stop Standard ML Package Manager capable of downloading and adding dependencies, installing binaries, and building projects. See [comparison against other SML package managers](#comparison)

## Dependencies
Jinmori requires MLton to compile.
It also requires [`medjool`](https://github.com/Forthoney/medjool),
which can be automatically downloaded with the following instructions.

## Installation
If you already have jinmori, clone this repo and simply run
```sh
jinmori build --release
```

If you do not have an existing jinmori binary, run the following to install the necessary dependencies
```sh
bash bootstrap.sh
```

## Walkthrough
Create a new project with 
```sh
jinmori new myproject
```
This creates a new directory named `myproject` with some boilerplate/scaffolding inside.
There are two files worth noting: **`src/sources.mlb`** and **`src/myproject.mlb`**.
`sources.mlb` should hold the code that is meant to be imported by others as a library,
while `myproject.mlb` contains code that is meant to be used only when building the executable.
By default `myproject.mlb` automatically imports `src/Main.sml` which serves, by convention,
as the entry point of the binary.

Now, from anywhere within the `myproject` directory, execute 
```sh
jinmori build
```
This will create a `build/myproject.dbg` executable.
Running `build/myproject.dbg` should output the classic "Hello, world!"

To use an external library,
run 
```sh
jinmori add github.com/<owner>/<repo>
```
This will automatically download the target repo and create a symbolic link to the repo's root at
`deps/<repo>`
To use the library, just add `../deps/<repo>/sources.mlb` to the appropriate `.mlb` file such as `src/sources.mlb`.

## Available Packages
### Jinmori-native packages
- [which](https://github.com/Forthoney/which)
- [fold](https://github.com/Forthoney/fold)
- [shorthand](https://github.com/Forthoney/shorthand)

### Jinmori-compatible forks
These packages in their original form are not compatible with Jinmori,
but have a fork which is compatible
- [smlfmt](https://github.com/Forthoney/smlfmt)
- [sml-uri](https://github.com/Forthoney/sml-uri)

## Planned features
Jinmori currently only supports using the latest commit of a repo.
- [x] Support version tags
- [x] Install commands
- [x] ~~Assign MLBasisPathMap variables~~ Handling dependencies through symlinks
- [ ] Support multiple compilers
- [ ] Verbosity control
- [ ] Lockfile 

## Comparison
### Unique to Jinmori
- Jinmori handles building automatically without requiring the use of a `Makefile`
- Jinmori only supports MLton (as of now)

### [smlpkg](https://github.com/diku-dk/smlpkg)
- Jinmori downloads packages once and reuses it via symlinks rather than redownloading packages on a per-project basis
- Jinmori allows for flat project directories instead of `lib/github.com/<username>/<package>`
- Jinmori provides a `build` command instead of relying on project-specific `Makefile`, and thus can install binaries as well
- Jinmori only supports MLton (as of now)
- Jinmori requires specifying the exact version whereas smlpkg assumes packages abide by semantic versioning and will update packages accordingly

### [smackage](https://github.com/standardml/smackage)
- Jinmori handles downloading of dependencies
- Jinmori explicitly lists dependencies in `Jinmori.json`
- Jinmori does not rely on SML path maps and instead uses symlinks
