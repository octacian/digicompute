local params = ...
local code = (table.concat(params, " "))

local ok, res = run(code)

if not ok then
	print("Error: "..res)
end
