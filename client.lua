local serverName = "server"
local serverProtocol = "serverLine"
local requestDataProtocol = "requestData"

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
	local remainingCapacity = data.stressCapacity - data.currentStress
	local textToWrite = data.currentStress .. "/" .. data.stressCapacity .. "su " .. stressPercentage .. "%"
	print(textToWrite)
	if remainingCapacity < 0 then
		print("(overstressed by " .. remainingCapacity .. "su)")
	else
		print("(" .. remainingCapacity .. "su remaining)")
	end
end

local function receiveData()
	local serverId = rednet.lookup(serverProtocol,serverName)
	if serverId == nil then
		printError("Unable to establish connection to server")
		return nil
	end
	local message = {}
	local computerId = os.getComputerID()
	message["computerName"] = "personalPocket" .. computerId
	rednet.send(serverId,message,requestDataProtocol)
	while true do
		local id, message, protocol = rednet.receive(requestDataProtocol)
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
	if receiveData() == nil then
		return
	end
end

start()