# Environment API
This API provides a simple set of functions to easily run code under a secure environment.

## `env()`
**Usage:** `digicompute.env()`

Returns a table of safe functions for use when executing code under a secure environment. It is not recommended that you attempt to use this table to manually execute code, rather use `digicompute.run_code`.

## `run_code(code, env)`
**Usage:** `digicompute.run_code(<code (string)>, <environment (table)>)`

* `false`, `msg`: code failed to execute.
* `true`, `msg`: code executed successfully.

Attempts to run provided code under a safe environment (environment table can be generated with `digicompute.env()`). The function returns two variables, the first being a boolean telling whether the operation was successful, and the second an error message/return value from the executed code.

## `run_file(path, env)`
**Usage:** `digicompute.run_file(<path (string)>, <environment (table)>)`

Loads the contents of a file using `builtin` and provides the resulting code and environment table (provided as second parameter) to `run_code`.