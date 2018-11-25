local option = ...
option = option[1]

if option then
	if option == "-r" then
		system.reboot()
	else
		print("Invalid option (see help shutdown)")
	end
else
	system.shutdown()
end
