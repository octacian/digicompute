local path = ...
path = path[1]

if path then
	local contents = fs.list(path)
	local result = table.concat(contents.files, " ") .. " " .. table.concat(contents.subdirs, " ")
	print(result)
else
	print("Must specify path (see help ls)")
end
