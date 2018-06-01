-- Set OS values
set_os("clear", "clear")
set_os("off", "shutdown")
set_os("reboot", "shutdown -r")
set_os("prefix", get_attr("name")..":~$ ")

-- Initialize bin table
local bin = {}

-- Load bin file
local bin_contents = fs.list("os/bin")
for _,f in ipairs(bin_contents.files) do
	local fpath    = "os/bin/"..f
	local cmd_info = Settings(fpath):to_table()
	local name     = cmd_info.name or f

	bin[name] = {
		description = cmd_info.description or "",
		params = cmd_info.params or "",
		exec = cmd_info.exec or "os/exec/nil"
	}
end

-- Add additional commands to bin
bin[get_os("clear")] = { description = "Clear the shell output" } -- Clear shell output
bin[get_os("off")] = { description = "Turn off computer" } -- Turn off computer
bin[get_os("reboot")] = { description = "Reboot computer" } -- Reboot computer

-- Save bin table
set_userdata("bin", bin)

-- Set initial output value
set_output("Welcome to octOS version 0.2.\n\n"..get_os("prefix")) -- print welcome

-- Refresh view
refresh()
