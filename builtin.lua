-- digicompute/builtin.lua

digicompute.builtin = {}
local builtin = digicompute.builtin

-- [function] check if file exists
function builtin.exists(path)
	if io.open(path, "r") then return true end
end

-- [function] list contents
function builtin.list(path)
	local files = minetest.get_dir_list(path, false)
	local subdirs = minetest.get_dir_list(path, true)

	local retval = {
		files = files,
		subdirs = subdirs,
	}

	if not files and not subdirs then
		retval = nil
	end

	return retval
end

-- [function] create file
function builtin.create(path)
	local f = io.open(path, "w") -- create file
	f:close() -- close file
	return true
end

-- [function] write to file
function builtin.write(path, data, mode)
	if mode ~= "w" and mode ~= "a" then
		mode = "w"
	end
	local f = io.open(path, mode) -- open file for writing
	f:write(data) -- write data
	f:close() -- close file
	return true
end

-- [function] read file
function builtin.read(path)
	local f = io.open(path, "r") -- open file for reading
	if f then
		local data = f:read("*all") -- read and store all data
		f:close() -- Close file
		return data -- return file contents
	end
end

-- [function] copy file
function builtin.copy(original, new)
	original = builtin.read(original) -- read
	if original then
		builtin.write(new, original) -- write
		return true
	end
end

-- [function] create directory
function builtin.mkdir(path)
	if not io.open(path) then
		if minetest.mkdir then
			minetest.mkdir(path) -- create directory if minetest.mkdir is available
		elseif os.execute then
			os.execute('mkdir "'..path..'"') -- create directory with os mkdir command
		else
			return false
		end
		return true
	end
end

-- [function] remove directory
function builtin.rmdir(path)
	if builtin.list(path) then
		-- [local function] remove files
		local function rm_files(ppath, files)
			for _, f in ipairs(files) do
				os.remove(ppath.."/"..f)
			end
		end

		-- [local function] check and rm dir
		local function rm_dir(dpath)
			local files = minetest.get_dir_list(dpath, false)
			local subdirs = minetest.get_dir_list(dpath, true)
			rm_files(dpath, files)
			if subdirs then
				for _, d in ipairs(subdirs) do
					rm_dir(dpath.."/"..d)
				end
			end

			local ok = os.remove(dpath) -- TODO: TEST
			if not ok then
				if os.execute then
					os.execute("rmdir "..dpath)
				end
			end
		end

		local len = path:len()

		if path:sub(len, len) == "/" then
			path = path:sub(1, -2)
		end

		rm_dir(path)
		return true
	end
end

-- [function] copy directory
function builtin.cpdir(original, new)
	if builtin.list(original) then
		-- [local function] copy files
		local function copy_files(opath, npath, files)
			for _, f in ipairs(files) do
				builtin.copy(opath.."/"..f, npath.."/"..f)
			end
		end

		-- [local function] check and copy dir
		local function copy_dir(opath, npath)
			builtin.mkdir(npath)
			local files = minetest.get_dir_list(opath, false)
			local subdirs = minetest.get_dir_list(opath, true)
			copy_files(opath, npath, files)
			for _, d in ipairs(subdirs) do
				copy_dir(opath.."/"..d, npath.."/"..d)
			end
		end

		copy_dir(original, new)
		return true
	end
end
