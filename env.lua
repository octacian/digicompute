-- digicompute/env.lua --

-- [function] create environment
function digicompute.env()
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

  local env = {
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
  return env
end

-- [function] run code
function digicompute.run_code(code, env)
  if code:byte(1) == 27 then
    return nil, "Binary code prohibited."
  end
  local f, msg = loadstring(code)
  if not f then return false, msg end
  setfenv(f, env)

  -- Turn off JIT optimization for user code so that count
  -- events are generated when adding debug hooks
  if rawget(_G, "jit") then
    jit.off(f, true)
  end

  -- Use instruction counter to stop execution
  -- after 10000 events
  debug.sethook(function()
    error("Code timed out!", 2)
  end, "", 10000)
  local ok, ret = pcall(f)
  debug.sethook()  -- Clear hook
  if not ok then return false, ret end
  return true, ret
end

-- [function] run file
function digicompute.run_file(path, env)
  local code = digicompute.builtin.read(path)
  local ok, res = digicompute.run_code(code, env)
  return ok, res
end
