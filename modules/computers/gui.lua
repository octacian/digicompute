-- computers/gui.lua

local path      = digicompute.path
local main_path = path.."computers/"

local computers = digicompute.loaded_computers

-- [local function] Wrap text inserting a comma after a line exceeds the limit
local function prepare_text(str, limit)
	if type(str) == "string" then
		local res = ""
		local newline = false
		local line_length = 0
		for c in str:gmatch(".") do
			-- if newline is true, wait for a space or 10 extra characters to insert a newline
			if newline then
				if c == " " or (line_length - limit) > 10 then
					res = res .. ","
					newline = false
					line_length = 0
				else
					res = res .. c
					line_length = line_length + 1
				end
			-- elseif character is an unescaped break, reset line length
			elseif c == "," and res:sub(-1) ~= "\\" then
				line_length = 0
				newline = false
				res = res .. c
			-- else, increment line length
			else
				line_length = line_length + 1
				-- if line is too long, set to break at next space
				if line_length > limit then
					newline = true
				end

				res = res .. c
			end
		end

		return res
	end
end

-------------------
---- FORMSPECS ----
-------------------

local computer_contexts = {}

local tabs = {
	"main",
	"debug",
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
				"field_close_on_enter[name;false]"..
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
				output = prepare_text(table.concat(output, ","), meta:get_int("wrap_limit"))
				output =
					"tableoptions[background=#000000FF;highlight=#00000000;border=false]"..
					"table[-0.25,-0.38;10.38,11.17;list_credits;"..output..";"..#output.."]"
			end

			return
				"size[10,11]"..
				"tabheader[0,0;tabs;Command Line,Debug Console,Settings;1]"..
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

			-- Hand values over to operating system
			if fields.input or fields.key_enter_field == "name" then
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
		end,
	},
	debug = {
		get = function(pos)
			local meta = minetest.get_meta(pos)
			local debug = minetest.deserialize(meta:get_string("debug"))
			local length = 0
			-- Escape lines
			for _, l in pairs(debug) do
				debug[_] = minetest.formspec_escape(l)
				length = length + 1
			end
			-- Concatenate and wrap
			debug = prepare_text(table.concat(debug, ","), meta:get_int("wrap_limit"))

			return
				"size[10,11]"..
				"tabheader[0,0;tabs;Command Line,Debug Console,Settings;2]"..
				default.gui_bg_img..
				"tableoptions[background=#000000FF;highlight=#00000000;border=false]"..
				"table[-0.25,-0.38;10.38,11.17;debug;"..debug..";"..length.."]"..
				"button[-0.28,10.22;10.6,2;clear;Clear Debug Console]"
		end,
		handle = function(pos, player, fields)
			if digicompute.c:handle_tabs(pos, player, fields) then return end

			if fields.clear then
				local meta = minetest.get_meta(pos)
				meta:set_string("debug", minetest.serialize({})) -- Clear debug buffer
				digicompute.c:open(pos, player) -- Refresh formspec
			end
		end,
	},
	settings = {
		get = function(pos)
			local meta = minetest.get_meta(pos)
			local limit = tostring(meta:get_int("wrap_limit"))
			local wrap_msg = "Wrap text after (default: 90; min: 10):"
			wrap_msg = minetest.formspec_escape(wrap_msg)

			return
				"size[10,11]"..
				"tabheader[0,0;tabs;Command Line,Debug Console,Settings;3]"..
				default.gui_bg_img..
				"button[0.5,0.25;9,1;reset;Reset Filesystem]"..
				"tooltip[reset;Wipes all files and OS data replacing it with the basic octOS.]"..
				"field[0.8,1.7;7,1;wrap_limit;"..wrap_msg..";"..limit.."]"..
				"field_close_on_enter[wrap_limit;false]"..
				"tooltip[wrap_limit;Number of characters after which to wrap text.]"..
				"button[7.5,1.4;1,1;wrap_save;Save]"..
				"tooltip[wrap_save;Save wrap limit]"..
				"button[8.5,1.4;1,1;wrap_reset;Reset]"..
				"tooltip[wrap_reset;Reset wrap limit to default]"..

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
			elseif fields.key_enter_field == "wrap_limit" or fields.wrap_save then
				if fields.wrap_limit == "" then
					digicompute.c:open(pos, player)
				else
					local new_limit = tonumber(fields.wrap_limit)
					if new_limit and new_limit >= 10 then
						meta:set_int("wrap_limit", new_limit)
						digicompute.c:print_debug(pos, "Set wrap limit to "..new_limit)
					else
						digicompute.c:open(pos, player)
					end
				end
			elseif fields.wrap_reset then
				meta:set_int("wrap_limit", 90)
				digicompute.c:print_debug(pos, "Reset wrap limit to 90")
				digicompute.c:open(pos, player)
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

			-- Set current user
			digicompute.c:set_user(pos, name)

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
	local name = player:get_player_name()

	if formname[1] == "digicompute" and digicompute.c.forms[formname[2]] then
		local computer = computers[computer_contexts[name]]

		if computer then
			local pos = computer.pos
			local meta = minetest.get_meta(pos)

			-- if formspec quit, remove current user
			if fields.quit == "true" then
				digicompute.c:unset_user(pos, name)
			end

			-- if input is from the current user, process
			if name == meta:get_string("current_user") then
				digicompute.c.forms[formname[2]].handle(pos, player, fields)
			elseif not fields.quit then -- elseif not already closed, close formspec
				minetest.close_formspec(name, formname)
			end
		else
			minetest.chat_send_player(player:get_player_name(), "Computer could not be found!")
		end
	end
end)
