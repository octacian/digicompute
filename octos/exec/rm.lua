local path = ...
path = path[1]

if path then
  if fs.exists(path) then
    if fs.remove(path) then
      print("Removed file "..path)
    else
      print(path.." is a directory")
    end
  else
    print(path.." does not exist")
  end
else
  print("Must specify path (see help rm)")
end
