-- digicompute/api.lua

-- SYSTEM FUNCTIONS
-- turn on
function digicompute.on(pos, node)
  local temp = minetest.get_node(pos) -- get node
  minetest.swap_node({x = pos.x, y = pos.y, z = pos.z}, {name = "digicompute:"..node.."_bios", param2 = temp.param2}) -- set node to bios
  minetest.after(3.5, function(pos_)
    minetest.swap_node({x = pos_.x, y = pos_.y, z = pos_.z}, {name = "digicompute:"..node.."_on", param2 = temp.param2}) -- set node to on after 5 seconds
  end, vector.new(pos))
  local meta = minetest.get_meta(pos) -- get meta
  -- if setup is not true, use set name formspec
  if meta:get_string("setup") ~= "true" then
    meta:set_string("formspec", digicompute.formspec_name("")) -- set formspec
  else -- use default formspec
    -- if not when_on, use blank
    if not digicompute.os.when_on(pos) then
      meta:set_string("formspec", digicompute.formspec("", "")) -- set formspec
    end
    digicompute.os.refresh(pos) -- refresh
  end
end
-- turn off
function digicompute.off(pos, node)
  local temp = minetest.get_node(pos) -- get node
  local meta = minetest.get_meta(pos) -- get meta
  meta:set_string("formspec", "") -- clear formspec
  minetest.swap_node({x = pos.x, y = pos.y, z = pos.z}, {name = "digicompute:"..node, param2 = temp.param2}) -- set node to off
end
-- reboot
function digicompute.reboot(pos, node)
  digicompute.off(pos, node)
  digicompute.on(pos, node)
end
-- clear
function digicompute.clear(field, pos)
  local meta = minetest.get_meta(pos) -- get meta
  meta:set_string(field, "") -- clear value
end
-- /SYSTEM FUNCTIONS

function digicompute.register_terminal(termstring, desc)
  -- check os
  if not desc.os then
    desc.os = "bios"
  end
  digicompute.os.load(desc.os) -- load os
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
          if digicompute.os.digiline ~= false then
            local meta = minetest.get_meta(pos) -- get meta
            -- if channel is correct, turn on
            if channel == meta:get_string("channel") then
              if msg.system == digicompute.os.digiline_on then
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
          if digicompute.os.digiline ~= false and digicompute.os.on:find("digiline") then
            local meta = minetest.get_meta(pos) -- get meta
            if channel ~= meta:get_string("channel") then return end -- ignore if not proper channel
            if msg.system then
              if msg.system == digicompute.os.clear then digicompute.clear("output", pos) -- clear output
              elseif msg.system == digicompute.os.off then digicompute.off(pos, termstring) -- turn off
              elseif msg.system == digicompute.os.reboot then digicompute.reboot(pos, termstring) -- reboot
              else digicompute.os.proc_digiline({x = pos.x, y = pos.y, z = pos.z}, fields.input) end -- else, hand over to OS
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
      if digicompute.os.clear_on_close == true then
        local meta = minetest.get_meta(pos) -- get meta
        meta:set_string("formspec", digicompute.formspec("", "")) -- clear formspec
      end
    end,
    on_receive_fields = function(pos, formname, fields, sender) -- precess formdata
      local meta = minetest.get_meta(pos) -- get meta
      -- if name, set
      if fields.name then
        meta:set_string("name", fields.name) -- set name
        meta:set_string("setup", "true") -- set computer to configured
        -- try to run when_on
        if digicompute.os.when_on(pos) then return true end
        meta:set_string("formspec", digicompute.formspec(meta:get_string("input"), meta:get_string("output"))) -- update formspec
        return
      end

      -- if submitted, process basic commands, pass on to os
      if fields.submit then
        if fields.input == digicompute.os.clear then meta:set_string("formspec", digicompute.formspec("",""))
        elseif fields.input == digicompute.os.off then digicompute.off(pos, termstring) -- set off
        elseif fields.input == digicompute.os.reboot then digicompute.reboot(pos, termstring) -- reboot
        else digicompute.os.proc_input(pos, fields.input) end -- turn over to os
      end
    end,
  })
end
