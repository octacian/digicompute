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

  -- [function] set
  local function set_string(key, value)
    return meta:set_string(key, value)
  end
  -- [function] get
  local function get_string(key)
    return meta:get_string(key)
  end
  -- [function] set int
  local function set_int(key, value)
    return meta:set_int(key, value)
  end
  -- [function] get int
  local function get_int(key)
    return meta:get_int(key)
  end
  -- [function] set float
  local function set_float(key, value)
    return meta:set_float(key, value)
  end
  -- [function] get float
  local function get_float(key)
    return meta:get_float(key)
  end
  -- [function] get input
  local function get_input()
    return meta:get_string("input")
  end
  -- [function] set input
  local function set_input(value)
    return meta:set_string("input", value)
  end
  -- [function] get output
  local function get_output()
    return meta:get_string("output")
  end
  -- [function] set output
  local function set_output(value)
    return meta:set_string("output", value)
  end
  -- [function] get field
  local function get_field(key)
    return fields[key]
  end
  -- [function] refresh
  local function refresh()
    meta:set_string("formspec", digicompute.formspec(meta:get_string("input"), meta:get_string("output")))
  end

  -- ENVIRONMENT TABLE --

  local env = {
    run = digicompute.run,
    set_string = set_string,
    get_string = get_string,
    set_int = set_int,
    get_int = get_int,
    set_float = set_float,
    get_float = get_float,
    get_input = get_input,
    set_input = set_input,
    get_output = get_output,
    set_output = set_output,
    get_field = get_field,
    refresh = refresh,
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
