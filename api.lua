-- digicompute/api.lua
local modpath = digicompute.modpath -- modpath pointer
local path = digicompute.path -- path pointer

-- [function] refresh formspec
function digicompute.refresh(pos)
  local meta = minetest.get_meta(pos) -- get meta
  meta:set_string("formspec", digicompute.formspec(meta:get_string("input"), meta:get_string("output")))
end

dofile(modpath.."/env.lua") -- do env file
dofile(modpath.."/fs.lua") -- do fs api file

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
    if not digicompute.fs.run_file(pos, "os/start.lua", fields, "start.lua") then
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

dofile(modpath.."/c_api.lua") -- do computer API file
