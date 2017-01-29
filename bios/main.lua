local input = get_attr("input")

if input ~= "" then
  print(input, false) -- print input

  local ok, res = run(input)
  if res then print(res) end

  print(get_os("prefix")) -- Print prefix
  set_input("")
  refresh() -- refresh
end
