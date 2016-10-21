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
function digicompute.fs.rm(pos)
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
function digicompute.fs.get_file(pos, cname, fpath)
  local meta = minetest.get_meta(pos) -- meta
  local player = meta:get_string("owner") -- owner username
  local cpath = path.."/"..player.."/"..cname -- comp path
  local contents = datalib.read(cpath.."/"..fpath)
  if not contents then return { error = "File does not exist.", contents = nil } end
  return { error = nil, contents = contents }
end

-- [function] get directory contents
function digicompute.fs.get_dir(pos, cname, dpath)
  local meta = minetest.get_meta(pos) -- meta
  local player = meta:get_string("owner") -- owner username
  local cpath = path.."/"..player.."/"..cname -- comp path
  local files = minetest.get_dir_list(cpath.."/"..dpath, false)
  local subdirs = minetest.get_dir_list(cpath.."/"..dpath, true)
  if not files and not subdirs then return { error = "Directory does not exist, or is empty.", contents = nil } end
  return { error = nil, contents = { files = files, subdirs = subdirs } }
end

-- [function] run file under env
function digicompute.fs.run_file(pos, lpath, fields, replace)
  local meta = minetest.get_meta(pos)
  local lpath = path.."/"..meta:get_string("owner").."/"..meta:get_string("name").."/"..lpath
  local env = digicompute.create_env(pos, fields) -- environment
  local f = loadfile(lpath) -- load func
  local e = digicompute.run(f, env) -- run function
  -- if error, call error handle function and re-run start
  if e and replace then
    datalib.copy(lpath, lpath..".old")
    datalib.copy(modpath.."/bios/"..replace, lpath)
    meta:set_string("output", "Error: \n"..msg.."\n\nRestoring OS, modified files will remain.") -- set output
    digicompute.refresh(pos) -- refresh
    minetest.after(13, function() -- after 13 seconds, run start
      local s = loadfile(path.."/"..meta:get_string("owner").."/"..meta:get_string("name").."/os/start.lua") -- load func
      digicompute.run(s, env) -- run func
      return false
    end)
  elseif e and not replace then return e end -- elseif no replace and error, return error msg
end
