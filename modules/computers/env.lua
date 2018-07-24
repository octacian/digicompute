-- computers/env.lua

local environments = {}

-----------------------------
----- EXPOSED FUNCTIONS -----
-----------------------------

-- [local function] Create the table of custom functions
local function create_env_table(meta, pos)
	local cpath = meta:get_string("path") -- Get computer path
	-- Define basic tables
	local env = {
		fs = {}, -- Filesystem API
		ram = {}, -- RAM userdata table
	}

	--- General Functions ---

	-- [function] Print to computer console
	function env.print(contents, newline)
		if type(contents) ~= "string" then
			contents = dump(contents)
		end
		if newline == false then
			newline = ""
		else
			newline = "\n"
		end

		meta:set_string("output", meta:get_string("output")..newline..
			contents)
	end

	-- [function] Print to the computer debug buffer
	function env.print_debug(msg)
		return digicompute.c:print_debug(pos, msg)
	end

	-- [function] Set help text shown when hovering over question mark button
	function env.set_help(value)
		if not value or type(value) ~= "string" then
			value = "Type a command and press enter."
		end

		return meta:set_string("help", value)
	end

	-- [function] Get an attribute from the computer meta
	function env.get_attr(key)
		return meta:to_table().fields[key] or nil
	end

	-- [function] Get the value of the output formspec field
	function env.get_output()
		return meta:get_string("output") or nil
	end

	-- [function] Set the value of the output formspec field
	function env.set_output(value)
		return meta:set_string("output", value)
	end

	-- [function] Toggle whether the output area can be edited
	function env.set_output_editable(bool)
		if bool == true then
			meta:set_string("output_editable", "true")
		else
			meta:set_string("output_editable", "false")
		end
	end

	-- [function] Get the value of the input formspec field
	function env.get_input()
		return meta:get_string("input") or nil
	end

	-- [function] Set the value of the input formspec field
	function env.set_input(value)
		return meta:set_string("input", value)
	end

	-- [function] Get a value from the OS table
	function env.get_os(key)
		return minetest.deserialize(meta:get_string("os"))[key] or nil
	end

	-- [function] Set the value of one of the allowed keys in the OS table
	function env.set_os(key, value)
		local allowed_keys = {
			clear = true,
			off = true,
			reboot = true,
			prefix = true,
		}

		if allowed_keys[key] == true then
			local table = minetest.deserialize(meta:get_string("os")) or {}
			table[key] = value
			return meta:set_string("os", minetest.serialize(table))
		else
			return false
		end
	end

	-- [function] Refresh the computer formspec
	function env.refresh()
		local current_user = meta:get_string("current_user")
		if current_user ~= "" then
			local player = minetest.get_player_by_name(current_user)
			if player then
				return digicompute.c:open(pos, player)
			end
		end
	end

	-- [function] Run a string representing Lua code within the environment
	function env.run(code, ...)
		return digicompute.c:run_code(pos, code, ...)
	end

	-- [function] Change the file that is run when input is given
	function env.set_run(run_path)
		if run_path then
			if digicompute.builtin.exists(cpath..run_path) then
				meta:set_string("run", run_path)
			end
		else
			meta:set_string("run", "os/env.lua")
		end
	end

	--- Filesystem-Related Functions ---

	-- [function] Check if a file exists
	function env.fs.exists(internal_path)
		return digicompute.builtin.exists(cpath..internal_path)
	end

	-- [function] Create a file
	function env.fs.create(internal_path)
		return digicompute.builtin.create(cpath..internal_path)
	end

	-- [function] Remove a file
	function env.fs.remove(internal_path)
		return os.remove(cpath..internal_path)
	end

	-- [function] Write to a file
	function env.fs.write(internal_path, data, mode)
		if type(data) ~= "string" then
			data = dump(data)
		end
		return digicompute.builtin.write(cpath..internal_path, data, mode)
	end

	-- [function] Read from a file
	function env.fs.read(internal_path)
		return digicompute.builtin.read(cpath..internal_path)
	end

	-- [function] List the contents of a directory
	function env.fs.list(internal_path)
		return digicompute.builtin.list(cpath..internal_path)
	end

	-- [function] Copy a file
	function env.fs.copy(original, new)
		return digicompute.builtin.copy(cpath..original, cpath..new)
	end

	-- [function] Create a directory
	function env.fs.mkdir(internal_path)
		return digicompute.builtin.mkdir(cpath..internal_path)
	end

	-- [function] Remove a directory
	function env.fs.rmdir(internal_path)
		return digicompute.builtin.rmdir(cpath..internal_path)
	end

	-- [function] Copy a directory
	function env.fs.cpdir(original, new)
		return digicompute.builtin.cpdir(cpath..original, cpath..new)
	end

	-- [function] Read the contents of a file and run it as Lua code
	function env.fs.run(internal_path, ...)
		return digicompute.c:run_file(pos, internal_path, ...)
	end

	-- [function] Create a settings object
	function env.fs.read_settings(internal_path)
		local fpath = cpath..internal_path
		if digicompute.builtin.exists(fpath) then
			return Settings(fpath)
		end
	end

	return env -- Return custom env functions
end

---------------------------
----- ENVIRONMENT API -----
---------------------------

-- [function] Make environment
function digicompute.c:make_env(pos)
	assert(pos, "digicompute.c:make_env missing position")
	local meta = minetest.get_meta(pos)
	local id = meta:get_string("id")

	-- if an environment for this computer has already been generated, return it instead
	if environments[id] then
		return environments[id]
	end

	local env = digicompute.env()
	local custom_env = create_env_table(meta, pos)
	-- Custom custom env with default environment table
	for k, v in pairs(custom_env) do
		env[k] = v
	end

	environments[id] = env
	return environments[id]
end

-- [function] Get environment
function digicompute.c:get_env(pos)
	local id = minetest.get_meta(pos):get_string("id")
	return environments[id]
end

-- [function] Remove environment
function digicompute.c:remove_env(pos)
	environments[minetest.get_meta(pos):get_string("id")] = nil
	return true
end

-- [function] run code
function digicompute.c:run_code(pos, code, ...)
	local env     = digicompute.c:make_env(pos)
	local ok, res = digicompute.run_code(code, env, ...)
	digicompute.c:print_debug(pos, "Run Code, Success: "..dump(ok)..
		", Message: "..dump(res))
	return ok, res
end

-- [function] run file
function digicompute.c:run_file(pos, internal_path, ...)
	local complete_path = minetest.get_meta(pos):get_string("path")..internal_path
	local env           = digicompute.c:make_env(pos)
	local ok, res       = digicompute.run_file(complete_path, env, ...)
	digicompute.c:print_debug(pos, "Run File ("..internal_path.."), Success: "..
		dump(ok)..", Message: "..dump(res))
	return ok, res
end
