if get_attr("run") == "os/exec/nano.lua" then
	local input = get_attr("input")
	if input == "save" then
		fs.write(ram.nano_path, system.output, "w")
	elseif input == "discard" or input == "exit" then
		if input == "exit" then
			fs.write(ram.nano_path, system.output, "w")
		end

		ram.nano_path = nil -- Clear nano path
		system.prefix = ram.nano_prefix -- Restore prefix
		ram.nano_prefix = nil -- Clear stored prefix
		system.output = ram.nano_output.."\n"..system.prefix -- Restore output
		ram.nano_output = nil -- Clear stored output
		set_run() -- Clear custom run file

		-- Restore "output editable" to previous state
		if not ram.nano_output_was_editable then
			system.output_editable = false
		else
			ram.nano_output_was_editable = nil
		end
	end

	system.input = "" -- Clear input
	refresh() -- Refresh formspec
else
	local path = ...
	path = path[1]

	if path then
		local contents = fs.read(path) or ""

		ram.nano_path = path -- Store editing path for later
		ram.nano_output = system.output -- Store old output for later
		system.output = contents -- Set output to contents of file or blank
		ram.nano_prefix = system.prefix -- Store OS prefix for later
		system.prefix = "" -- Set OS prefix to a blank string
		set_help("\"save\" to save, \"discard\" to discard and exit, \"exit\" to save and exit") -- Add information to help
		set_run("os/exec/nano.lua") -- Set run file to the nano executable

		-- Ensure output is editable
		if get_attr("output_editable") == "false" then
			system.output_editable = true
		else
			ram.nano_output_was_editable = true
		end

		refresh() -- Refresh formspec
	else
		print("Must specify path (see help nano)")
	end
end
