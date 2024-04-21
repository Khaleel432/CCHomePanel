local function getScriptName(name)
	local urlArray = {}
	for word in string.gmatch(name, "([^*/]+)") do
		table.insert(urlArray, word)
	end
	return urlArray[#urlArray]
end

local function updateFile(filepath, content)
	local file = fs.open(filepath, "w")
	file.write(content)
	file.close()
end

local function updateScript()
	local scriptToUpdate = "https://raw.githubusercontent.com/Khaleel432/CCHomePanel/main/transmitter.lua"
	local request = http.get(scriptToUpdate);
	local content = request.readAll();
	local scriptName = getScriptName(scriptToUpdate);
	local filepath = fs.combine("/startup",scriptName)
	request.close()
	updateFile(filepath, content)
	print("File saved to " .. filepath)
	shell.execute(filepath)
end

local function start()
	updateScript()
end

start()