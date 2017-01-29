# Computer API
This API is used for registering new computers. The API can also be used for modders to make advanced interactions with pre-existing computers or customize their own.

## Computer Registration
It's actually quite easy to register a computer, the end result looking similar to the definition of a normal node.

Register a computer with `digicompute.register_computer`.
```lua
digicompute.register_computer("<computer_string>", {
  description = "<description>",
  off_tiles = {},
  bios_tiles = {},
  on_tiles = {},
  node_box = {},
})
```

The definition is formed just like that of a normal node definition, except digicompute uses it to do a lot of groundwork rather than requiring you to do it manually. **Note:** do not put a modname in the computer string, `digicompute:` is automatically inserted.

**Example:**
```lua
digicompute.register_computer("default", {
	description = "digicomputer",
	off_tiles = {
		"top.png",
		"bottom.png",
		"right.png",
		"left.png",
		"back_off.png",
		"front_off.png",
	},
	bios_tiles = {
		"top.png",
		"bottom.png",
		"right.png",
		"left.png",
		"back_off.png",
		"front_off.png^bios.png",
	},
	on_tiles = {
		"top.png",
		"bottom.png",
		"right.png",
		"left.png",
		"back.png",
		"front.png"
	},
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.125, 0.5, 0.5, 0.5},
		}
	},
})
```

Above is example code from the default computer.

## Advanced API
This API is more of a documentation of pre-existing API functions for developers new to this mod who would like to get started. The Advanced API documentation is sectioned out as it is in the code.

### ID Management
This section manages loading, saving, and assigning new IDs to computers.

#### `load_computers()`
**Usage:** `digicompute.load_computers()`

Loads the IDs of all computers for later use. This should only be called after the variable `computer` (type: `table`) is defined. **Note:** the Computer API automatically loads the computers IDs when the server starts.

#### `save_computers()`
**Usage:** `digicompute.save_computers()`

Saves computer IDs as stored in the `computer` table. Be sure that this table exists before attempting to save. **Note:** the Computer API automatically saves the computers IDs before the server shuts down.

#### `c:new_id(pos)`
**Usage:** `digicompute.c:new_id(<computer position (table)>)`

Generate a new computer ID, store it in the `computers` table, and save it in the node meta. Make sure this table exists before attempting to generate a new ID.

### Formspecs
This section uses tables to store information about the formspec(s) and their tabs. It also introduces functions to show and handle received fields from formspecs.

#### `c:handle_tabs(pos, player, fields)`
**Usage:** `digicompute.c:handle_tabs(<computer position (table)>, <player (userdata value)>, <form fields (table)>`

Handles tab switching. Should be called in the handle function of any tab for the main form. Valid tabs should be added (in proper order) to the tabs table (defined above function). **TODO:** improve API to support tab handling for other forms.

#### Forms Table
**Name:** `digicompute.c.forms`

This is a slightly more complex topic, as this table handles all of the forms (and tabs) used by digicomputers. Each form/tab has it's own entry, defining a table of informatin about it.

**Basic Parameters:**
```lua
digicompute.c.forms = {
  newformname = {
    cache_formname = true/false,
    get = function(pos, player) ... end,
    handle = function(pos, player, fields) ... end,    
  },
  ...
}
```

The `cache_formname` field is used in `digicompute.c:open` to choose whether or not to cache the formname in meta. If the formname is cached in meta, it will automatically be opened the next time the computer is right-clicked. Unless this is `false`, the formname will be cached.

`get` is a required item which is used by `digicompute.c:open` to obtain the actual formspec information. All that really matters is that you return a valid formspec string at the end of the function.

`handle` is called `on_receive_fields` to handle player input. It is a required item, but there are no direct requirements past that.

**Example (naming form):**
```lua
  naming = {
    cache_formname = false,
    get = function(pos)
      local meta = minetest.get_meta(pos)

      return
        "size[6,1.7]"..
        default.gui_bg_img..
        "field[.25,0.50;6,1;name;Computer Name:;"..minetest.formspec_escape(meta:get_string("name")).."]"..
        "button[4.95,1;1,1;submit_name;Set]"
    end,
    handle = function(pos, player, fields)
      local meta  = minetest.get_meta(pos)
      local name  = player:get_player_name()
      local owner = meta:get_string("owner")

      if owner == name then
        if fields.name or fields.key_enter_field == "name" and fields.name ~= "" then
          meta:set_string("name", fields.name)
          meta:set_string("setup", "true")
          meta:set_string("path", main_path..meta:get_string("owner").."/"..meta:get_string("id").."/")
          digicompute.c:init(pos)
          digicompute.c:open(pos, player)
        else
          minetest.chat_send_player(name, "Name cannot be empty.")
        end
      else
        minetest.chat_send_player(name, "Only the owner can set this computer. ("..owner..")")
      end
    end,
  },
```

#### `c:open(pos, player, formname)`
**Usage:** `digicompute.c:open(<computer position (table)>, <player (userdata value)>, <form name (string)>)`

Shows a form defined in the forms table. If the formname is not provided, it will be set to the formname cached in meta (if any), and default to `main`. Fields are automatically sent to the `handle` function defined in the forms table. **Note:** `player` should not be the a plaintext string containing the player name, but a userdata value.

### Helper Functions
This section defines several helper functions used in the formspecs, environment, and node definition.

#### `c:infotext(pos)`
**Usage:** `digicompute.c:infotext(<computer position (table)>)`

Updates the infotext of the computer. This is called after the computer is named or when its state changes (off/bios/on).

#### `c:init(pos)`
**Usage:** `digicompute.c:init(<computer position (table)>)`

Initializes the computers filesystem, runs `main.lua`, and updates the infotext. **Note:** path must already be defined in meta, otherwise the initialization process will not complete (this is defined in the handling function of the naming form).

#### `c:deinit(pos, true/false)`
**Usage:** `digicompute.c:deinit(<computer position (table)>, <clear computer ID entry (boolean)>)`

Deinitializes a computers filesystem. The entry in the computers table is also cleared unless the final parameter is `false` (used when a computer reset is requested as the ID should not be cleared).

#### `c:reinit(pos)`
**Usage:** `digicompute.c:reinit(<computer position (table)>)`

Reinitializes the filesystem of a computer by calling `c:deinit` followed by `c:init`. **Note:** this is destructive and will wipe any files created or changed by the player.

#### `c:on(pos, player)`
**Usage:** `digicompute.c:on(<computer position (table)>, <player (userdata value)>`

Turns a computer on (will not execute if computer is not off). `start.lua` is automatically run, hence the player userdata is required.

#### `c:off(pos, player)`
**Usage:** `digicompute.c:off(<computer position (table)>, <player (userdata value)>`

Turns a computer off. The formspec is automatically closed using `minetest.close_formspec` (requires Minetest 0.4.15 or later), hence the player userdata is required.

#### `c:reboot(pos, player)`
**Usage:** `digicompute.c:reboot(<computer position (table)>, <player (userdata value)>`

Reboots a computer by calling `c:off` followed by `c:on`.

### Environment
This section introduces functions to initialize the environment per-computer and execute a string or file under the environment.

#### `c:make_env(pos, player)`
**Usage:** `digicompute.c:make_env(<computer position (table)>, <player (userdata value)>`

Returns a table of functions allowed under the environment. The table is made up of a wide array of functions for interacting with the computer and its file system. These are joined with the table returned by `digicompute.env()`, explaned in `env.md`. The player userdata parameter is required for later callbacks to functions such as `c:open`.

#### `c:run_code(pos, player, code)`
**Usage:** `digicompute.c:run_code(<computer position (table)>, <player (userdata value)>, <code (string)>)`

Generates an environment table using `c:make_env` and runs the code (provided as third parameter) with `digicompute.run_code` (see `env.md`).

#### `c:run_file(pos, player, path)`
**Usage:** `digicompute.c:run_file(<computer position (table)>, <player (userdata value)>, <path (string)>)`

Generates an environment table using `c:make_env` and runs the code found in the file specified by `path` with `digicompute.run_file` (see `env.md`). **Note:** the path is relative to the computer, meaning that `main.lua` could be run with `digicompute.c:run_file(pos, player, "os/main.lua")`.