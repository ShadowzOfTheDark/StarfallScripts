--Only a little sus

if commands ~= nil then
	term.clear()
	term.setCursorPos(1,1)
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
				output = fs.open("cmd_proxy/output.txt","w")
				local exec, result = commands.exec(contents)
				for _,str in ipairs(result) do
					result.write(result)
				end
				output.close()
			else
			
			end
		end
	end
end
