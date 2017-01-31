-- computers/api.lua

digicompute.c = {}

local modpath   = digicompute.modpath
local path      = digicompute.path
local main_path = path.."computers/"

-- Make computer directory
digicompute.builtin.mkdir(main_path)

-------------------
-- ID MANAGEMENT --
-------------------

local computers = {}

-- [function] load computers
function digicompute.load_computers()
  local res  = digicompute.builtin.read(path.."/computers.txt")
  if res then
    res = minetest.deserialize(res)
    if type(res) == "table" then
      computers = res
    end
  end
end

-- Load all computers
digicompute.load_computers()

-- [function] save computers
function digicompute.save_computers()
  digicompute.builtin.write(path.."/computers.txt", minetest.serialize(computers))
end

-- [function] generate new computer ID
function digicompute.c:new_id(pos)
  assert(type(pos) == "table", "digicompute.c:new_id requires a valid position")
  local meta = minetest.get_meta(pos)

  local function count()
    local count = 1
    for _, i in pairs(computers) do
      count = count + 1
    end
    return count
  end

  local id = "c_"..count()

  computers[id] = {
    pos = pos,
  }

  meta:set_string("id", id)
end

-- [event] save computers on shutdown
minetest.register_on_shutdown(digicompute.save_computers)

-------------------
---- FORMSPECS ----
-------------------

local computer_contexts = {}

local tabs = {
  "main",
  "settings",
}

-- [function] handle tabs
function digicompute.c:handle_tabs(pos, player, fields)
  if fields.tabs then
    if digicompute.c:open(pos, player, tabs[tonumber(fields.tabs)]) then
      return true
    end
  end
end

digicompute.c.forms = {
  naming = {
    cache_formname = false,
    get = function(pos)
      local meta = minetest.get_meta(pos)

      return
        "size[6,1.7]"..
        default.gui_bg_img..
        "field[.25,0.50;6,1;name;Computer Name:;"..minetest.formspec_escape(meta:get_string("name")).."]"..
        "button[4.95,1;1,1;submit_name;Set]"
    end,
    handle = function(pos, player, fields)
      local meta  = minetest.get_meta(pos)
      local name  = player:get_player_name()
      local owner = meta:get_string("owner")

      if owner == name then
        if fields.name or fields.key_enter_field == "name" and fields.name ~= "" then
          meta:set_string("name", fields.name)
          meta:set_string("setup", "true")
          meta:set_string("path", main_path..meta:get_string("owner").."/"..meta:get_string("id").."/")
          digicompute.c:init(pos)
          digicompute.c:open(pos, player)
        else
          minetest.chat_send_player(name, "Name cannot be empty.")
        end
      else
        minetest.chat_send_player(name, "Only the owner can set this computer. ("..owner..")")
      end
    end,
  },
  main = {
    get = function(pos)
      local meta     = minetest.get_meta(pos)
      local input    = minetest.formspec_escape(meta:get_string("input"))
      local help     = minetest.formspec_escape(meta:get_string("help"))
      local output   = meta:get_string("output"):split("\n", true)

      for i, line in ipairs(output) do
      	output[i] = minetest.formspec_escape(line)
      end

      return
        "size[10,11]"..
        "tabheader[0,0;tabs;Command Line,Settings;1]"..
        "bgcolor[#000000FF;]"..
        "tableoptions[background=#000000FF;highlight=#00000000;border=false]"..
        "table[-0.25,-0.38;10.38,11.17;list_credits;"..table.concat(output, ",")..";"..#output.."]"..
        "button[9.56,10.22;0.8,2;help;?]"..
        "tooltip[help;"..help.."]"..
        "field[-0.02,10.99;10.1,1;input;;"..input.."]"..
        "field_close_on_enter[input;false]"
    end,
    handle = function(pos, player, fields)
      if digicompute.c:handle_tabs(pos, player, fields) then return end

      local meta   = minetest.get_meta(pos) -- get meta
      local os     = minetest.deserialize(meta:get_string("os")) or {}
      local prefix = os.prefix or ""

      if fields.input or fields.key_enter_field == "name" then
        if fields.input == os.clear then
          meta:set_string("output", prefix)
          meta:set_string("input", "")
          digicompute.c:open(pos, player)
        elseif fields.input == os.off then digicompute.c:off(pos, player)
        elseif fields.input == os.reboot then digicompute.c:reboot(pos, player)
        else -- else, turn over to os
          -- Set meta value(s)
          meta:set_string("input", fields.input)

          -- Run main.lua
          digicompute.c:run_file(pos, player, "os/main.lua") -- Run main
        end
      end
    end,
  },
  settings = {
    get = function(pos)
      local meta = minetest.get_meta(pos)

      return
        "size[10,11]"..
        "tabheader[0,0;tabs;Command Line,Settings;2]"..
        default.gui_bg_img..
        "button[0.5,0.25;9,1;reset;Reset Filesystem]"..
        "tooltip[reset;Wipes all files and OS data replacing it with the basic BiosOS.]"..
        "label[0.5,10.35;digicompute Version: "..tostring(digicompute.VERSION)..", "..
          digicompute.RELEASE_TYPE.."]"..
        "label[0.5,10.75;(c) Copywrite "..tostring(os.date("%Y")).." "..
          "Elijah Duffy <theoctacian@gmail.com>]"
    end,
    handle = function(pos, player, fields)
      if digicompute.c:handle_tabs(pos, player, fields) then return end

      local meta = minetest.get_meta(pos)

      if fields.reset then
        -- Clear buffers
        meta:set_string("output", "")
        meta:set_string("input", "")

        -- Reset Filesystem
        digicompute.c:reinit(pos)
      end
    end,
  },
}

-- [function] open formspec
function digicompute.c:open(pos, player, formname)
  local meta = minetest.get_meta(pos)

  if meta:get_string("setup") == "true" then
    local meta_formname = meta:get_string("formname")

    if not formname and meta_formname and meta_formname ~= "" then
      formname = meta_formname
    end
  else
    formname = "naming"
  end

  formname   = formname or "main"
  local form = digicompute.c.forms[formname]

  if form then
    local name = player:get_player_name()

    if form.cache_formname ~= false then
      meta:set_string("formname", formname)
    end

    computer_contexts[name] = minetest.get_meta(pos):get_string("id")
    minetest.show_formspec(name, "digicompute:"..formname, form.get(pos, player))
    return true
  end
end

-- [event] on receive fields
minetest.register_on_player_receive_fields(function(player, formname, fields)
  local formname = formname:split(":")

  if formname[1] == "digicompute" and digicompute.c.forms[formname[2]] then
    local computer = computers[computer_contexts[player:get_player_name()]]

    if computer then
      local pos = computer.pos
      minetest.get_meta(pos):set_string("current_user", player:get_player_name())
      digicompute.c.forms[formname[2]].handle(pos, player, fields)
    else
      minetest.chat_send_player(player:get_player_name(), "Computer could not be found!")
    end
  end
end)

----------------------
-- HELPER FUNCTIONS --
----------------------

-- [function] update infotext
function digicompute.c:infotext(pos)
  local meta = minetest.get_meta(pos)
  local state = minetest.registered_nodes[minetest.get_node(pos).name].digicompute.state

  if meta:get_string("setup") == "true" then
    meta:set_string("infotext", meta:get_string("name").." - "..state.."\n(owned by "
      ..meta:get_string("owner")..")")
  else
    meta:set_string("infotext", "Unconfigured Computer - "..state.."\n(owned by "
      ..meta:get_string("owner")..")")
  end
end

-- [function] initialize computer
function digicompute.c:init(pos)
  local meta = minetest.get_meta(pos)
  local path = meta:get_string("path")

  if path and path ~= "" then
    digicompute.builtin.mkdir(main_path..meta:get_string("owner"))
    digicompute.builtin.mkdir(path)
    digicompute.builtin.cpdir(digicompute.modpath.."/bios/", path.."os")
    digicompute.c:run_file(pos, meta:get_string("owner"), "os/start.lua")
    digicompute.log("Initialized computer "..meta:get_string("id").." owned by "..
      meta:get_string("owner").." at "..minetest.pos_to_string(pos))
    digicompute.c:infotext(pos)
  end
end

-- [function] deinitialize computer
function digicompute.c:deinit(pos, clear_entry)
  local meta  = minetest.get_meta(pos)
  local path  = meta:get_string("path")
  local owner = meta:get_string("owner")

  if path and path ~= "" then
    digicompute.builtin.rmdir(path)
    digicompute.log("Deinitialized computer "..meta:get_string("id").." owned by "..
      meta:get_string("owner").." at "..minetest.pos_to_string(pos))

      if digicompute.builtin.list(main_path..owner).subdirs then
        os.remove(main_path..owner)
      end
  end

  if clear_entry ~= false then
    local id = meta:get_string("id")
    computers[id] = nil
  end
end

-- [function] reinitialize computer (reset)
function digicompute.c:reinit(pos)
  digicompute.c:deinit(pos, false)
  digicompute.c:init(pos)
end

-- [function] turn computer on
function digicompute.c:on(pos, player)
  local temp = minetest.get_node(pos)
  local ddef = minetest.registered_nodes[temp.name].digicompute
  if ddef.state == "off" then
    local name, param2 = temp.name, temp.param2

    -- Swap to Bios
    minetest.swap_node({x = pos.x, y = pos.y, z = pos.z}, {name = name.."_bios", param2 = param2}) -- set node to bios

    -- Update infotext
    digicompute.c:infotext(pos)

    -- Swap to on node after 2 seconds
    minetest.after(2, function(pos_)
      minetest.swap_node({x = pos_.x, y = pos_.y, z = pos_.z}, {name = name.."_on", param2 = param2})

      -- Update infotext
      digicompute.c:infotext(pos)
      -- Run start if setup
      if minetest.get_meta(pos):get_string("setup") == "true" then
        digicompute.c:run_file(pos, player, "os/start.lua")
      end
    end, vector.new(pos))
  end
end

-- [function] turn computer off
function digicompute.c:off(pos, player)
  local temp = minetest.get_node(pos) -- Get basic node information
  local offname = "digicompute:"..minetest.registered_nodes[temp.name].digicompute.base
  -- Swap node to off
  minetest.swap_node({x = pos.x, y = pos.y, z = pos.z}, {name = offname, param2 = temp.param2})
  -- Update infotext
  digicompute.c:infotext(pos)
  -- Update Formspec
  minetest.close_formspec(player:get_player_name(), "")
  -- Clear update buffer
  minetest.get_meta(pos):set_string("output", "")
end

-- [function] reboot computer
function digicompute.c:reboot(pos, player)
  digicompute.c:off(pos, player)
  digicompute.c:on(pos, player)
end

-----------------------
----- ENVIRONMENT -----
-----------------------

-- [function] Make environment
function digicompute.c:make_env(pos, player)
  assert(pos, "digicompute.c:make_env missing position")
  local meta = minetest.get_meta(pos)

  -- Main Environment Functions

  local main = {}

  -- [local function] print
  function main.print(contents, newline)
    if type(contents) ~= "string" then
      contents = dump(contents)
    end
    if newline == false then
      newline = ""
    else
      newline = "\n"
    end

    meta:set_string("output", meta:get_string("output")..newline..contents)
  end
  -- [local function] set help
  function main.set_help(value)
    if not value or type(value) ~= "string" then
      value = "Type a command and press enter."
    end

    return meta:set_string("help", value)
  end
  -- [local function] get attribute
  function main.get_attr(key)
    return meta:get_string(key) or nil
  end
  -- [local function] get output
  function main.get_output()
    return meta:get_string("output") or nil
  end
  -- [local function] set output
  function main.set_output(value)
    return meta:set_string("output", value)
  end
  -- [local function] get input
  function main.get_input()
    return meta:get_string("input") or nil
  end
  -- [local function] set input
  function main.set_input(value)
    return meta:set_string("input", value)
  end
  -- [local function] get os value
  function main.get_os(key)
    return minetest.deserialize(meta:get_string("os"))[key] or nil
  end
  -- [local function] set os value
  function main.set_os(key, value)
    local allowed_keys = {
      clear = true,
      off = true,
      reboot = true,
      prefix = true,
    }

    if allowed_keys[key] == true then
      local table = minetest.deserialize(meta:get_string("os")) or {}
      table[key] = value
      return meta:set_string("os", minetest.serialize(table))
    else
      return false
    end
  end
  -- [local function] get userdata value
  function main.get_userdata(key)
    return minetest.deserialize(meta:get_string("userdata"))[key] or nil
  end
  -- [local function] set userdata value
  function main.set_userdata(key, value)
    local table = minetest.deserialize(meta:get_string("userdata")) or {}
    table[key] = value
    return meta:set_string("userdata", minetest.serialize(table))
  end
  -- [local function] refresh
  function main.refresh()
    return digicompute.c:open(pos, minetest.get_player_by_name(meta:get_string("current_user")))
  end
  -- [local function] run code
  function main.run(code)
    return digicompute.c:run_code(pos, player, code)
  end

  -- Filesystem Environment Functions

  local fs    = {}
  local cpath = meta:get_string("path")

  -- [local function] exists
  function fs.exists(path)
    return digicompute.builtin.exists(cpath..path)
  end
  -- [local function] create file
  function fs.create(path)
    return digicompute.builtin.create(cpath..path)
  end
  -- [local function] remove file
  function fs.remove(path)
    return os.remove(cpath..path)
  end
  -- [local function] write to file
  function fs.write(path, data, mode)
    if type(data) ~= "string" then
      data = dump(data)
    end
    return digicompute.builtin.write(cpath..path, data, mode)
  end
  -- [local function] read file
  function fs.read(path)
    return digicompute.builtin.read(cpath..path)
  end
  -- [local function] list directory contents
  function fs.list(path)
    return digicompute.builtin.list(cpath..path)
  end
  -- [local function] copy file
  function fs.copy(original, new)
    return digicompute.builtin.copy(cpath..original, cpath..new)
  end
  -- [local function] create directory
  function fs.mkdir(path)
    return digicompute.builtin.mkdir(cpath..path)
  end
  -- [local function] remove directory
  function fs.rmdir(path)
    return digicompute.builtin.rmdir(cpath..path)
  end
  -- [local function] copy directory
  function fs.cpdir(original, new)
    return digicompute.builtin.cpdir(cpath..original, cpath..new)
  end
  -- [local function] run file
  function fs.run(path)
    return digicompute.c:run_file(pos, player, path)
  end

  -- Get default env table

  local env = digicompute.env()

  env.fs = fs

  for k, v in pairs(main) do
    env[k] = v
  end

  return env
end

-- [function] run code
function digicompute.c:run_code(pos, player, code)
  local env     = digicompute.c:make_env(pos, player)
  local ok, res = digicompute.run_code(code, env)
  return ok, res
end

-- [function] run file
function digicompute.c:run_file(pos, player, path)
  local path    = minetest.get_meta(pos):get_string("path")..path
  local env     = digicompute.c:make_env(pos, player)
  local ok, res = digicompute.run_file(path, env)
  return ok, res
end

----------------------
-- NODE DEFINITIONS --
----------------------

function digicompute.register_computer(itemstring, def)
  -- off
  minetest.register_node("digicompute:"..itemstring, {
    digicompute = {
      state = "off",
      base = itemstring,
    },
    drawtype = "nodebox",
    description = def.description,
    tiles = def.off_tiles,
    paramtype = "light",
    paramtype2 = "facedir",
    groups = {cracky = 2},
    drop = "digicompute:"..itemstring,
    sounds = default.node_sound_stone_defaults(),
    node_box = def.node_box,
    after_place_node = function(pos, player)
      local meta = minetest.get_meta(pos)
      meta:set_string("owner", player:get_player_name())
      meta:set_string("input", "")                               -- Initialize input buffer
      meta:set_string("output", "")                              -- Initialize output buffer
      meta:set_string("os", "")                                  -- Initialize OS table
      meta:set_string("userspace", "")                           -- Initialize userspace table
      meta:set_string("help", "Type a command and press enter.") -- Initialize help
      digicompute.c:new_id(pos)                                  -- Set up ID

      -- Update infotext
      digicompute.c:infotext(pos)
    end,
    on_rightclick = function(pos, node, player)
      digicompute.c:on(pos, player)
    end,
    on_destruct = function(pos)
      if minetest.get_meta(pos):get_string("name") then
        digicompute.c:deinit(pos)
      end
    end,
  })
  -- bios
  minetest.register_node("digicompute:"..itemstring.."_bios", {
    light_source = def.light_source or 7,
    digicompute = {
      state = "bios",
      base = itemstring,
    },
    drawtype = "nodebox",
    defription = def.defription,
    tiles = def.bios_tiles,
    paramtype = "light",
    paramtype2 = "facedir",
  	groups = {cracky = 2, not_in_creative_inventory = 1},
    drop = "digicompute:"..itemstring,
  	sounds = default.node_sound_stone_defaults(),
    node_box = def.node_box,
    on_destruct = function(pos)
      if minetest.get_meta(pos):get_string("name") then
        digicompute.c:deinit(pos)
      end
    end,
  })
  -- on
  minetest.register_node("digicompute:"..itemstring.."_on", {
    light_source = def.light_source or 7,
    digicompute = {
      state = "on",
      base = itemstring,
    },
    drawtype = "nodebox",
    description = def.defription,
    tiles = def.on_tiles,
    paramtype = "light",
    paramtype2 = "facedir",
  	groups = {cracky = 2, not_in_creative_inventory = 1},
    drop = "digicompute:"..itemstring,
  	sounds = default.node_sound_stone_defaults(),
    node_box = def.node_box,
    on_rightclick = function(pos, node, player)
      digicompute.c:open(pos, player)
    end,
    on_destruct = function(pos)
      if minetest.get_meta(pos):get_string("name") then
        digicompute.c:deinit(pos)
      end
    end,
  })
end
