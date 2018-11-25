# OctOS
OctOS is the operating system used by digicomputers. OctOS is made of many Linux-like commands which are documented in `commands.md`, however, there is also an API which can be used when writing programs for OctOS. The API can be used by players to interact with the computer under a safe and secure environment. The documentation is divided into two sections as is the code, main (for general functions), and filesystem (for filesystem access).

## Accessing the RAM (userdata)

In earlier versions of digicompute, a RAM-like storage mechanism could be accessed with a `get_userdata` and `set_userdata` API. However, this API was later removed and instead the RAM is accessed by setting values of the `ram` table within the environment. Data can also be preserved by setting a global variable within the environment, however, use of the `ram` table is recommended. This is because of how digicompute handles the environments in the background. Global variables, including the `ram` table, are stored within the environment itself, and with the environment being preserved until the computer is shut off or deinitialized, the variables are preserved as well. Please note that digicompute does not currently have a completely accurate representation of RAM, in that there is no limitation to the amount of data that can be stored. **Warning:** Functions and userdata cannot be stored within RAM.

## Accessing the System Information

Earlier versions of digicompute had an array of functions to get and set arbitrary customizable data regarding the system. This data includes the prefix, clear command, input buffer, and more. However, these APIs have been replaced with a single `system` table, available globally and saved with the help of metatables. There are a very limited amount of keys that can be written to in the system table, as documented below.

**Valid Keys:**
* `prefix` - `string`: prefix printed at the beginning of a new line.
* `input` - `string`: contents of the input field.
* `output` - `string`: contents of the output buffer.
* `output_editable` - `boolean`: whether or not the output is editable.

**Example:**
```lua
system.prefix = get_attr("name")..":~$ "
```

## System API

The system API is part of the `system` table and is used to control low-level aspects of a computer.

#### `shutdown()`
**Usage:** `system.shutdown()`

Turns the computer off and closes the formspec.

#### `reboot()`
**Usage:** `system.reboot()`

Reboots the computer and closes the formspec.

## Main
This contains a set of functions mainly for the purpose of interacting with the computer's displays.

#### `print(string, false)`
**Usage:** `print(<contents>, <newline (true/false)>`

Prints to the output buffer. If contents is not a string, it will be converted to a string with `dump`. The second parameter, if false, prevents print from inserting a newline before printing the provided contents.

#### `print_debug(msg)`
**Usage:** `print_debug(<message (*)>)`

Prints a message to the debug buffer in the Debug Console tab. If contents is not a string, it will be converted to a string with `dump`.

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
* `help`: formspec help text.
* `id`: computer id.
* `output_editable`: whether the output buffer is editable.

#### `refresh()`
**Usage:** `refresh()`

Refresh the computer display, typically after making changes to a buffer, field, or other element. If `nil` is returned rather than `true`, you have been somehow disconnected from the computer as being the current user (e.g. somebody manually edited the `current_user` meta field); the problem can be solved by simply closing and reopening the formspec manually.

#### `run(code, ...)`
**Usage:** `run(<code (string)>, <additional parameters>)`

Run code under the environment (e.g. run data in the input field whenever it is submitted). Returns two parameters, the first representing success and the second being `nil` unless the operation was not successful, in which case it contains an error message. Any number of additional parameters can be provided after the path, to be accessed by the code being run.

#### `set_run(path)`
__Usage:__ `set_run(<file path (string)>)`

Set the file that is to be run when text in the input bar is submitted. Defaults to `os/main.lua`. If the `path` parameter is not provided, the run file will be reset to the default.

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

#### `list(path)`
__Usage:__ `fs.list(<path (string)>)`

Lists the contents of a directory specified by `path`. Returns a table containing two subtables, `files` and `subdirs`. If there are no file or subdirectories, or if the path point to a file rather than a directory, these two subtables will both be empty.

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

#### `run(path, ...)`
__Usage:__ `fs.run(<path to file (string)>, <additional paramters>)`

Attempts to read the contents of a file, treating it as Lua code to be run under the environment. Returns two parameters, the first representing success and the second being `nil` unless the operation was not successful, in which case it contains an error message. Any number of additional parameters can be provided after the path, to be accessed by the code being run.

#### `read_settings(path)`
__Usage:__ `fs.read_settings(<path (string)>)`

Returns a userdata value containing a list of the "settings" defined in a file. Each setting should be on a new line, like variables but without `local` as a prefix. This "object" has several methods that you can use on it (e.g. `:to_table()`), however they are not documented here. Instead, see the methods section in the [documentation for node meta](http://dev.minetest.net/NodeMetaRef#Methods) as `Settings()` and node meta share the same methods.
