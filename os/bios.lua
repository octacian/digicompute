-- bios os
digicompute.os.clear = "clear" -- clear command
digicompute.os.off = "shutdown" -- shutdown command
digicompute.os.reboot = "reboot" -- reboot command
digicompute.os.digiline = false -- do not support digilines
digicompute.os.network = false -- do not support network
digicompute.os.on = "rightclick" -- on command (rightclick)
digicompute.os.clear_on_close = false -- do not clear output on close

-- process input
function digicompute.os.proc_input(pos, input)
  if digicompute.os.get("output") == "" then local n = "" else local n = "\n" end -- if output blank, do not use \n
  digicompute.os.set(pos, "output", digicompute.os.get(pos, "output")..n..digicompute.os.get(pos, "name")..":~$ "..input) -- print input
  -- process command
  --if input == ""
  digicompute.os.refresh(pos) -- refresh
end
