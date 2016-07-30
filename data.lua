-- digicompute/data.lua
digicompute.file = {}
digicompute.file.table = {} -- internal table global

-- logger
function digicompute.log(content, log_type)
  if log_type == nil then log_type = "action" end
  minetest.log(log_type, "[digicompute.file:digicompute.file] "..content)
end

-- global path variables
digicompute.modpath = minetest.get_modpath("digicompute") -- modpath
digicompute.worldpath = minetest.get_worldpath() -- worldpath
digicompute.path = digicompute.worldpath.."/digicompute" -- path for general digicompute.file storage
-- local path variables
local modpath = digicompute.modpath
local worldpath = digicompute.worldpath
local path = digicompute.path

-- check if digicompute.file world folder exists
function digicompute.file.initdata()
  local f = io.open(path)
  if not f then
    if minetest.mkdir then
      minetest.mkdir(path) -- create directory if minetest.mkdir is available
      return
    else
      os.execute('mkdir "'..path..'"') -- create directory with os mkdir command
      return
    end
  end
  f:close() -- close file
end

digicompute.file.initdata() -- initialize world data directory

-- check if file exists
function digicompute.file.exists(path)
  local f = io.open(path, "r") -- open file
  if f ~= nil then f:close() return true else return false end
end

-- create folder
function digicompute.file.mkdir(path)
  local f = io.open(path)
  if not f then
    if minetest.mkdir then
      minetest.mkdir(path) -- create directory if minetest.mkdir is available
      return
    else
      os.execute('mkdir "'..path..'"') -- create directory with os mkdir command
      return
    end
  end
  f:close() -- close file
end

-- create file
function digicompute.file.create(path)
  -- check if file already exists
  if digicompute.file.exists(path) == true then
    digicompute.log("File ("..path..") already exists.") -- log
    return true -- exit and return
  end
  local f = io.open(path, "w") -- create file
  f:close() -- close file
  digicompute.log("Created file "..path) -- log
end

-- write to file
function digicompute.file.write(path, data, serialize)
  if digicompute.file.exists(path) ~= true then digicompute.file.create(path) end -- check if exists
  if not serialize then local serialize = false end -- if blank serialize = true
  local f = io.open(path, "w") -- open file for writing
  if serialize == true then local data = minetest.serialize(data) end -- serialize data
  f:write(data) -- write data
  f:close() -- close file
  digicompute.log('Wrote "'..data..'" to '..path) -- log
end

-- append to file
function digicompute.file.append(path, data, serialize)
  if digicompute.file.exists(path) ~= true then return false end -- check if exists
  if not serialize then local serialize = false end -- if blank serialize = true
  local f = io.open(path, "a") -- open file for writing
  if serialize == true then local data = minetest.serialize(data) end -- serialize data
  f:write(data) -- write data
  f:close() -- close file
  digicompute.log('Wrote "'..data..'" to '..path) -- log
end

-- load file
function digicompute.file.read(path, deserialize)
  if digicompute.file.exists(path) ~= true then return false end -- check if exists
  local f = io.open(path, "r") -- open file for reading
  local data = f:read("*all") -- read and store file data in variable data
  if deserialize == true then local data = minetest.deserialize(data) end -- deserialize data
  return data -- return file contents
end

-- write table to file
function digicompute.file.table.write(path, intable)
  if digicompute.file.exists(path) ~= true then return false end -- check if exists
  local intable = minetest.serialize(intable) -- serialize intable
  local f = io.open(path, "w") -- open file for writing
  f:write(intable) -- write intable
  f:close() -- close file
  digicompute.log("Wrote table to "..path)
end

-- load table from file
function digicompute.file.table.read(path)
  if digicompute.file.exists(path) ~= true then return false end -- check if exists
  local f = io.open(path, "r") -- open file for reading
  local externaltable = minetest.deserialize(f:read()) -- deserialize and read externaltable
  f:close() -- close file
  return externaltable
end

-- dofile
function digicompute.file.dofile(path)
  -- check if file exists
  if digicompute.file.exists(path) == true then
    dofile(path)
    return true -- return true, successful
  else
    digicompute.log("File "..path.." does not exist.")
    return false -- return false, unsuccessful
  end
end
