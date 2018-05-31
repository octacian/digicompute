-- cmd: help --

local params = ...
local bin    = get_userdata("bin")
local param  = params[1]

-- [local function] Print help
local function print_h(name, info)
	local cparams = ""
	if info.params then
		cparams = " "..info.params
	end

	print(name..cparams..": "..info.description)
end

if param == "all" then
	for name, info in pairs(bin) do
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
