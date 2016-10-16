-- digicompute/api.lua
local modpath = digicompute.modpath -- modpath pointer
local path = digicompute.path -- path pointer

-- [function] refresh formspec
function digicompute.refresh(pos)
  local meta = minetest.get_meta(pos) -- get meta
  meta:set_string("formspec", digicompute.formspec(meta:get_string("input"), meta:get_string("output")))
end

dofile(modpath.."/env.lua") -- do env file

-- turn on
function digicompute.on(pos, node)
  local temp = minetest.get_node(pos) -- get node
  minetest.swap_node({x = pos.x, y = pos.y, z = pos.z}, {name = "digicompute:"..node.."_bios", param2 = temp.param2}) -- set node to bios
  minetest.after(3.5, function(pos_)
    minetest.swap_node({x = pos_.x, y = pos_.y, z = pos_.z}, {name = "digicompute:"..node.."_on", param2 = temp.param2}) -- set node to on after 5 seconds
  end, vector.new(pos))
  local meta = minetest.get_meta(pos) -- get meta
  -- if setup is not true, use set name formspec
  if meta:get_string("setup") ~= "true" then
    meta:set_string("formspec", digicompute.formspec_name("")) -- set formspec
  else -- use default formspec
		local fields = {
			input = meta:get_string("input"),
			output = meta:get_string("output"),
		}
    -- if not when_on, use blank
    if not digicompute.runfile(pos, path.."/"..meta:get_string("name").."/os/start.lua", "start", fields) then
      meta:set_string("formspec", digicompute.formspec("", "")) -- set formspec
    end
    digicompute.refresh(pos) -- refresh
  end
end

-- turn off
function digicompute.off(pos, node)
  local temp = minetest.get_node(pos) -- get node
  local meta = minetest.get_meta(pos) -- get meta
  meta:set_string("formspec", "") -- clear formspec
  minetest.swap_node({x = pos.x, y = pos.y, z = pos.z}, {name = "digicompute:"..node, param2 = temp.param2}) -- set node to off
end

-- reboot
function digicompute.reboot(pos, node)
  digicompute.off(pos, node)
  digicompute.on(pos, node)
end

-- clear
function digicompute.clear(field, pos)
  local meta = minetest.get_meta(pos) -- get meta
  meta:set_string(field, "") -- clear value
end

-- [function] run code (in sandbox env)
function digicompute.run(f, env)
  setfenv(f, env)
  local e, msg = pcall(f)
  if e == false then return msg end
end

-- [function] run file under env
function digicompute.runfile(pos, lpath, errloc, fields)
  local meta = minetest.get_meta(pos)
  local env = digicompute.create_env(pos, fields) -- environment
  local f = loadfile(lpath) -- load func
  local e = digicompute.run(f, env) -- run function
  -- if error, call error handle function and re-run start
  if e then
    digicompute.handle_error(pos, e, errloc) -- handle error
    local s = loadfile(path.."/"..meta:get_string("name").."/os/start.lua") -- load func
    digicompute.run(s, env) -- run func
    return false
  end
end

-- [function] handle error
function digicompute.handle_error(pos, msg, file)
  local meta = minetest.get_meta(pos) -- get meta
  local name = meta:get_string("name") -- get name

  -- [function] restore
  local function restore()
    -- if file is conf main or start, replace only
    if file == "conf" then
      datalib.copy(path.."/"..name.."/os/conf.lua", path.."/"..name.."/os/conf.old.lua")
      datalib.copy(modpath.."/bios/conf.lua", path.."/"..name.."/os/conf.lua")
    elseif file == "main" then
      datalib.copy(path.."/"..name.."/os/main.lua", path.."/"..name.."/os/main.old.lua")
      datalib.copy(modpath.."/bios/main.lua", path.."/"..name.."/os/main.lua")
    elseif file == "start" then
      datalib.copy(path.."/"..name.."/os/start.lua", path.."/"..name.."/os/start.old.lua")
      datalib.copy(modpath.."/bios/start.lua", path.."/"..name.."/os/start.lua")
    else -- else, restore all
      datalib.copy(path.."/"..name.."/os/conf.lua", path.."/"..name.."/os/conf.old.lua")
      datalib.copy(modpath.."/bios/conf.lua", path.."/"..name.."/os/conf.lua")
      datalib.copy(path.."/"..name.."/os/main.lua", path.."/"..name.."/os/main.old.lua")
      datalib.copy(modpath.."/bios/main.lua", path.."/"..name.."/os/main.lua")
      datalib.copy(path.."/"..name.."/os/start.lua", path.."/"..name.."/os/start.old.lua")
      datalib.copy(modpath.."/bios/start.lua", path.."/"..name.."/os/start.lua")
    end
  end

  meta:set_string("output", "Error: \n"..msg.."\n\nRestoring OS in 13 seconds. Files will remain.") -- set output
  digicompute.refresh(pos) -- refresh
  minetest.after(15, restore) -- after 15 seconds, call restore func
end

dofile(modpath.."/c_api.lua") -- do computer API file
