-- digicompute/c_api.lua
--[[
API for registering computer nodes. Documentation in progress.
]]
local modpath = digicompute.modpath
local path = digicompute.path

function digicompute.register_computer(termstring, desc)
  -- off
  minetest.register_node("digicompute:"..termstring, {
    drawtype = "nodebox",
    description = desc.description,
    tiles = desc.off_tiles,
    paramtype = "light",
    paramtype2 = "facedir",
    groups = {cracky = 2},
    drop = "digicompute:"..termstring,
    sounds = default.node_sound_stone_defaults(),
    node_box = desc.node_box,
    digiline = {
      receptor = {},
      effector = {
        action = function(pos, node, channel, msg)
          if digicompute.digiline ~= false then
            local meta = minetest.get_meta(pos) -- get meta
            -- if channel is correct, turn on
            if channel == meta:get_string("channel") then
              if msg.system == digicompute.digiline_on then
                digicompute.on(pos, termstring)
              end
            end
          end
        end
      },
    },
    on_rightclick = function(pos)
      digicompute.on(pos, termstring)
    end,
  })
  -- bios
  minetest.register_node("digicompute:"..termstring.."_bios", {
    drawtype = "nodebox",
    description = desc.description,
    tiles = desc.bios_tiles,
    paramtype = "light",
    paramtype2 = "facedir",
  	groups = {cracky = 2, not_in_creative_inventory = 1},
    drop = "digicompute:"..termstring,
  	sounds = default.node_sound_stone_defaults(),
    node_box = desc.node_box,
  })
  -- on
  minetest.register_node("digicompute:"..termstring.."_on", {
    drawtype = "nodebox",
    description = desc.description,
    tiles = desc.on_tiles,
    paramtype = "light",
    paramtype2 = "facedir",
  	groups = {cracky = 2, not_in_creative_inventory = 1},
    drop = "digicompute:"..termstring,
  	sounds = default.node_sound_stone_defaults(),
    node_box = desc.node_box,
    digiline = {
      receptor = {},
      effector = {
        action = function(pos, node, channel, msg)
          -- if os supports digilines and digiline on, listen for signal
          if digicompute.digiline ~= false and digicompute.on:find("digiline") then
            local meta = minetest.get_meta(pos) -- get meta
            if channel ~= meta:get_string("channel") then return end -- ignore if not proper channel
            if msg.system then
              if msg.system == digicompute.clear then digicompute.clear("output", pos) -- clear output
              elseif msg.system == digicompute.off then digicompute.off(pos, termstring) -- turn off
              elseif msg.system == digicompute.reboot then digicompute.reboot(pos, termstring) -- reboot
              else digicompute.proc_digiline({x = pos.x, y = pos.y, z = pos.z}, fields.input) end -- else, hand over to OS
            end
          end
        end
      },
    },
    on_construct = function(pos) -- set meta and formspec
      local meta = minetest.get_meta(pos) -- get meta
      meta:set_string("output", "") -- output buffer
      meta:set_string("input", "") -- input buffer
      local name = meta:get_string("name") -- get computer name
      if not name then name = "" end -- if name nil, set to blank
      meta:set_string("formspec", digicompute.formspec_name(name)) -- computer name formspec
    end,
    on_rightclick = function(pos)
      -- if clear_on_close is true, clear
      if digicompute.clear_on_close == true then
        local meta = minetest.get_meta(pos) -- get meta
        meta:set_string("formspec", digicompute.formspec("", "")) -- clear formspec
      end
    end,
    on_destruct = function(pos)
      local meta = minetest.get_meta(pos) -- get meta
      local name = meta:get_string("name") -- get name
      if name then os.remove(path.."/"..name) end -- try to remove files
    end,
    on_receive_fields = function(pos, formname, fields, sender) -- process formdata
      local meta = minetest.get_meta(pos) -- get meta

      -- if name, set
      if fields.name then
        meta:set_string("name", fields.name) -- set name
        meta:set_string("setup", "true") -- set computer to configured
        -- create filesystem
        datalib.mkdir(path.."/"..fields.name.."/os/")
        datalib.copy(modpath.."/bios/conf.lua", path.."/"..fields.name.."/os/conf.lua", false)
        datalib.copy(modpath.."/bios/main.lua", path.."/"..fields.name.."/os/main.lua", false)
        datalib.copy(modpath.."/bios/start.lua", path.."/"..fields.name.."/os/start.lua", false)
        -- try to run when_on
        if not digicompute.runfile(pos, path.."/"..meta:get_string("name").."/os/start.lua", "start", fields) then
          meta:set_string("formspec", digicompute.formspec("", "")) -- set formspec
        end
        digicompute.refresh(pos) -- refresh
      end

      local name = meta:get_string("name") -- get name
			local c = loadfile(path.."/"..name.."/os/conf.lua")
			local e, msg = pcall(c)
      -- if submitted, process basic commands, pass on to os
      if fields.input then
        if fields.input == clear then meta:set_string("formspec", digicompute.formspec("",""))
        elseif fields.input == off then digicompute.off(pos, termstring) -- set off
        elseif fields.input == reboot then digicompute.reboot(pos, termstring) -- reboot
        else -- else, turn over to os
          digicompute.runfile(pos, path.."/"..name.."/os/main.lua", "main", fields) -- run main.lua
        end
      end
    end,
  })
end
