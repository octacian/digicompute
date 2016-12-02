-- digicompute/env.lua --
-- ENVIRONMENT --
-----------------

-- [function] create environment
function digicompute.create_env(pos, fields)
  local meta = minetest.get_meta(pos) -- get meta
  -- CUSTOM SAFE FUNCTIONS --

  local function safe_print(param)
  	print(dump(param))
  end

  local function safe_date()
  	return(os.date("*t",os.time()))
  end

  -- string.rep(str, n) with a high value for n can be used to DoS
  -- the server. Therefore, limit max. length of generated string.
  local function safe_string_rep(str, n)
  	if #str * n > 6400 then
  		debug.sethook() -- Clear hook
  		error("string.rep: string length overflow", 2)
  	end

  	return string.rep(str, n)
  end

  -- string.find with a pattern can be used to DoS the server.
  -- Therefore, limit string.find to patternless matching.
  local function safe_string_find(...)
  	if (select(4, ...)) ~= true then
  		debug.sethook() -- Clear hook
  		error("string.find: 'plain' (fourth parameter) must always be true for digicomputers.")
  	end

  	return string.find(...)
  end

  -- [function] get attr (from meta)
  local function get_attr(key)
    return meta:get_string(key) or nil
  end
  -- [function] get userdata
  local function get_userdata(key)
    local t = minetest.deserialize(meta:get_string("userspace"))
    return t[key] or nil
  end
  -- [function] set userdata
  local function set_userdata(key, value)
    local t = minetest.deserialize(meta:get_string("userspace"))
    t[key] = value
    return meta:set_string("userspace", minetest.serialize(t))
  end
  -- [function] get input
  local function get_input()
    return meta:get_string("input") or nil
  end
  -- [function] set input
  local function set_input(value)
    return meta:set_string("input", value) or nil
  end
  -- [function] get output
  local function get_output()
    return meta:get_string("output") or nil
  end
  -- [function] set output
  local function set_output(value)
    return meta:set_string("output", value) or nil
  end
  -- [function] get field
  local function get_field(key)
    return fields[key] or nil
  end
  -- [function] refresh
  local function refresh()
    meta:set_string("formspec", digicompute.formspec(meta:get_string("input"), meta:get_string("output")))
    return true
  end

  -- filesystem API

  -- [function] get file (read)
  local function get_file(path)
    local res = digicompute.fs.get_file(pos, path)
    if res then return res end
  end

  -- [function] get directory contents
  local function get_dir(path)
    local res = digicompute.fs.get_dir(pos, path)
    if res then return res end
  end

  -- [function] exists
  local function exists(path)
    local res = digicompute.fs.exists(pos, path)
    if res then return res end
  end

  -- [function] mkdir
  local function mkdir(path)
    local res = digicompute.fs.exists(pos, path)
    if res then return res end
  end

  -- [function] rmdir
  local function rmdir(path)
    local res = digicompute.fs.rmdir(pos, path)
    if res then return res end
  end

  -- [function] mkdir
  local function mkdir(path)
    local res = digicompute.fs.exists(pos, path)
    if res then return res end
  end

  -- [function] create file
  local function create(path)
    local res = digicompute.fs.create(pos, path)
    if res then return res end
  end

  -- [function] write
  local function write(path, data)
    local res = digicompute.fs.write(pos, path, data)
    if res then return res end
  end

  -- [function] append
  local function append(path, data)
    local res = digicompute.fs.append(pos, path, data)
    if res then return res end
  end

  -- [function] copy
  local function copy(path, npath)
    local res = digicompute.fs.copy(pos, path, npath)
    if res then return res end
  end

  -- ENVIRONMENT TABLE --

  local env = {
    run = digicompute.run,
    get_attr = get_attr,
    get_userdata = get_userdata,
    set_userdata = set_userdata,
    get_input = get_input,
    set_input = set_input,
    get_output = get_output,
    set_output = set_output,
    get_field = get_field,
    refresh = refresh,
    fs = {
      read = get_file,
      list = get_dir,
      check = exists,
      mkdir = mkdir,
      rmdir = rmdir,
      touch = create,
      write = write,
      copy = copy,
      cp = copy,
    },
    string = {
      byte = string.byte,
      char = string.char,
      format = string.format,
      len = string.len,
      lower = string.lower,
      upper = string.upper,
      rep = safe_string_rep,
      reverse = string.reverse,
      sub = string.sub,
      find = safe_string_find,
    },
    math = {
      abs = math.abs,
      acos = math.acos,
      asin = math.asin,
      atan = math.atan,
      atan2 = math.atan2,
      ceil = math.ceil,
      cos = math.cos,
      cosh = math.cosh,
      deg = math.deg,
      exp = math.exp,
      floor = math.floor,
      fmod = math.fmod,
      frexp = math.frexp,
      huge = math.huge,
      ldexp = math.ldexp,
      log = math.log,
      log10 = math.log10,
      max = math.max,
      min = math.min,
      modf = math.modf,
      pi = math.pi,
      pow = math.pow,
      rad = math.rad,
      random = math.random,
      sin = math.sin,
      sinh = math.sinh,
      sqrt = math.sqrt,
      tan = math.tan,
      tanh = math.tanh,
    },
    table = {
      concat = table.concat,
      insert = table.insert,
      maxn = table.maxn,
      remove = table.remove,
      sort = table.sort,
    },
    os = {
      clock = os.clock,
      difftime = os.difftime,
      time = os.time,
      datetable = safe_date,
    },
  }
  return env -- return table
end
