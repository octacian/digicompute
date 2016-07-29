-- bios os
digicompute.os.clear = "clear" -- clear command
digicompute.os.off = "shutdown" -- shutdown command
digicompute.os.reboot = "reboot" -- reboot command
digicompute.os.digiline = false -- do not support digilines
digicompute.os.network = false -- do not support network
digicompute.os.on = "rightclick" -- on command (rightclick)
digicompute.os.clear_on_close = false -- do not clear output on close

-- when_on
function digicompute.os.when_on(pos)
  digicompute.os.set(pos, "output", "Welcome to BiosOS version 0.1.\n\n"..digicompute.os.get(pos, "name")..":~$ ") -- print welcome
end

-- process input
function digicompute.os.proc_input(pos, input)
  digicompute.os.set(pos, "output", digicompute.os.get(pos, "output")..input.."\n"..digicompute.os.get(pos, "name")..":~$ ") -- print input
  digicompute.os.refresh(pos) -- refresh
end
