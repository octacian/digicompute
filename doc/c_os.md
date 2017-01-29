# Computer OS API
This API can be used by players to interact with the computer under a safe and secure environment. The documentation is divided into two sections as is the code, main (for general functions), and filesystem (for filesystem access).

## Main
This contains a set of functions mainly for the purpose of interacting with the computer's displays.

#### `print(string, false)`
**Usage:** `print(<contents>, <newline (true/false)>`

Prints to the output buffer. If contents is not a string, it will be converted to a string with `dump`. The second parameter, if false, prevents print from inserting a newline before printing the provided contents.

#### `set_help(value)`
**Usage:** `set_help(<value (string)>)`

Sets the text to be shown when hovering over the help button. A `nil` value will revert the text to default.

#### `get_attr(key)`
**Usage:** `get_attr(<attribute name (string)>)`

Gets a piece of global information from the node meta (storage). Several common attributes are below. **Note:** none of these attributes can be directly set, with the purpose of being read-only. However, there are methods to set several.

* `owner`: username of the player who owns the computer.
* `input`: input field.
* `output`: output buffer.
* `name`: computer name.

#### `get_output()`
**Usage:** `get_output()`

Returns the value of the output buffer. Shorthand for `get_attr("output")`.

#### `set_output(value)`
**Usage:** `set_output(<value (string)>)`

Set the output buffer to any string. This is the write method for the output attribute.

#### `get_input()`
**Usage:** `get_input()`

Returns the value of the input field. Shorthand for `get_attr("input")`.

#### `set_input(value)`
**Usage:** `set_input(<value (string)>)`

Set the input field to any string. This is the write method for the input attribute.

#### `get_os(key)`
**Usage:** `get_os(<data name (string)>)`

Gets a piece of information from the OS table. See next function for further information on this table.

#### `set_os(key, value)`
**Usage:** `set_os(<data name (string)>, <value>`

Sets a piece of information stored in the OS table. This table stores basic values containing information global to the operating system. However, it is quite limitted, only being capable of storing a few pieces of information as listed below.

* `clear`: command to clear the output and input.
* `off`: command to turn the computer off.
* `reboot`: command to reboot the computer.
* `prefix`: prefix printed at the beginning of a new line.

#### `get_userdata(key)`
**Usage:** `get_userdata(<data name (string)>)`

Gets a piece of information from the userdata table. This table is like RAM, as information will be reset when the computer is turned off.

#### `set_userdata(key, value)`
**Usage:** `set_userdata(<data name (string)>, <value>`

Stores any piece of information in the non-persistant userdata table. (Table is cleared when computer is turned off, therefore non-persistant.)

#### `refresh()`
**Usage:** `refresh()`

Refresh the computer display, typically after making changes to a buffer, field, or other element.

#### `run(code)`
**Usage:** `run(<code (string)>)`

Run code under the environment (e.g. run data in the input field whenever it is submitted).

## Filesystem
This API section introduces function to interact with the computer's physical filesystem.

#### `exists(path)`
__Usage:__ `fs.exists(<path (string)>)`

Checks to see if a file exists by opening it with `io.open()` and returns `true` if exists, and `nil` if it does not.

#### `create(path)`
__Usage:__ `fs.create(<path (string)>)`

Creates a file with and returns `true` unless unsuccessful. If you want to write to the file, use `write` directly, as it will automatically create the file if it doesn't already exist.

#### `remove(path)`
__Usage:__ `fs.remove(<path (string)>`

Removes a file and returns `true` if successful. If the return value is `nil`, the file either does not exist or is a directory. Directories must be removed with `rmdir`.

#### `write(path, data, mode)`
__Usage:__ `fs.write(<path (string)>, <data>, <mode (string)>`

Writes any data to the file specified by `path` and returns `true` if successful. If the file does not exist, it will be created and written to. You can specify if you would like to overwrite or append to a file using the optional `mode` parameter (`w`: overwrite/create, `a`: append).

#### `read(path)`
__Usage:__ `fs.read(<path (string)>)`

Attempts to read entire file. If `nil` is returned, the file does not exist, otherwise, the file contents will be returned.

#### `copy(original_path, new_path)`
__Usage:__ `fs.copy(<original path (string)>, <new path> (string)`

Reads from one path then creates and writes its contents to the new path. If the function returns `nil`, the file doesn't exist or some other error has occurred. Otherwise, a return value of `true` indicates a success.

#### `mkdir(path)`
__Usage:__ `fs.mkdir(<path (string)>)`

Creates a directory. Will return `true` if successful, and `nil` if the directory already exists or another error occurs.

#### `rmdir(path)`
__Usage:__ `fs.rmdir(<path (string)>)`

Recursively removes a directory if it exists. Returns `true` if successful. __Note:__ this is destructive and will remove all of the sub-directories and files inside of a directory.

#### `cpdir(original_path, new_path)`
__Usage:__ `fs.cpdir(<original path (string)>, <new path (string)>`

Recursively copies a directory and all it's sub-directories and files. Returns `true` if successful. __Note:__ depending on the size of the original directory, this may take some time.