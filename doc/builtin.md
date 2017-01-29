# Builtin
Builtin contains many independent functions that don't seem to fit elsewhere. Currently, it is mainly an API for easy interaction with the filesystem. All functions provided by builtin are packed under `digicompute.builtin.*`, but have been shortened in this documentation.

## `exists`
__Usage:__ `digicompute.builtin.exists(<string: path>)`

* `true`: file exists
* `nil`: file does not exist

Checks to see if a file exists by opening it with `io.open()` and returning `true` if `io.open()` does not return a `nil` value.

## `create`
__Usage:__ `digicompute.builtin.create(<string: path>)`

* `true`: file successfully created

Creates a file with `io.open()` and returns `true`. If you want to write to the file, use `write` directly, as it will automatically create the file if it doesn't already exist.

## `write`
__Usage:__ `digicompute.builtin.write(<string: path>, <any: data>, <string: mode>`

* `true`: successfully wrote to file

Writes any data to the file specified by `path` and returns `true` if successful. If the file does not exist, it will be created and written to. You can specify if you would like to overwrite or append to a file using the optional `mode` parameter (`w`: overwrite/create, `a`: append). Do directly write a table, but rather serialize it first with `minetest.serialize`. Doing so will cause a crash.

## `read`
__Usage:__ `digicompute.builtin.read(<string: path>)`

* `not-nil`: data read from file
* `nil`: file does not exist

Attempts to read entire file with `io.open():read()`. If `nil` is returned, the file does not exist, otherwise, the file contents will be returned. If your data was serialized before being written, be sure to run `minetest.deserialize` after reading the file.

## `copy`
__Usage:__ `digicompute.builtin.copy(<string: original path>, <string: new path>`

* `true`: successfully copied
* `nil`: original file does not exist

Reads from one path then creates and writes its contents to the new path. If the function returns `nil`, the file doesn't exist or some other error has occurred.

## `mkdir`
__Usage:__ `digicompute.builtin.mkdir(<string: path>)`

* `true`: successfully created directory
* `nil`: directory already exists

Attempts to create directory with `minetest.mkdir()` if available, resorting to `os.execute("mkdir")` if unavailable. Will return `true` if successful, and `nil` if the directory already exists or another error occurs.

## `rmdir`
__Usage:__ `digicompute.builtin.rmdir(<string: path>)`

* `true`: successfully removed directory
* `nil`: directory does not exist

Recursively removes a directory if it exists. __Note:__ this is destructive and will remove all of the sub-directories and files inside of a directory.

## `cpdir`
__Usage:__ `digicompute.builtin.cpdir(<string: original path>, <string: new path>`

* `true`: successfully copied directory
* `nil`: original directory does not exist

Recursively copies a directory and all it's sub-directories and files. __Note:__ depending on the size of the original directory, this may take some time.