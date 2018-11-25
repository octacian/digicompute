-- Set OS values
system.clear = "clear"
system.off = "shutdown"
system.reboot = "shutdown -r"
system.prefix = get_attr("name")..":~$ "

-- Initialize bin table
local bin = {}

-- Load bin file
local bin_contents = fs.list("os/bin")
for _,f in ipairs(bin_contents.files) do
	local fpath    = "os/bin/"..f
	local cmd_info = fs.read_settings(fpath):to_table()
	local name     = cmd_info.name or f

	bin[name] = {
		description = cmd_info.description or "",
		params = cmd_info.params or "",
		exec = cmd_info.exec or "os/exec/nil"
	}
end

-- Add additional commands to bin
bin[system.clear] = { description = "Clear the shell output" } -- Clear shell output
bin[system.off] = { description = "Turn off computer" } -- Turn off computer
bin[system.reboot] = { description = "Reboot computer" } -- Reboot computer

-- Save bin table
ram.bin = bin

-- Set initial output value
system.output = "Welcome to octOS version 0.2.\n\n"..system.prefix -- print welcome

-- Refresh view
refresh()
