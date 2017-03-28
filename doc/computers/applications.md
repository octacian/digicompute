# Applications with OctOS
OctOS has a simple framework to allow the player to easily create their own programs for their computers. All you have to do, is place a file in the `bin` directory to tell OctOS about your application, while the code is typically placed in `exec`.

Files in `bin` do not have to follow any naming convention and typically do not even have an extension. They are formatted as shown below, `name` and `exec` being the only required fields. If `name` is not defined, the file name will be used. Parameters are shown just after the command name in help, and just before the description.

```
name = <name>
description = <description>
params = <parameters>
exec = <path to code (e.g. os/exec/help.lua)>
```

Files in `exec` should be referenced by a file in `bin`. Any parameters provided when executing the command will be provided to the file and can be retrieved from the `...` variable, as shown below.

```lua
local params = ...
```