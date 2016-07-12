-- digiterm/init.lua
digiterm = {}
-- variables
digiterm.modpath = minetest.get_modpath("digiterm") -- modpath
local modpath = digiterm.modpath -- modpath pointer

if not minetest.get_modpath("datalib") then dofile(modpath.."/data.lua") end -- load data api if not datalib mod
dofile(modpath.."/os.lua") -- load os api
dofile(modpath.."/api.lua") -- load api
dofile(modpath.."/nodes.lua") -- load nodes
