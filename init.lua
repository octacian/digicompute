-- digicompute/init.lua
digicompute = {}

digicompute.VERSION = 0.1
digicompute.RELEASE_TYPE = "beta"

digicompute.path = minetest.get_worldpath().."/digicompute/" -- digicompute directory
digicompute.modpath = minetest.get_modpath("digicompute") -- modpath
local modpath = digicompute.modpath -- modpath pointer

-- Load builtin
dofile(modpath.."/builtin.lua")

-- Logger
function digicompute.log(content, log_type)
  assert(content, "digicompute.log content nil")
  if log_type == nil then log_type = "action" end
  minetest.log(log_type, "[digicompute] "..content)
end

-- Create mod directory inside world directory
digicompute.builtin.mkdir(digicompute.path)

-- Load environment utilities
dofile(modpath.."/env.lua")

-- Load API-like resources
dofile(modpath.."/c_api.lua") -- Computer API

-- Load registration code
dofile(modpath.."/computers.lua") -- Computers
