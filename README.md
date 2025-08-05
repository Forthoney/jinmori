# Jinmori
Jinmori is an opinionated Standard ML Package Manager.

## Dependencies
Jinmori requires MLton to compile.

## Installation
### I already have Jinmori
You can simply run
```sh
jinmori build --release
```

### I do not have jinmori
Run `bootstrap.sh`, which will manually install the necessary dependencies.

## Planned features
Jinmori currently only supports using the latest commit of a repo.
- [x] Support version tags
- [x] Install commands
- [x] ~~Assign MLBasisPathMap variables~~ Handling dependencies through symlinks
- [ ] Support multiple compilers
- [ ] Verbosity control
- [ ] Lockfile 
