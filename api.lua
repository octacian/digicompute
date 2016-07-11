-- digiterm/api.lua

-- FORMSPECS
digiterm.formspec = {}
-- normal
function digiterm.formspec.normal(output, input)
  return 'size[10,11] textarea[.25,.25;10,10.5;output;;'..output..'] button[0,9.5;10,1;update;update] field[.25,10.75;9,1;input;;'..input..'] button[9,10.5;1,1;submit;submit]'
end
-- refresh
function digiterm.formspec.operating(startspace)
  return (startspace and ' ' or '')..digiterm.formspec.normal('${output}', '${input}');
end
-- /FORMSPECS

-- SYSTEM FUNCTIONS
digiterm.system = {}

function digiterm.register_terminal(itemstring, desc)
  -- off
  minetest.register_node("digiterm:"..itemstring, {
    description = desc.description,
    tiles = desc.off_tiles,
    paramtype2 = "facedir",
    groups = {cracky = 2, not_in_creative_inventory = 1},
    sounds = default.node_sound_stone_defaults(),
    digiline = {
      receptor = {},
      effector = {
        action = function(pos, node, channel, msg)
          local meta = minetest.get_meta(pos) -- get meta =
          -- if channel is correct, turn on
          if channel == meta:get_string("channel") then
            if msg.system == "on" then
              digiterm.system.on(pos)
            end
          end
        end
      },
    },
    --on_rightclick = digiterm.system.on(pos, itemstring),
  })
  -- bios
  minetest.register_node("digiterm:"..itemstring.."_bios", {
    description = desc.description,
    tiles = desc.bios_tiles,
    paramtype2 = "facedir",
  	groups = {cracky = 2, not_in_creative_inventory = 1},
  	sounds = default.node_sound_stone_defaults(),
  })
  -- on
  minetest.register_node("digiterm:"..itemstring.."_on", {
    description = desc.description,
    tiles = desc.on_tiles,
    paramtype2 = "facedir",
  	groups = {cracky = 2},
  	sounds = default.node_sound_stone_defaults(),
    digiline = {
      receptor = {},
      effector = {
        action = function(pos, node, channel, msg)
          local meta = minetest.get_meta(pos) -- get meta
          if channel ~= meta:get_string("channel") then return end -- ignore if not proper channel
          if type(msg) ~= "table" then
            meta:set_string("output", meta:get_string("output")..msg) -- set output buffer meta
          elseif type(msg) == "table" then -- process tables
            if msg.display == "clear" then meta:set_string("output", "") end -- clear display
          end
        end
      },
    },
    on_construct = function(pos) -- set meta and formspec
      local meta = minetest.get_meta(pos) -- get meta
      meta:set_string("output", "") -- output buffer
      meta:set_string("input", "") -- input buffer
      meta:set_string("formspec", "field[channel;Set Channel:;${channel}]") -- channel specification formspec
    end,
    on_receive_fields = function(pos, formname, fields, sender) -- precess formdata
      local meta = minetest.get_meta(pos) -- get meta
      -- if channel received, set meta
      if fields.channel then
        meta:set_string("channel", fields.channel) -- set channel meta
        meta:set_string("formspec", digiterm.formspec.operating(true)) -- refresh formspec
        return
      end
      -- if submit, reset field print to output and send digiline
      if fields.submit then
        digiline:receptor_send(pos, digiline.rules.default, meta:get_string("channel"), fields.input) -- send digiline data
        meta:set_string("output", meta:get_string("channel").."@minetest:~$\n "..fields.input.."\n") -- repeat input
      else meta:set_string("input", fields.input) end -- else, do nothing
      -- refresh formspec
      meta:set_string("formspec", digiterm.formspec.operating(meta:get_string("formspec"):sub(0, 1) ~= " "))
    end,
    --on_punch = digiterm.system.off(pos, itemstring),
  })
end
