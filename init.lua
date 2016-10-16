-- digicompute/init.lua
digicompute = {}
-- variables
digicompute.modpath = minetest.get_modpath("digicompute") -- modpath
local modpath = digicompute.modpath -- modpath pointer

-- logger
function digicompute.log(content, log_type)
  if log_type == nil then log_type = "action" end
  minetest.log(log_type, "[digicompute] "..content)
end

-- create mod world dir
datalib.mkdir(datalib.worldpath.."/digicompute")
digicompute.path = datalib.worldpath.."/digicompute"

-- FORMSPECS
-- normal
function digicompute.formspec(input, output)
  if not output then local output = "" end
  if not input then local input = "" end
  -- formspec
  local formspec =
    "size[10,11]"..
    default.gui_bg_img..
    "textarea[.25,.25;10,10.5;output;Output:;"..output.."]"..
    "button[0,9.5;10,1;update;Update Output]"..
    "field[.25,10.75;9,1;input;;"..input.."]"..
    "button[8.7,10.43;1.30,1;submit;<enter>]"
  return formspec -- return formspec text
end
-- set name
function digicompute.formspec_name(computer)
  if not computer then local computer = "" end -- use blank channel is none specified
  local formspec =
    "size[6,1.7]"..
    default.gui_bg_img..
    "field[.25,0.50;6,1;name;Computer Name:;"..computer.."]"..
    "button[4.95,1;1,1;submit_name;Set]"
  return formspec
end
-- /FORMSPECS

-- load resources
dofile(modpath.."/api.lua") -- load api
dofile(modpath.."/nodes.lua") -- load nodes
