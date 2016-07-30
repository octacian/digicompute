-- digicompute/os.lua
digicompute.os = {} -- init os table
local modpath = digicompute.modpath -- modpath pointer
local path = digicompute.path -- datapath pointer

-- [function] load os
function digicompute.os.load(os_name)
  if digicompute.file.dofile(modpath.."/os/"..os_name..".lua") ~= true then
    if digicompute.file.dofile(path.."/os/"..os_name.."/.lua") ~= true then
      -- print error
      digicompute.log(os_name.." os could not be found. Please place the OS file in "..modpath.."/os/ or "..path.."/os/ with extension '.lua'.", "error")
    end
  end
end

-- [function] set meta value
function digicompute.os.set(pos, key, value)
  local meta = minetest.get_meta({x = pos.x, y = pos.y, z = pos.z}) -- get meta
  meta:set_string(key, value) -- set value
  return true -- return true, successful
end

-- [function] get meta value
function digicompute.os.get(pos, key)
  local meta = minetest.get_meta({x = pos.x, y = pos.y, z = pos.z}) -- get meta
  local value = meta:get_string(key) -- get value
  return value -- return retrieved value
end

-- [function] refresh formspec
function digicompute.os.refresh(pos)
  local meta = minetest.get_meta(pos) -- get meta
  meta:set_string("formspec", digicompute.formspec(meta:get_string("input"), meta:get_string("output")))
end
