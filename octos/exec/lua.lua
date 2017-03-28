local params = ...
local code = (table.concat(params, " "))

local res = run(code)

if not res then
  print("Error: Could not run `"..code.."`")
end
