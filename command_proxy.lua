--Only a little sus

if commands ~= nil then
	while true do
		os.sleep(0.5)
		local input = fs.open("cmd_proxy/input.txt","r")
		if input then
			local contents = input.readAll()
			input.close()
			if contents ~= "" then
				print("Command: "..contents)
				input = fs.open("cmd_proxy/input.txt","w")
				input.close()
			else
			
			end
		end
	end
end