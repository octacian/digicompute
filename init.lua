-- digicompute/init.lua
digicompute = {}

digicompute.VERSION = 0.5
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

-------------------
----- MODULES -----
-------------------

local loaded_modules = {}

local settings = Settings(modpath.."/modules.conf"):to_table()

-- [function] Get module path
function digicompute.get_module_path(name)
  local module_path = modpath.."/modules/"..name

  if digicompute.builtin.exists(module_path) then
    return module_path
  end
end

-- [function] Load module (overrides modules.conf)
function digicompute.load_module(name)
  if loaded_modules[name] ~= false then
    local module_path = digicompute.get_module_path(name)

    if module_path then
      if digicompute.builtin.exists(module_path.."/init.lua") then
        dofile(module_path.."/init.lua")
        loaded_modules[name] = true
        return true
      else
        digicompute.log("Module ("..name..") missing init.lua, could not load", "error")
      end
    else
      digicompute.log("Invalid module \""..name.."\"", "error")
    end
  else
    return true
  end
end

-- [function] Require module (does not override modules.conf)
function digicompute.require_module(name)
  if settings[name] and settings[name] ~= false then
    return digicompute.load_module(name)
  end
end

for name,enabled in pairs(settings) do
  if enabled ~= false then
    digicompute.load_module(name)
  end
end
