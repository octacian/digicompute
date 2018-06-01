-- computers/api.lua

digicompute.c = {}

local path      = digicompute.path
local main_path = path.."computers/"

-- Make computer directory
digicompute.builtin.mkdir(main_path)

-----------------------------
-- CURRENT USER MANAGEMENT --
-----------------------------

local current_users = {}

-- [event] remove current users on leave
minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	if current_users[name] then
		minetest.get_meta(current_users[name]):set_string("current_user", nil)
		current_users[name] = nil
	end
end)

-------------------
-- ID MANAGEMENT --
-------------------

local computers = {}

-- [function] load computers
function digicompute.load_computers()
	local res  = digicompute.builtin.read(path.."/computers.txt")
	if res then
		res = minetest.deserialize(res)
		if type(res) == "table" then
			computers = res
		end
	end
end

-- Load all computers
digicompute.load_computers()

-- [function] save computers
function digicompute.save_computers()
	digicompute.builtin.write(path.."/computers.txt", minetest.serialize(computers))
end

-- [function] generate new computer ID
function digicompute.c:new_id(pos)
	assert(type(pos) == "table", "digicompute.c:new_id requires a valid position")
	local meta = minetest.get_meta(pos)

	local function count()
		local c = 1
		for _, i in pairs(computers) do
			c = c + 1
		end
		return c
	end

	local id = "c_"..count()

	computers[id] = {
		pos = pos,
	}

	meta:set_string("id", id)
end

-- [event] save computers on shutdown
minetest.register_on_shutdown(digicompute.save_computers)

----------------------------------
-- MID-BOOT COMPUTER MANAGEMENT --
----------------------------------

-- Loop through all computers in a coroutine and check if
-- any were left in the midst of the boot process
local check_booting = coroutine.create(function()
	-- [function] Get node
	local function get_node(pos)
		local node = minetest.get_node_or_nil(pos)
		if node then return node end
		minetest.get_voxel_manip(pos, pos)
		return minetest.get_node(pos)
	end

	for id, c in pairs(computers) do
		if c.booting then
			local temp = get_node(c.pos)
			local ddef = minetest.registered_nodes[temp.name].digicompute
			if ddef.state == "off" or ddef.state == "bios" then
				local name, param2 = "digicompute:"..ddef.base, temp.param2
				digicompute.c:complete_boot(c.pos, id, name, param2)
			else
				c.booting = nil
			end
		end
	end
end)

-- Start coroutine
minetest.after(0, function()
	coroutine.resume(check_booting)
end)

-------------------
---- FORMSPECS ----
-------------------

local computer_contexts = {}

local tabs = {
	"main",
	"settings",
}

-- [function] handle tabs
function digicompute.c:handle_tabs(pos, player, fields)
	if fields.tabs then
		if digicompute.c:open(pos, player, tabs[tonumber(fields.tabs)]) then
			return true
		end
	end
end

digicompute.c.forms = {
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
					meta:set_string("run", "os/main.lua") -- Set default run file
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
	main = {
		get = function(pos)
			local meta = minetest.get_meta(pos)

			local last_start = meta:get_int("last_run_start")
			if last_start == 0 or last_start < meta:get_int("last_boot") then
				if meta:get_string("setup") == "true" then
					meta:set_int("last_run_start", os.time())
					digicompute.c:run_file(pos, "os/start.lua")
				end
			end

			local input    = minetest.formspec_escape(meta:get_string("input"))
			local help     = minetest.formspec_escape(meta:get_string("help"))
			local output   = meta:get_string("output")

			if meta:get_string("output_editable") == "true" then
				output = minetest.formspec_escape(output)
				output =
					"textarea[-0.03,-0.4;10.62,13.03;output;;"..output.."]"
			else
				output = output:split("\n", true)
				for i, line in ipairs(output) do
					output[i] = minetest.formspec_escape(line)
				end
				output =
					"tableoptions[background=#000000FF;highlight=#00000000;border=false]"..
					"table[-0.25,-0.38;10.38,11.17;list_credits;"..table.concat(output, ",")..";"..#output.."]"
			end

			return
				"size[10,11]"..
				"tabheader[0,0;tabs;Command Line,Settings;1]"..
				"bgcolor[#000000FF;]"..
				output..
				"button[9.56,10.22;0.8,2;help;?]"..
				"tooltip[help;"..help.."]"..
				"field[-0.02,10.99;10.1,1;input;;"..input.."]"..
				"field_close_on_enter[input;false]"
		end,
		handle = function(pos, player, fields)
			if digicompute.c:handle_tabs(pos, player, fields) then return end

			local meta   = minetest.get_meta(pos) -- get meta
			local os     = minetest.deserialize(meta:get_string("os")) or {}
			local prefix = os.prefix or ""

			if fields.input or fields.key_enter_field == "name" then
				if fields.input == os.clear then
					meta:set_string("output", prefix)
					meta:set_string("input", "")
					digicompute.c:open(pos, player)
				elseif fields.input == os.off then digicompute.c:off(pos, player)
				elseif fields.input == os.reboot then digicompute.c:reboot(pos, player)
				else -- else, turn over to os
					-- Set meta value(s)
					meta:set_string("input", fields.input)
					if fields.output then
						meta:set_string("output", fields.output)
					end

					local run = meta:get_string("run")
					if run == "" then run = "os/main.lua" end
					-- Get and run current "run file" (default: os/main.lua)
					digicompute.c:run_file(pos, run)
				end
			end
		end,
	},
	settings = {
		get = function(pos)
			return
				"size[10,11]"..
				"tabheader[0,0;tabs;Command Line,Settings;2]"..
				default.gui_bg_img..
				"button[0.5,0.25;9,1;reset;Reset Filesystem]"..
				"tooltip[reset;Wipes all files and OS data replacing it with the basic octOS.]"..
				"label[0.5,10.35;digicompute Version: "..tostring(digicompute.VERSION)..", "..
					digicompute.RELEASE_TYPE.."]"..
				"label[0.5,10.75;(c) Copywrite "..tostring(os.date("%Y")).." "..
					"Elijah Duffy <theoctacian@gmail.com>]"
		end,
		handle = function(pos, player, fields)
			if digicompute.c:handle_tabs(pos, player, fields) then return end

			local meta = minetest.get_meta(pos)

			if fields.reset then
				-- Clear buffers
				meta:set_string("output", "")
				meta:set_string("input", "")

				-- Reset Filesystem
				digicompute.c:reinit(pos)

				-- Rerun start.lua
				meta:set_int("last_run_start", os.time())
				digicompute.c:run_file(pos, "os/start.lua")
			end
		end,
	},
}

-- [function] open formspec
function digicompute.c:open(pos, player, formname)
	local meta = minetest.get_meta(pos)
	local user = meta:get_string("current_user")
	local name = player:get_player_name()

	if user == "" or user == name then
		if meta:get_string("setup") == "true" then
			local meta_formname = meta:get_string("formname")

			if not formname and meta_formname and meta_formname ~= "" then
				formname = meta_formname
			end
		else
			formname = "naming"
		end

		formname   = formname or "main"
		local form = digicompute.c.forms[formname]

		if form then
			if form.cache_formname ~= false then
				meta:set_string("formname", formname)
			end

			-- Add current user
			meta:set_string("current_user", name)
			current_users[name] = pos

			computer_contexts[name] = minetest.get_meta(pos):get_string("id")
			minetest.show_formspec(name, "digicompute:"..formname, form.get(pos, player))
			return true
		end
	else
		minetest.chat_send_player(name, minetest.colorize("red", "This computer is " ..
			"already in use by "..user))
	end
end

-- [event] on receive fields
minetest.register_on_player_receive_fields(function(player, formname, fields)
	formname = formname:split(":")

	if formname[1] == "digicompute" and digicompute.c.forms[formname[2]] then
		local computer = computers[computer_contexts[player:get_player_name()]]

		if computer then
			local pos = computer.pos

			-- if formspec quit, remove current user
			if fields.quit == "true" then
				minetest.get_meta(pos):set_string("current_user", nil)
				current_users[player:get_player_name()] = nil
			end

			digicompute.c.forms[formname[2]].handle(pos, player, fields)
		else
			minetest.chat_send_player(player:get_player_name(), "Computer could not be found!")
		end
	end
end)

----------------------
-- HELPER FUNCTIONS --
----------------------

-- [function] update infotext
function digicompute.c:infotext(pos)
	local meta = minetest.get_meta(pos)
	local state = minetest.registered_nodes[minetest.get_node(pos).name].digicompute.state

	if meta:get_string("setup") == "true" then
		meta:set_string("infotext", meta:get_string("name").." - "..state.."\n(owned by "
			..meta:get_string("owner")..")")
	else
		meta:set_string("infotext", "Unconfigured Computer - "..state.."\n(owned by "
			..meta:get_string("owner")..")")
	end
end

-- [function] initialize computer
function digicompute.c:init(pos)
	local meta = minetest.get_meta(pos)
	local new_path = meta:get_string("path")

	if new_path and new_path ~= "" then
		digicompute.builtin.mkdir(main_path..meta:get_string("owner"))
		digicompute.builtin.mkdir(new_path)
		digicompute.builtin.cpdir(digicompute.modpath.."/octos/", new_path.."os")
		digicompute.log("Initialized computer "..meta:get_string("id").." owned by "..
			meta:get_string("owner").." at "..minetest.pos_to_string(pos))
		digicompute.c:infotext(pos)
	end
end

-- [function] deinitialize computer
function digicompute.c:deinit(pos, clear_entry)
	local meta     = minetest.get_meta(pos)
	local old_path = meta:get_string("path")
	local owner    = meta:get_string("owner")

	if old_path and old_path ~= "" then
		digicompute.builtin.rmdir(old_path)
		digicompute.log("Deinitialized computer "..meta:get_string("id").." owned by "..
			meta:get_string("owner").." at "..minetest.pos_to_string(pos))

			if digicompute.builtin.list(main_path..owner).subdirs then
				digicompute.builtin.rmdir(main_path..owner)
			end
	end

	if clear_entry ~= false then
		local id = meta:get_string("id")
		computers[id] = nil
	end
end

-- [function] reinitialize computer (reset)
function digicompute.c:reinit(pos)
	digicompute.c:deinit(pos, false)
	digicompute.c:init(pos)
end

-- [function] complete computer boot process (swap from bios to on)
function digicompute.c:complete_boot(pos, index, name, param2)
	minetest.swap_node({x = pos.x, y = pos.y, z = pos.z}, {name = name.."_on", param2 = param2})

	-- Remove computer booting tag
	computers[index].booting = nil

	-- Update infotext
	digicompute.c:infotext(pos)
	-- Set last boot to the current time for later use on_rightclick to
	-- check if os/start.lua should be run
	minetest.get_meta(pos):set_int("last_boot", os.time())
end

-- [function] turn computer on
function digicompute.c:on(pos)
	local temp = minetest.get_node(pos)
	local ddef = minetest.registered_nodes[temp.name].digicompute
	if ddef.state == "off" then
		local name, param2 = temp.name, temp.param2

		-- Swap to Bios
		minetest.swap_node({x = pos.x, y = pos.y, z = pos.z}, {name = name.."_bios", param2 = param2}) -- set node to bios

		-- Update infotext
		digicompute.c:infotext(pos)

		-- Save event so that if the game is exited mid-boot, the boot
		-- process can be resumed immediately thereafter
		local id = minetest.get_meta(pos):get_string("id")
		computers[id].booting = true

		-- Swap to on node after 2 seconds
		minetest.after(2, function(pos_, index)
			digicompute.c:complete_boot(pos_, index, name, param2)
		end, vector.new(pos), id)
	end
end

-- [function] turn computer off
function digicompute.c:off(pos, player)
	local temp = minetest.get_node(pos) -- Get basic node information
	local offname = "digicompute:"..minetest.registered_nodes[temp.name].digicompute.base
	-- Swap node to off
	minetest.swap_node({x = pos.x, y = pos.y, z = pos.z}, {name = offname, param2 = temp.param2})
	-- Update infotext
	digicompute.c:infotext(pos)
	-- Close formspec if player object is provided
	if player and player.get_player_name then
		minetest.close_formspec(player:get_player_name(), "")
	end
	-- Clear update buffer
	minetest.get_meta(pos):set_string("output", "")
end

-- [function] reboot computer
function digicompute.c:reboot(pos, player)
	digicompute.c:off(pos, player)
	digicompute.c:on(pos)
end

-----------------------
----- ENVIRONMENT -----
-----------------------

-- [function] Make environment
function digicompute.c:make_env(pos)
	assert(pos, "digicompute.c:make_env missing position")
	local meta = minetest.get_meta(pos)
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
		return meta:get_string(key) or nil
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
	-- [function] get userdata value
	function main.get_userdata(key)
		local res = meta:get_string("userdata")
		return minetest.deserialize(res)[key] or nil
	end
	-- [function] set userdata value
	function main.set_userdata(key, value)
		local table = minetest.deserialize(meta:get_string("userdata")) or {}
		table[key] = value
		return meta:set_string("userdata", minetest.serialize(table))
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

	return env
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

----------------------
-- NODE DEFINITIONS --
----------------------

function digicompute.register_computer(itemstring, def)
	-- off
	minetest.register_node("digicompute:"..itemstring, {
		digicompute = {
			state = "off",
			base = itemstring,
		},
		drawtype = "nodebox",
		description = def.description,
		tiles = def.off_tiles,
		paramtype = "light",
		paramtype2 = "facedir",
		groups = {cracky = 2},
		drop = "digicompute:"..itemstring,
		sounds = default.node_sound_stone_defaults(),
		node_box = def.node_box,
		after_place_node = function(pos, player)
			local meta = minetest.get_meta(pos)
			meta:set_string("owner", player:get_player_name())
			meta:set_string("input", "")                               -- Initialize input buffer
			meta:set_string("output", "")                              -- Initialize output buffer
			meta:set_string("os", "")                                  -- Initialize OS table
			meta:set_string("userdata", "")                           -- Initialize userdata table
			meta:set_string("help", "Type a command and press enter.") -- Initialize help
			digicompute.c:new_id(pos)                                  -- Set up ID

			-- Update infotext
			digicompute.c:infotext(pos)
		end,
		on_rightclick = function(pos, node, player)
			digicompute.c:on(pos)
		end,
		on_destruct = function(pos)
			if minetest.get_meta(pos):get_string("name") then
				digicompute.c:deinit(pos)
			end
		end,
	})
	-- bios
	minetest.register_node("digicompute:"..itemstring.."_bios", {
		light_source = def.light_source or 7,
		digicompute = {
			state = "bios",
			base = itemstring,
		},
		drawtype = "nodebox",
		defription = def.defription,
		tiles = def.bios_tiles,
		paramtype = "light",
		paramtype2 = "facedir",
		groups = {cracky = 2, not_in_creative_inventory = 1},
		drop = "digicompute:"..itemstring,
		sounds = default.node_sound_stone_defaults(),
		node_box = def.node_box,
		on_destruct = function(pos)
			if minetest.get_meta(pos):get_string("name") then
				digicompute.c:deinit(pos)
			end
		end,
	})
	-- on
	minetest.register_node("digicompute:"..itemstring.."_on", {
		light_source = def.light_source or 7,
		digicompute = {
			state = "on",
			base = itemstring,
		},
		drawtype = "nodebox",
		description = def.defription,
		tiles = def.on_tiles,
		paramtype = "light",
		paramtype2 = "facedir",
		groups = {cracky = 2, not_in_creative_inventory = 1},
		drop = "digicompute:"..itemstring,
		sounds = default.node_sound_stone_defaults(),
		node_box = def.node_box,
		on_rightclick = function(pos, node, player)
			digicompute.c:open(pos, player)
		end,
		on_destruct = function(pos)
			if minetest.get_meta(pos):get_string("name") then
				digicompute.c:deinit(pos)
			end
		end,
	})
end
