# Modules
Non-API portions of digicompute are loaded as modules to allow them to be easily enabled or disabled. Modules can be manually loaded or required from the API or from another module. Specific modules can be disabled using `modules.conf`, as documented below.

## Managing Modules
Modules listed in the configuration file are automatically loaded at startup unless specifically disabled. For the purpose of listing and/or disabling mods, we've introduced the `modules.conf` file. 

Each module is listed on a new line, as if setting a variable. A module can be disabled or enabled by setting this variable to `true` or `false`. If a module is not listed here, or is set to `false` (disabled), it will not be automatically loaded.

__Example:__
```lua
-- Enabled:
computers = true
-- Disabled:
computers = false
```

A small API is provided allowing modules to be loaded from another module or from the main API. A module can be force loaded (overrides configuration), or can be loaded with the configuration in mind.

## Module API
Modules are places a subdirectories of the `modules` directory. Each module must have the same name as its reference in the configuration file. Modules must have an `init.lua` file, where you can load other portions of the module with `dofile`, or use the API documented below.

#### `get_module_path(name)`
__Usage:__ `digicompute.get_module_path(<module name (string)>)`

Returns the full path of the module or `nil` if it does not exist. This can be used to check for another module, or to easily access the path of the current module in preparation to load other files with `dofile` or the likes.

#### `load_module(name)`
__Usage:__ `digicompute.load_module(<module name (string)>)`

Attempts to load a module. If the module path is `nil`, `nil` is returned to indicate that the module does not exist. Otherwise, a return value of `true` indicates a success or that the module has already been loaded. __Note:__ this function overrides any settings in `modules.conf`, meaning that it will be loaded even if it was disabled. For general use cases, use `require_module` instead.

#### `require_module(name)`
__Usage:__ `digicompute.require_module(<module name (string)>)`

Passes name to `load_module` if the mod was not disabled in `modules.conf`. For further documentation, see `load_module`.