-- computers/api.lua

local path      = digicompute.path
local main_path = path.."computers/"

local computers = digicompute.loaded_computers

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

-------------------------
-- COMPUTER OPERATIONS --
-------------------------

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

-- [function] print to computer debug buffer
function digicompute.c:print_debug(pos, msg)
	if type(msg) ~= "string" then msg = dump(msg) end
	local meta = minetest.get_meta(pos)
	local debug = minetest.deserialize(meta:get_string("debug"))
	table.insert(debug, os.date("[%d/%m/%Y @ %H:%M] ")..msg)
	meta:set_string("debug", minetest.serialize(debug))
	return true
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
		digicompute.c:print_debug(pos, "Initialized")
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

	local id = meta:get_string("id")
	-- Remove saved environment
	digicompute.c:remove_env(pos)

	if clear_entry ~= false then
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
	-- Log boot in debug buffer
	digicompute.c:print_debug(pos, "Booted")
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
	local meta = minetest.get_meta(pos)
	-- Swap node to off
	minetest.swap_node({x = pos.x, y = pos.y, z = pos.z}, {name = offname, param2 = temp.param2})
	-- Update infotext
	digicompute.c:infotext(pos)
	-- Close formspec if player object is provided
	if player and player.get_player_name then
		minetest.close_formspec(player:get_player_name(), "")
	end
	-- Log action in debug buffer
	digicompute.c:print_debug(pos, "Shut down")
	-- Clear output buffer
	meta:set_string("output", "")
	-- Clear RAM
	meta:set_string("ram", minetest.serialize({}))
	-- Reset environment
	digicompute.c:remove_env(pos)
end

-- [function] reboot computer
function digicompute.c:reboot(pos, player)
	digicompute.c:off(pos, player)
	digicompute.c:on(pos)
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
			meta:set_string("debug", minetest.serialize({}))           -- Initialize debug buffer
			meta:set_string("os", "")                                  -- Initialize OS table
			meta:set_string("ram", minetest.serialize({}))             -- Initialize RAM preservation table
			meta:set_string("help", "Type a command and press enter.") -- Initialize help
			meta:set_string("output_editable", "false")                -- Initialize uneditable output
			meta:set_int("wrap_limit", 90)                             -- Initialize wrap chracter limit
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
