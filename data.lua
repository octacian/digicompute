-- datalib/init.lua
datalib = {}
datalib.table = {} -- internal table global

-- logger
function datalib.log(content, log_type)
  if log_type == nil then log_type = "action" end
  minetest.log(log_type, "[digicompute:datalib] "..content)
end

-- global path variables
datalib.modpath = minetest.get_modpath("digicompute") -- modpath
datalib.worldpath = minetest.get_worldpath() -- worldpath
datalib.datapath = datalib.worldpath.."/digicompute" -- path for general datalib storage
-- local path variables
local modpath = datalib.modpath
local worldpath = datalib.worldpath
local datapath = datalib.datapath

-- check if datalib world folder exists
function datalib.initdata()
  local f = io.open(datapath)
  if not f then
    if minetest.mkdir then
      minetest.mkdir(datapath) -- create directory if minetest.mkdir is available
      return
    else
      os.execute('mkdir "'..datapath..'"') -- create directory with os mkdir command
      return
    end
  end
  f:close() -- close file
end

datalib.initdata() -- initialize world data directory

-- check if file exists
function datalib.exists(path)
  local f = io.open(path, "r") -- open file
  if f ~= nil then f:close() return true else return false end
end

-- create file
function datalib.create(path)
  -- check if file already exists
  if datalib.exists(path) == true then
    datalib.log("File ("..path..") already exists.") -- log
    return true -- exit and return
  end
  local f = io.open(path, "w") -- create file
  f:close() -- close file
  datalib.log("Created file "..path) -- log
end

-- write to file
function datalib.write(path, data, serialize)
  if datalib.exists(path) ~= true then return false end -- check if exists
  if not serialize then local serialize = false end -- if blank serialize = true
  local f = io.open(path, "w") -- open file for writing
  if serialize == true then local data = minetest.serialize(data) end -- serialize data
  f:write(data) -- write data
  f:close() -- close file
  datalib.log('Wrote "'..data..'" to '..path) -- log
end

-- append to file
function datalib.append(path, data, serialize)
  if datalib.exists(path) ~= true then return false end -- check if exists
  if not serialize then local serialize = false end -- if blank serialize = true
  local f = io.open(path, "a") -- open file for writing
  if serialize == true then local data = minetest.serialize(data) end -- serialize data
  f:write(data) -- write data
  f:close() -- close file
  datalib.log('Wrote "'..data..'" to '..path) -- log
end

-- load file
function datalib.read(path, deserialize)
  if datalib.exists(path) ~= true then return false end -- check if exists
  local f = io.open(path, "r") -- open file for reading
  local data = f:read() -- read and store file data in variable data
  if deserialize == true then local data = minetest.deserialize(data) end -- deserialize data
  return data -- return file contents
end

-- write table to file
function datalib.table.write(path, intable)
  if datalib.exists(path) ~= true then return false end -- check if exists
  local intable = minetest.serialize(intable) -- serialize intable
  local f = io.open(path, "w") -- open file for writing
  f:write(intable) -- write intable
  f:close() -- close file
  datalib.log("Wrote table to "..path)
end

-- load table from file
function datalib.table.read(path)
  if datalib.exists(path) ~= true then return false end -- check if exists
  local f = io.open(path, "r") -- open file for reading
  local externaltable = minetest.deserialize(f:read()) -- deserialize and read externaltable
  f:close() -- close file
  return externaltable
end

-- dofile
function datalib.dofile(path)
  -- check if file exists
  if datalib.exists(path) == true then
    dofile(path)
    return true -- return true, successful
  else
    datalib.log("File "..path.." does not exist.")
    return false -- return false, unsuccessful
  end
end
