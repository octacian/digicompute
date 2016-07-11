-- digiterm/init.lua
digiterm = {}
local modpath = minetest.get_modpath("digiterm")
dofile(modpath.."/api.lua")
dofile(modpath.."/nodes.lua")

--[[
-- digiterm formspec
local function digiterm_formspec(output, input)
	return 'size[10,11] textarea[.25,.25;10,10.5;output;;'..output..'] button[0,9.5;10,1;update;update] field[.25,10.75;9,1;input;;'..input..'] button[9,10.5;1,1;submit;submit]'
end

-- refresh formspec
local function hacky_quote_new_digiterm_formspec(startspace)
	return (startspace and ' ' or '')..digiterm_formspec('${output}', '${input}');
end

-- basic digiterm
minetest.register_node('digiterm:basic', {
	description = "digiterm",
	tiles = {'digiterm_side.png', 'digiterm_side.png', 'digiterm_side.png', 'digiterm_side.png', 'digiterm_side.png', 'digiterm_front.png'},
	paramtype2 = 'facedir',
	groups = {cracky = 2},
	sounds = default.node_sound_stone_defaults(),
	-- digiline registers
	digiline = {
		receptor = {},
		effector = {
			action = function(pos, node, channel, msg)
				local meta = minetest.get_meta(pos);
				--ignore anything that isn't our channel
				if channel ~= meta:get_string('channel') then return end
				--if it's a string, append to the end of our output string
				if type(msg) == 'string' then meta:set_string('output', meta:get_string('output')..msg);
				--it may also be a control code; check if it's a table with a 'code' member
				elseif type(msg) == 'table' and msg.code then
					--the code 'cls' clears out the output
					if msg.code == "clear" then meta:set_string('output', ''); end
				end
			end
		},
	},
	on_construct = function(pos) -- set default meta/formspec
		local meta = minetest.get_meta(pos); -- get meta
		-- initialize the input and output buffers
		meta:set_string('output', '');
		meta:set_string('input', '');
		-- initial channel specification formspec
		meta:set_string('formspec', 'field[channel;channel;${channel}]');
		-- init on blank channel
		meta:set_string('channel', '');
	end,
	on_receive_fields = function(pos, formname, fields, sender) -- when fields recieved
		local meta = minetest.get_meta(pos);
		-- if channel provided, set it
		if fields.channel then
			meta:set_string("channel", fields.channel);
			-- replace with operating formspec
			meta:set_string('formspec', hacky_quote_new_digiterm_formspec(false));
			return; -- end callback
		end
		-- if submit pressed, reset and send
		if fields.submit then
			digiline:receptor_send(pos, digiline.rules.default, meta:get_string('channel'), fields.input); -- send via digilines
			meta:set_string('input', ''); -- reset
		else -- don't reset input
			meta:set_string('input', fields.input); -- keep input
		end
		-- refresh formspec
		meta:set_string('formspec', hacky_quote_new_digiterm_formspec(meta:get_string('formspec'):sub(0, 1) ~= ' '));
	end,
});

-- creation and usage of node positions encoded into formspec names
local function make_secure_digiterm_formspec_name(pos)
	return 'digitermspec{x='..tostring(pos.x)..',y='..tostring(pos.y)..',z='..tostring(pos.z)..'}';
end
local function retrieve_secure_digiterm_pos(formname)

	--try to pull the vector out of the form name
	local possstr;
	posstr = formname:match('^digitermspec({x=%-?%d*%.?%d*,y=%-?%d*%.?%d*,z=%-?%d*%.?%d*})$');

	--if we didn't get one, give up
	if not posstr then return; end

	--otherwise, grab the position
	return loadstring('return '..posstr)();
end

-- secure digiterm
minetest.register_node('digiterm:secure', {
	description = 'secure digiterm',
	tiles = {'digiterm_side.png', 'digiterm_side.png', 'digiterm_side.png', 'digiterm_side.png', 'digiterm_side.png', 'digiterm_secure_front.png'},
	paramtype2 = 'facedir',
	groups = {cracky = 2},
	sounds = default.node_sound_stone_defaults(),
	-- digiline register
	digiline = {
		receptor = {},
		effector = {
			action = function(pos, node, channel, msg)
				local meta = minetest.get_meta(pos); -- get meta
				-- ignore signal if incorrect channel
				if channel ~= meta:get_string('channel') then return end
				-- get player name
				if type(msg) == 'table' and msg.player then
					local player = msg.player == 'string' and msg.player; -- get player name as string
					msg = msg.msg or msg; -- set msg
				end
				-- if player was not determined, use last player
				if not player then player = meta:get_string('last_player'); end
				-- if player still blank, return and end
				if not player then return; end
				-- if player has no session, return and end
				if not meta:get_int(player..'_seq') then return; end
				-- if msg is string, append to end of player name
				if type(msg) == 'string' then meta:set_string(player..'_output', meta:get_string(player..'_output')..msg);
				elseif type(msg) == 'table' and msg.code then -- handle control codes
					-- the code 'cls' clears out the output
					if msg.code == 'cls' then meta:set_string(player..'_output', ''); end
				end
			end
		},
	},
	on_construct = function(pos) -- set default meta/formspec
		local meta = minetest.get_meta(pos); -- get meta
		-- initialize the input and output buffers
		meta:set_string('output', '');
		meta:set_string('input', '');
		-- initial channel specification formspec
		meta:set_string('formspec', 'field[channel;channel;${channel}]');
		-- init on blank channel
		meta:set_string('channel', '');
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.get_meta(pos); -- get meta
		-- if channel provided, set it
		if fields.channel then
			meta:set_string('channel', fields.channel); -- set channel
			meta:set_string('formspec', ''); -- remove formspec
		end
	end,
	on_rightclick = function(pos, node, player, itemstack) -- on rightclick
		local meta = minetest.get_meta(pos); -- get meta
		local name = player:get_player_name(); -- get player name
		meta:set_string('last_player', name); -- log as last visitor
		-- get the input, output, and current message sequence number for this player
		local output, input, seq = meta:get_string(name..'_output'), meta:get_string(name..'_input'), meta:get_int(name..'_seq');
		-- re-initialize nil values
		if not output or not input or not seq then
			output, input, seq = '', '', 0;
			meta:set_string(name..'_output', output);
			meta:set_string(name..'_input', input);
			meta:set_int(name..'_seq', seq);
		end
		-- send message to network
		digiline:receptor_send(pos, digiline.rules.default, meta:get_string('channel'), function() return {player=name, seq=seq, code='init'} end);
		meta:set_int(name..'_seq', seq + 1); -- bump sequence number
		minetest.show_formspec(name, make_secure_digiterm_formspec_name(pos), digiterm_formspec(output, input)); -- show formspec
		return itemstack;
	end,
});

-- pick up formspec submissions
minetest.register_on_player_receive_fields(function (player, formname, fields)
	-- attempt to obtain coordinates from formname
	local pos = retrieve_secure_digiterm_pos(formname);
	-- if that failed, ignore
	if not pos then return false; end
	-- get metadata and player name
	local meta = minetest.get_meta(pos);
	local name = player:get_player_name();
	-- if submit, send msg and resut input
	if fields.submit then
		local seq = meta:get_int(name..'_seq');
		digiline:receptor_send(pos, digiline.rules.default, meta:get_string('channel'), function() return {player=name, seq=seq, msg=fields.input} end);
		meta:set_string(name..'_input', '');
		meta:set_int(name..'_seq', seq + 1); -- bump the sequence number
	else -- else, don't change input
		meta:set_string(name..'_input', fields.input);
	end
	-- refresh formspec
	minetest.show_formspec(name, make_secure_digiterm_formspec_name(pos), digiterm_formspec(meta:get_string(name..'_output'), meta:get_string(name..'_input')));
end);

-- [recipe] basic digiterm
minetest.register_craft({
	output = "digiterm:basic",
	recipe = {
		{'default:glass', 'default:glass', 'default:glass'},
		{'digilines:wire_std_00000000', 'mesecons_luacontroller:luacontroller0000', 'digilines:wire_std_00000000'},
		{'default:stone', 'default:steel_ingot', 'default:stone'},
	},
})

-- [recipe] secure digiterm
minetest.register_craft({
	output = "digiterm:secure",
	recipe = {
		{'', 'default:steel_ingot', ''},
		{'default:steel_ingot', 'digiterm:digiterm', 'default:steel_ingot'},
		{'', 'default:steel_ingot', ''},
	},
});]]--
