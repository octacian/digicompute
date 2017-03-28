-- cmd: help --

local params = ...
local bin    = get_userdata("bin")

if params[1] == "all" then
  for name, info in pairs(bin) do
    local params = ""
    if info.params then
      params = " "..info.params
    end

    print(name..params..": "..info.description)
  end
else
  print("Specify a command to get help for or use help all to view help for all commands.")
end
