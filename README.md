# Jinmori
Jinmori is an opinionated Standard ML Package Manager.

## Dependencies
Jinmori requires MLton to compile.

## Installation
### I already have an existing Jinmori installation
Jinmori can bootstrap itself.
Clone this repository then run `jinmori build --release` anywhere in the repo.
This will produce a new `jinmori` executable binary in `build/jinmori`.

### I do not have an existing installation
Clone this repository.
Navigate to the root of the project (where this `README.md` is located),
then run `mlton -output build/jinmori src/main.mlb`.

## Planned features
Jinmori currently only supports using the latest commit of a repo.
- [] Support version tags
- [] Assign MLBasisPathMap variables
- [] Lockfile
