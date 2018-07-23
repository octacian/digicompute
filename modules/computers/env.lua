-- computers/env.lua

local environments = {}

-----------------------
----- ENVIRONMENT -----
-----------------------

-- [function] Make environment
function digicompute.c:make_env(pos)
	assert(pos, "digicompute.c:make_env missing position")
	local meta = minetest.get_meta(pos)
	local id = meta:get_string("id")

	-- if an environment for this computer has already been generated, return it instead
	if environments[id] then
		return environments[id]
	end

	local cpath = meta:get_string("path")

	-- Main Environment Functions

	local main = {}

	-- [function] print
	function main.print(contents, newline)
		if type(contents) ~= "string" then
			contents = dump(contents)
		end
		if newline == false then
			newline = ""
		else
			newline = "\n"
		end

		meta:set_string("output", meta:get_string("output")..newline..contents)
	end
	-- [function] set help
	function main.set_help(value)
		if not value or type(value) ~= "string" then
			value = "Type a command and press enter."
		end

		return meta:set_string("help", value)
	end
	-- [function] get attribute
	function main.get_attr(key)
		return meta:to_table().fields[key] or nil
	end
	-- [function] get output
	function main.get_output()
		return meta:get_string("output") or nil
	end
	-- [function] set output
	function main.set_output(value)
		return meta:set_string("output", value)
	end
	-- [function] set whether output is writable
	function main.set_output_editable(bool)
		if bool == true then
			meta:set_string("output_editable", "true")
		else
			meta:set_string("output_editable", "false")
		end
	end
	-- [function] get input
	function main.get_input()
		return meta:get_string("input") or nil
	end
	-- [function] set input
	function main.set_input(value)
		return meta:set_string("input", value)
	end
	-- [function] get os value
	function main.get_os(key)
		return minetest.deserialize(meta:get_string("os"))[key] or nil
	end
	-- [function] set os value
	function main.set_os(key, value)
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
	-- [function] refresh
	function main.refresh()
		local current_user = meta:get_string("current_user")
		if current_user ~= "" then
			local player = minetest.get_player_by_name(current_user)
			if player then
				return digicompute.c:open(pos, player)
			end
		end
	end
	-- [function] run code
	function main.run(code, ...)
		return digicompute.c:run_code(pos, code, ...)
	end
	-- [function] set file to be run when input is submitted
	function main.set_run(run_path)
		if run_path then
			if digicompute.builtin.exists(cpath..run_path) then
				meta:set_string("run", run_path)
			end
		else
			meta:set_string("run", "os/main.lua")
		end
	end

	-- Filesystem Environment Functions

	local fs = {}

	-- [function] exists
	function fs.exists(internal_path)
		return digicompute.builtin.exists(cpath..internal_path)
	end
	-- [function] create file
	function fs.create(internal_path)
		return digicompute.builtin.create(cpath..internal_path)
	end
	-- [function] remove file
	function fs.remove(internal_path)
		return os.remove(cpath..internal_path)
	end
	-- [function] write to file
	function fs.write(internal_path, data, mode)
		if type(data) ~= "string" then
			data = dump(data)
		end
		return digicompute.builtin.write(cpath..internal_path, data, mode)
	end
	-- [function] read file
	function fs.read(internal_path)
		return digicompute.builtin.read(cpath..internal_path)
	end
	-- [function] list directory contents
	function fs.list(internal_path)
		return digicompute.builtin.list(cpath..internal_path)
	end
	-- [function] copy file
	function fs.copy(original, new)
		return digicompute.builtin.copy(cpath..original, cpath..new)
	end
	-- [function] create directory
	function fs.mkdir(internal_path)
		return digicompute.builtin.mkdir(cpath..internal_path)
	end
	-- [function] remove directory
	function fs.rmdir(internal_path)
		return digicompute.builtin.rmdir(cpath..internal_path)
	end
	-- [function] copy directory
	function fs.cpdir(original, new)
		return digicompute.builtin.cpdir(cpath..original, cpath..new)
	end
	-- [function] run file
	function fs.run(internal_path, ...)
		return digicompute.c:run_file(pos, internal_path, ...)
	end
	-- [function] Settings
	function main.Settings(internal_path)
		local fpath = cpath..internal_path
		if digicompute.builtin.exists(fpath) then
			return Settings(fpath)
		end
	end

	-- Get default env table

	local env = digicompute.env()

	env.fs = fs

	for k, v in pairs(main) do
		env[k] = v
	end

	env.ram = {} -- RAM table, replacement for userdata

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
	return ok, res
end

-- [function] run file
function digicompute.c:run_file(pos, internal_path, ...)
	local complete_path = minetest.get_meta(pos):get_string("path")..internal_path
	local env           = digicompute.c:make_env(pos)
	local ok, res       = digicompute.run_file(complete_path, env, ...)
	return ok, res
end
