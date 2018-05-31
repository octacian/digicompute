if get_attr("run") == "os/exec/nano.lua" then
	local input = get_attr("input")
	if input == "save" then
		fs.write(get_userdata("nano:path"), get_output(), "w")
	elseif input == "discard" or input == "exit" then
		if input == "exit" then
			fs.write(get_userdata("nano:path"), get_output(), "w")
		end

		set_userdata("nano:path", nil) -- Clear nano path
		set_os("prefix", get_userdata("nano:prefix")) -- Restore prefix
		set_userdata("nano:prefix", nil) -- Clear stored prefix
		set_output(get_userdata("nano:output").."\n"..get_os("prefix")) -- Restore output
		set_userdata("nano:output", nil) -- Clear stored output
		set_run() -- Clear custom run file

		-- Restore "output editable" to previous state
		if not get_userdata("nano:output_was_editable") then
			set_output_editable(false)
		else
			set_userdata("nano:output_was_editable", nil)
		end
	end

	set_input("") -- Clear input
	refresh() -- Refresh formspec
else
	local path = ...
	path = path[1]

	if path then
		local contents = fs.read(path) or ""

		set_userdata("nano:path", path) -- Store editing path for later
		set_userdata("nano:output", get_output()) -- Store old output for later
		set_output(contents) -- Set output to contents of file or blank
		set_userdata("nano:prefix", get_os("prefix")) -- Store OS prefix for later
		set_os("prefix", "") -- Set OS prefix to a blank string
		set_help("\"save\" to save, \"discard\" to discard and exit, \"exit\" to save and exit") -- Add information to help
		set_run("os/exec/nano.lua") -- Set run file to the nano executable

		-- Ensure output is editable
		if get_attr("output_editable") == "false" then
			set_output_editable(true)
		else
			set_userdata("nano:output_was_editable", "true")
		end

		refresh() -- Refresh formspec
	else
		print("Must specify path (see help nano)")
	end
end
