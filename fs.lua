-- digicompute/fs.lua
--[[
filesystem API.
]]
digicompute.fs = {}
local fs = digicompute.fs
local path = digicompute.path
local modpath = digicompute.modpath

----- BASE FUNCTIONS -----

-- [function] check if file exists
local function exists(path)
  local f = io.open(path, "r") -- open file
  if f ~= nil then f:close() return true end
end

-- [function] make directory
local function mkdir(path)
  local f = io.open(path)
  if not f then
    if minetest.mkdir then
      minetest.mkdir(path) -- create directory if minetest.mkdir is available
      return true
    else
      os.execute('mkdir "'..path..'"') -- create directory with os mkdir command
      return true
    end
  end

  f:close() -- close file
end

-- [function] remove directory
local function rmdir(path)
  if not exists(path) then return end -- directory doesn't exist

  -- [local function] remove files
  local function rm_files(ppath, files)
    for _, f in ipairs(files) do
      os.remove(ppath.."/"..f)
    end
  end

  -- [local function] check and rm dir
  local function rm_dir(dpath)
    local files = minetest.get_dir_list(dpath, false)
    local subdirs = minetest.get_dir_list(dpath, true)
    rm_files(dpath, files)
    if subdirs then
      for _, d in ipairs(subdirs) do
        rm_dir(dpath.."/"..d)
      end
    end
    os.remove(dpath)
  end

  rm_dir(path)
  return true
end

-- [function] create file
local function create(path)
  if exists(path) then return end -- if already exists, return
  local f = io.open(path, "w") -- create file
  f:close() -- close file
  return true
end

-- [function] write to file
local function write(path, data, overwrite)
  -- check if append or overwrite
  if overwrite == false then local w = "a" else
    if not exists(path) then return end
    local w = "w"
  end
  local f = io.open(path, w) -- open file for writing
  f:write(minetest.serialize(data)) -- write serialized data (prevents errors when writing tables)
  f:close() -- close file
  return true
end

-- [function] read file
local function read(path)
  if not exists(path) then return end -- check if exists
  local f = io.open(path, "r") -- open file for reading
  local data = f:read("*all") -- read and store file data in variable "data"
  return minetest.deserialize(data) -- return deserialized contents
end

-- [function] copy file
local function cp(path, new)
  if not exists(path) then return end -- check if path exists
  local original = read(path) -- read
  write(new, original, true) -- write
  return true
end

-- [function] copy directory
local function cpdir(path, new)
  if not exists(path) then return end -- directory doesn't exist

  -- [local function] copy files
  local function cp_files(ppath, files)
    for _, f in ipairs(files) do
      cp(ppath.."/"..f, new.."/"..f) -- copy
    end
  end

  -- [local function] check and copy dir
  local function cp_dir(dpath)
    mkdir(dpath) -- make new directory
    local files = minetest.get_dir_list(dpath, false)
    local subdirs = minetest.get_dir_list(dpath, true)
    cp_files(dpath, files)

    for _, d in ipairs(subdirs) do
      cp_dir(dpath.."/"..d)
    end
  end

  cp_dir(path)
  return true
end

----- FS -----

-- [function] initalize fs
function digicompute.fs.init(pos, cname)
  local meta = minetest.get_meta(pos) -- meta
  local player = meta:get_string("owner") -- owner username
  local cpath = path.."/"..player.."/"..cname -- comp path
  if not exists(path.."/"..player) then mkdir(path.."/"..player) end -- check for user dir
  if exists(cpath) then return "A computer with this name already exists." end
  mkdir(cpath) -- make computer dir
  cpdir(modpath.."/bios", cpath.."/os") -- copy biosOS
  digicompute.log("Initialized computer "..cname.." placed by "..player..".")
end

-- [function] de-initialize fs (delete)
function digicompute.fs.deinit(pos)
  local meta = minetest.get_meta(pos) -- meta
  local player = meta:get_string("owner") -- owner username
  local cname = meta:get_string("name") -- name

  -- [local function] remove files
  local function rm_files(ppath, files)
    for _, f in ipairs(files) do
      os.remove(ppath.."/"..f)
    end
  end

  -- [local function] check and rm dir
  local function rm_dir(dpath)
    local files = minetest.get_dir_list(dpath, false)
    local subdirs = minetest.get_dir_list(dpath, true)
    rm_files(dpath, files)
    if subdirs then
      for _, d in ipairs(subdirs) do
        rm_dir(dpath.."/"..d)
      end
    end
    os.remove(dpath)
  end

  rm_dir(path.."/"..player.."/"..cname)
end

-- [function] get file contents
function digicompute.fs.get_file(pos, fpath)
  local meta = minetest.get_meta(pos) -- meta
  local cname = meta:get_string("name") -- computer name
  local player = meta:get_string("owner") -- owner username
  local cpath = path.."/"..player.."/"..cname -- comp path
  local contents = datalib.read(cpath.."/"..fpath)
  if not contents then return { error = "File does not exist.", contents = nil } end
  return { error = nil, contents = contents }
end

-- [function] get directory contents
function digicompute.fs.get_dir(pos, dpath)
  local meta = minetest.get_meta(pos) -- meta
  local cname = meta:get_string("name") -- computer name
  local player = meta:get_string("owner") -- owner username
  local cpath = path.."/"..player.."/"..cname -- comp path
  local files = minetest.get_dir_list(cpath.."/"..dpath, false)
  local subdirs = minetest.get_dir_list(cpath.."/"..dpath, true)
  if not files or files == {} or not subdirs or subdirs == {} then
    return { error = "Directory does not exist, or is empty.", contents = nil }
  end
  return { error = nil, contents = { files = files, subdirs = subdirs } }
end

-- [function] exists
function digicompute.fs.exists(pos, fpath)
  local meta = minetest.get_meta(pos) -- meta
  local cname = meta:get_string("name") -- computer name
  local name = meta:get_string("owner") -- owner username
  local res = datalib.exists(path.."/"..name.."/"..cname.."/"..fpath)
  if res == true then return "File exists."
  else return "File does not exist."
  end
end

-- [function] create directory
function digicompute.fs.mkdir(pos, fpath)
  local meta = minetest.get_meta(pos) -- meta
  local cname = meta:get_string("name") -- computer name
  local name = meta:get_string("owner") -- owner username
  local res = datalib.mkdir(path.."/"..name.."/"..cname.."/"..fpath)
  if res == true then return "Directory already exists." end
end

-- [function] remove directory
function digicompute.fs.rmdir(pos, fpath)
  local meta = minetest.get_meta(pos) -- meta
  local cname = meta:get_string("name") -- computer name
  local name = meta:get_string("owner") -- owner username
  local res = datalib.rmdir(path.."/"..name.."/"..cname.."/"..fpath)
  if res == false then return "Directory does not exist." end
end

-- [function] create file
function digicompute.fs.create(pos, fpath)
  local meta = minetest.get_meta(pos) -- meta
  local cname = meta:get_string("name") -- computer name
  local name = meta:get_string("owner") -- owner username
  local res = datalib.create(path.."/"..name.."/"..cname.."/"..fpath)
  if res == true then return "File already exists." end
end

-- [function] write
function digicompute.fs.write(pos, fpath, data)
  local meta = minetest.get_meta(pos) -- meta
  local cname = meta:get_string("name") -- computer name
  local name = meta:get_string("owner") -- owner username
  datalib.write(path.."/"..name.."/"..cname.."/"..fpath, data, false)
end

-- [function] append
function digicompute.fs.append(pos, fpath, data)
  local meta = minetest.get_meta(pos) -- meta
  local cname = meta:get_string("name") -- computer name
  local name = meta:get_string("owner") -- owner username
  datalib.append(path.."/"..name.."/"..cname.."/"..fpath, data, false)
end

-- [function] copy file
function digicompute.fs.copy(pos, fpath, npath)
  local meta = minetest.get_meta(pos) -- meta
  local cname = meta:get_string("name") -- computer name
  local name = meta:get_string("owner") -- owner username
  local res = datalib.copy(path.."/"..name.."/"..cname.."/"..fpath, path.."/"..name.."/"..cname.."/"..npath)
  if res == false then return "Base file does not exist." end
end
digicompute.fs.cp = digicompute.fs.copy
