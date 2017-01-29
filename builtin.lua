-- digicompute/builtin.lua

digicompute.builtin = {}
local builtin = digicompute.builtin

-- [function] check if file exists
function builtin.exists(path)
  local f = io.open(path, "r") -- open file
  if f ~= nil then f:close() return true end
end

-- [function] list contents
function builtin.list(path)
  local files = minetest.get_dir_list(path, false)
  local subdirs = minetest.get_dir_list(path, true)

  return {
    files = files or nil,
    subdirs = subdirs or nil,
  }
end

-- [function] create file
function builtin.create(path)
  local f = io.open(path, "w") -- create file
  f:close() -- close file
  return true
end

-- [function] write to file
function builtin.write(path, data, mode)
  if mode ~= "w" and mode ~= "a" then
    mode = "w"
  end
  local f = io.open(path, mode) -- open file for writing
  f:write(data) -- write data
  f:close() -- close file
  return true
end

-- [function] read file
function builtin.read(path)
  local f = io.open(path, "r") -- open file for reading
  if f then
    local data = f:read("*all") -- read and store all data
    return data -- return file contents
  end
end

-- [function] copy file
function builtin.copy(original, new)
  local original = builtin.read(original) -- read
  if original then
    builtin.write(new, original) -- write
    return true
  end
end

-- [function] create directory
function builtin.mkdir(path)
  if not io.open(path) then
    if minetest.mkdir then
      minetest.mkdir(path) -- create directory if minetest.mkdir is available
    else
      os.execute('mkdir "'..path..'"') -- create directory with os mkdir command
    end
    return true
  end
end

-- [function] remove directory
function builtin.rmdir(path)
  if io.open(path) then
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
end

-- [function] copy directory
function builtin.cpdir(original, new)
  if io.open(original) then
    -- [local function] copy files
    local function copy_files(opath, npath, files)
      for _, f in ipairs(files) do
        builtin.copy(opath.."/"..f, npath.."/"..f)
      end
    end

    -- [local function] check and copy dir
    local function copy_dir(opath, npath)
      builtin.mkdir(npath)
      local files = minetest.get_dir_list(opath, false)
      local subdirs = minetest.get_dir_list(opath, true)
      copy_files(opath, npath, files)
      for _, d in ipairs(subdirs) do
        copy_dir(opath.."/"..d, npath.."/"..d)
      end
    end

    copy_dir(original, new)
    return true
  end
end
