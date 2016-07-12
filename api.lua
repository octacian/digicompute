-- digiterm/api.lua

-- SYSTEM FUNCTIONS
-- turn on
function digiterm.on(pos, node)
  minetest.swap_node({x = pos.x, y = pos.y, z = pos.z}, {name = "digiterm:"..node.."_bios"}) -- set node to bios
  minetest.after(3.5, function(pos_)
    minetest.swap_node({x = pos_.x, y = pos_.y, z = pos_.z}, {name = "digiterm:"..node.."_on"}) -- set node to on after 5 seconds
  end, vector.new(pos))
  local meta = minetest.get_meta(pos) -- get meta
  meta:set_string("formspec", digiterm.formspec_normal("", ""))
end
-- turn off
function digiterm.off(pos, node)
  minetest.swap_node({x = pos.x, y = pos.y, z = pos.z}, {name = "digiterm:"..node}) -- set node to off
  local meta = minetest.get_meta(pos) -- get meta
  meta:set_string("formspec", nil) -- clear formspec
end
-- reboot
function digiterm.reboot(pos, node)
  digiterm.off(pos, node)
  digiterm.on(pos, node)
end
-- clear
function digiterm.clear(field, pos)
  local meta = minetest.get_meta(pos) -- get meta
  meta:set_string(field, "") -- clear value
end
-- /SYSTEM FUNCTIONS

function digiterm.register_terminal(termstring, desc)
  -- check os
  if not desc.os then
    desc.os = "bios"
  end
  digiterm.os.load(desc.os) -- load os
  -- off
  minetest.register_node("digiterm:"..termstring, {
    description = desc.description,
    tiles = desc.off_tiles,
    paramtype2 = "facedir",
    groups = {cracky = 2},
    sounds = default.node_sound_stone_defaults(),
    digiline = {
      receptor = {},
      effector = {
        action = function(pos, node, channel, msg)
          if digiterm.os.digiline ~= false then
            local meta = minetest.get_meta(pos) -- get meta
            -- if channel is correct, turn on
            if channel == meta:get_string("channel") then
              if msg.system == digiterm.os.digiline_on then
                digiterm.on(pos, termstring)
              end
            end
          end
        end
      },
    },
    on_rightclick = function(pos)
      digiterm.on(pos, termstring)
    end,
  })
  -- bios
  minetest.register_node("digiterm:"..termstring.."_bios", {
    description = desc.description,
    tiles = desc.bios_tiles,
    paramtype2 = "facedir",
  	groups = {cracky = 2},
  	sounds = default.node_sound_stone_defaults(),
  })
  -- on
  minetest.register_node("digiterm:"..termstring.."_on", {
    description = desc.description,
    tiles = desc.on_tiles,
    paramtype2 = "facedir",
  	groups = {cracky = 2},
  	sounds = default.node_sound_stone_defaults(),
    digiline = {
      receptor = {},
      effector = {
        action = function(pos, node, channel, msg)
          if digiterm.os.digiline ~= false then
            local meta = minetest.get_meta(pos) -- get meta
            if channel ~= meta:get_string("channel") then return end -- ignore if not proper channel
            if msg.system then
              if msg.system == digiterm.os.clear then digiterm.clear("output", pos) -- clear output
              elseif msg.system == digiterm.os.off then digiterm.off(pos, termstring) -- turn off
              elseif msg.system == digiterm.os.reboot then digiterm.reboot(pos, termstring) -- reboot
              else digiterm.os.proc_digiline({x = pos.x, y = pos.y, z = pos.z}, fields.input) end -- else, hand over to OS
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
      meta:set_string("formspec", digiterm.formspec_name(name)) -- computer name formspec
    end,
    on_receive_fields = function(pos, formname, fields, sender) -- precess formdata
      local meta = minetest.get_meta(pos) -- get meta
      -- if name received, set
      if fields.name then
        meta:set_string("name", fields.name) -- set name
        meta:set_string("formspec", digiterm.formspec_normal(meta:get_string("input"), meta:get_string("output"))) -- refresh formspec
        return
      end
      -- if submit, check for keywords and process according to os
      if fields.submit then
        if fields.input == digiterm.os.clear then digiterm.clear("output", pos) -- clear output
        elseif fields.input == digiterm.os.off then digiterm.off(pos, termstring) -- turn off
        elseif fields.input == digiterm.os.reboot then digiterm.reboot(pos, termstring) -- reboot
        else digiterm.os.proc_input({x = pos.x, y = pos.y, z = pos.z}, fields.input) end -- else, hand over to OS
        digiterm.clear("input", pos) -- clear input field
      else meta:set_string("input", fields.input) end -- else, keep input
      -- refresh formspec
      meta:set_string("formspec", digiterm.formspec_normal(meta:get_string("input"), meta:get_string("output")))
    end,
  })
end
