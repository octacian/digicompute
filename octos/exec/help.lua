-- cmd: help --

local params = ...
local param  = params[1]
local bin = ram.bin

--[local function] Sort the help list alphabetically
local function sort(list)
	-- Order map
	local map = {["0"] = 1, ["1"] = 2, ["2"] = 3, ["3"] = 4, ["4"] = 5, ["5"] = 6, ["6"] = 7,
		["7"] = 8, ["8"] = 9, ["9"] = 10, a = 11, b = 12, c = 13, d = 14, e = 15, f = 16, g = 17,
		h = 18, i = 19, j = 20, k = 21, l = 22, m = 23, n = 24, o = 25, p = 26, q = 27, r = 28,
		s = 29, t = 30, u = 31, v = 32, w = 33, x = 34, y = 35, z = 36}

	local keys = {}
	for k in pairs(list) do keys[#keys + 1] = k end

	-- Detect sort order and sort using custom comparison functions
	table.sort(keys, function(a, b) return map[a:sub(1, 1):lower()] < map[b:sub(1, 1):lower()] end)

	-- Return iterator function
	local i = 0
	return function()
		i = i + 1
		if keys[i] then
			return keys[i], list[keys[i]]
		end
	end
end

-- [local function] Print help
local function print_h(name, info)
	local cparams = ""
	if info.params then
		cparams = " "..info.params
	end

	print(name..cparams..": "..info.description)
end

if param == "all" then
	for name, info in sort(bin) do
		print_h(name, info)
	end
elseif not param or param == "" then
	print("Specify a command to get help for or use help all to view help for all commands.")
else
	if bin[param] then
		print_h(param, bin[param])
	else
		print(param..": command not found")
	end
end
