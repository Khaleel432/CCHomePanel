local function resetText()
	term.clear()
	term.setCursorPos(1,1)
	term.setTextColour(colours.white)
end

local function displayData(data)
	resetText()
	local stressPercentage = math.ceil(data.percentage)
	if stressPercentage >= 75 then
		term.setTextColour(colours.red)
	elseif stressPercentage >= 50 then
		term.setTextColour(colours.yellow)
	else
		term.setTextColour(colours.green)
	end
	local textToWrite = data.currentStress .. "/" .. data.stressCapacity .. "su " .. stressPercentage .. "%"
	term.write(textToWrite)
end

local function receiveData()
	local serverId = rednet.lookup("infoLine","server")
	rednet.send(serverId,"Request for data","infoLine")
	while true do
		local id, message, protocol = rednet.receive()
		if message == nil then
			printError("No data avaliable")
			return nil
		end
		displayData(message)
	end
	return true
end

local function setup()
	local modem = peripheral.find("modem")
	if modem == nil then
		printError("Unable to find modem")
		return
	end
	local modemName = peripheral.getName(modem)
	rednet.open(modemName)
	return true
end

local function start()
	if setup() == nil then
		return
	end
	receiveData()
end

start()