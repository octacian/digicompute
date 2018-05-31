local path = ...
path = path[1]

if path then
	if not fs.exists(path) then
		if fs.mkdir(path) then
			print("Created directory "..path)
		else
			print("Could not create directory "..path)
		end
	else
		print(path.." already exists")
	end
else
	print("Must specify path (see help mkdir)")
end
