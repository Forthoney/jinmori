## Running tests
`./runner`

## Writing tests
The tests are contained in files with the `.test` extention.
The first three lines of these files contain the
1. Description of the test
2. Command to run
3. Expected exit code
The remaining lines are the expected file system side effects.

When writing the test command and file system side effects, use the following
variables:
* `JINMORI_TOP`: The project root
* `JINMORI`: The `jinmori` executable
* `TRY`: The `try` executable
* `TESTS`: The `tests` directory inside the project
* `PWD`: The path to the working directory

