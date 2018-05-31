local path = ...
local old  = path[1]
local new  = path[2]

if old and new then
	if fs.exists(old) then
		if not fs.exists(new) then
			if fs.copy(old, new) then
				print("Copied "..old.." to "..new)
			else
				print(old.." is a directory")
			end
		else
			print(new.." already exists")
		end
	else
		print(old.." does not exist")
	end
else
	print("Must specify original and new path (see help cp)")
end
