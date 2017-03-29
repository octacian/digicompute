# OctOS Commands
OctOS is the operating system used by digicomputers. OctOS is made of many Linux-like commands which are documented under the Commands section, however, there is also an API which can be used when writing programs for OctOS which is documented in `os_api.md`. Available commands are documented below.

#### `help [command, "all"]`
Shows help about the command specified or all commands if `all` is specified.

#### `lua [code]`
Runs Lua code from the command line under the secure environment.

#### `echo [text]`
Print text to the command line.

#### `touch [path]`
Create new file.

#### `rm [path]`
Remove file.

#### `cp [original path] [copy path]`
Make a copy of a file.

#### `mkdir [path]`
Create new directory.

#### `rmdir [path]`
Remove directory.

#### `cpdir [original path] [copy path]`
Make a copy of a directory.

#### `mv [old path] [new path]`
Move a file or directory to a new location.