local path = ...
path = path[1]

if path then
  if not fs.exists(path) then
    if fs.create(path) then
      print("Created file "..path)
    else
      print("Could not create file "..path)
    end
  else
    print(path.." already exists")
  end
else
  print("Must specify path (see help touch)")
end
