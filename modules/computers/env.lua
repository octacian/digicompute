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
		system = {}, -- Limited system table
	}

	--- System Functions ---

	-- [function] Turn computer off
	function env.system.shutdown()
		local current_user = meta:get_string("current_user")
		if current_user ~= "" then
			local player = minetest.get_player_by_name(current_user)
			if player then
				return digicompute.c:off(pos, player)
			end
		end
	end

	-- [function] Reboot computer
	function env.system.reboot()
		local current_user = meta:get_string("current_user")
		if current_user ~= "" then
			local player = minetest.get_player_by_name(current_user)
			if player then
				return digicompute.c:reboot(pos, player)
			end
		end
	end

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
			meta:set_string("run", "os/main.lua")
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

	--- Metatables ---

	local ram_shadow = minetest.deserialize(meta:get_string("ram"))
	-- Define RAM metatable
	local ram_mt = {
		-- Save to meta as well as to shadow table
		__newindex = function(table, key, value)
			local vtype = type(value)
			-- Prevent saving functions and userdata
			if vtype == "function" or vtype == "userdata" then
				local msg = "Error: Functions and userdata cannot be stored in the RAM."
				env.print(msg)
				env.print_debug(msg)
			else -- else, save
				rawset(ram_shadow, key, value) -- Save to table
				-- Save to metadata
				meta:set_string("ram", minetest.serialize(ram_shadow))
			end
		end,
		-- Always fetch values from the shadow table
		__index = function(table, key)
			return ram_shadow[key]
		end,
	}
	setmetatable(env.ram, ram_mt)

	local system_shadow = minetest.deserialize(meta:get_string("system"))
	-- Define OS metatable
	local system_mt = {
		-- Ensure value is allowed and save to meta as well
		__newindex = function(table, key, value)
			local allowed_keys = {
				prefix = "string",
				input = "string",
				output = "string",
				output_editable = "boolean",
			}

			-- Ensure allowed
			if not allowed_keys[key] then
				local msg = "Error: "..key.. " is not an allowed key in the system table."
				env.print(msg)
				env.print_debug(msg)
			-- Ensure type
			elseif type(value) ~= allowed_keys[key] then
				local msg = "Error: "..key.." must be a "..allowed_keys[key]
				env.print(msg)
				env.print_debug(msg)
			else -- else, save
				-- Set input, output, and output editable separately
				if key == "input" or key == "output" or key == "output_editable" then
					rawset(system_shadow, key, value) -- Save to table

					local t = allowed_keys[key]
					-- if type is boolean, convert to string
					if t == "boolean" then t = "string" end
					-- Save separately to metadata
					meta["set_"..t](meta, key, _G["to"..t](value))
				else
					rawset(system_shadow, key, value) -- Save to table
					-- Save to metadata
					meta:set_string("system", minetest.serialize(system_shadow))
				end
			end
		end,
		-- Always fetch values from the shadow table
		__index = system_shadow,
	}
	setmetatable(env.system, system_mt)

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
