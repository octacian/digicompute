-- Set OS values
set_os("clear", "clear")
set_os("off", "shutdown")
set_os("reboot", "shutdown -r")
set_os("prefix", get_attr("name")..":~$ ")

-- Set initial output value
set_output("Welcome to octOS version 0.2.\n\n"..get_os("prefix")) -- print welcome

-- Refresh view
refresh()
