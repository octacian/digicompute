local path = ...
path = path[1]

if path then
	if fs.exists(path) then
		if fs.rmdir(path) then
			print("Removed directory "..path)
		else
			print(path.." is not a directory")
		end
	else
		print(path.." does not exist")
	end
else
	print("Must specify path (see help rmdir)")
end
