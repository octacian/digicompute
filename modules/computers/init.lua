-- computers/init.lua

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

-- [function] Set current user
function digicompute.c:set_user(pos, name)
	current_users[name] = pos

	local meta = minetest.get_meta(current_users[name])
	local current_user = meta:get_string("current_user")
	-- Check if there was already another user
	if current_user ~= "" and current_user ~= name then
		if minetest.get_player_by_name(current_user) then
			local formname = meta:get_string("formname")
			-- if formname is defined, close that formspec
			if formname ~= "" then
				minetest.close_formspec(current_user, "digicompute:"..formname)
			end
			-- Remove from current users
			current_users[current_user] = nil
			minetest.log("Removed current user: "..dump(current_user))
		end
	end
	-- Update node meta entry
	meta:set_string("current_user", name)
end

-- [function] Unset current user
function digicompute.c:unset_user(pos, name)
	if current_users[name] then
		local meta = minetest.get_meta(current_users[name])
		-- Clear node meta entry
		meta:set_string("current_user", nil)
		current_users[name] = nil -- Remove from table

		local formname = meta:get_string("formname")
		-- if formname is defined, close that formspec
		if formname ~= "" then
			minetest.close_formspec(name, "digicompute:"..formname)
		end
	end
end

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

digicompute.loaded_computers = computers

-----------------------------
-- Load External Resources --
-----------------------------

local module_path = digicompute.get_module_path("computers")

-- Load env
dofile(module_path.."/env.lua")
-- Load GUI
dofile(module_path.."/gui.lua")
-- Load API
dofile(module_path.."/api.lua")
-- Load nodes (computers)
dofile(module_path.."/nodes.lua")
