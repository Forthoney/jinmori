The entrypoint to the test suite is `runner`.

Inside the individual tests, the following variables are available for convenience:
* `JINMORI_TOP`: The project root
* `JINMORI`: The `jinmori` executable
* `TRY`: The `try` executable
* `TESTS`: The `tests` directory inside the project

Inside each test, the expected `try` logs should be written in a file.
This file's path should be set to the `EXPECTED` variable.
The command to be run 

Each test should call `checkexpect.sh` after executing
