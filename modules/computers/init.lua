-- computers/init.lua

local module_path = digicompute.get_module_path("computers")

-- Load API
dofile(module_path.."/api.lua")
-- Load nodes (computers)
dofile(module_path.."/nodes.lua")
