local path = ...
path = path[1]

if path then
	if fs.exists(path) then
		print(fs.read(path))
	end
else
	print("Must specify path (see help cat)")
end
