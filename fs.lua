-- digicompute/fs.lua
--[[
filesystem API.
]]
digicompute.fs = {}
local fs = digicompute.fs
local path = digicompute.path
local modpath = digicompute.modpath

-- [function] initalize fs
function digicompute.fs.init(pos, cname)
  local meta = minetest.get_meta(pos) -- meta
  local player = meta:get_string("owner") -- owner username
  local cpath = path.."/"..player.."/"..cname -- comp path
  if datalib.exists(path.."/"..player) == false then datalib.mkdir(path.."/"..player) end -- check for user dir
  if datalib.exists(cpath) == true then return "A computer with this name already exists." end
  datalib.mkdir(cpath) -- make computer dir
  datalib.mkdir(cpath.."/os/") -- make os dir
  datalib.copy(modpath.."/bios/conf.lua", cpath.."/os/conf.lua", false)
  datalib.copy(modpath.."/bios/main.lua", cpath.."/os/main.lua", false)
  datalib.copy(modpath.."/bios/start.lua", cpath.."/os/start.lua", false)
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
  if not files and not subdirs then return { error = "Directory does not exist, or is empty.", contents = nil } end
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
