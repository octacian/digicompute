local path = ...
local old  = path[1]
local new  = path[2]

if old and new then
	if fs.exists(old) then
		if not fs.exists(new) then
			if fs.cpdir(old, new) and fs.rmdir(old) then
				print("Moved "..old.." to "..new)
			else
				print(old.." is a file")
			end
		else
			print(new.." already exists")
		end
	else
		print(old.." does not exist")
	end
else
	print("Must specify old and new path (see help mv)")
end
