local ccString = require "cc.strings"

local function initialiseServer()
	local dataProtocol = "dataLine"
	local infoProtocol = "infoLine"
	local serverName = "server"
	rednet.host(dataProtocol, serverName)
	rednet.host(infoProtocol, serverName)
	print(serverName .. " started")
	print(dataProtocol .. " protocol online")
	print(infoProtocol .. " protocol online")
end

local function resetMonitor(monitor)
	monitor.clear()
	monitor.setCursorPos(1,1)
	monitor.setTextColour(colours.white)
end

local function displayData(data)
	local monitor = peripheral.find("monitor")
	resetMonitor(monitor)
	local stressPercentage = math.ceil(data.percentage)
	if stressPercentage >= 75 then
		monitor.setTextColour(colours.red)
	elseif stressPercentage >= 50 then
		monitor.setTextColour(colours.yellow)
	else
		monitor.setTextColour(colours.green)
	end
	local textToWrite = data.currentStress .. "/" .. data.stressCapacity .. "su " .. stressPercentage .. "%"
	monitor.write(textToWrite)
end

local function sendDataToClient(id, data)
	
end 

local function recieveData()
	local data
	while true do
		local id, message, protocol = rednet.receive()
		if message.sType == "lookup" then
			print("Discovery request sent to: " .. id)
		elseif protocol == "infoLine" then
			if data ~= nil then
				sendDataToClient(id,data)
			else
				rednet.send(id,nil,"infoLine")
			end
		elseif protocol == "dataLine" then
			print("Message recieved from: " .. id .. ", with protocol: " .. protocol)
			print(textutils.serialise(message))
			data = message
			displayData(message)
		else
			if protocol == nil then
				printError("Unable to read message from: " .. id)
			else
				printError("Unable to read message from: " .. id .. ", with protocol: " .. protocol)
			end
			print(textutils.serialise(message))
		end
	end
end

local function setup()
	local modem = peripheral.find("modem")
	local monitor = peripheral.find("monitor")
	if monitor == nil then
		printError("Unable to find monitor")
		return nil
	end
	if modem == nil then
		printError("Unable to find modem")
		return nil
	end
	local modemName = peripheral.getName(modem)
	rednet.open(modemName)
	return true
end

local function start()
	if setup() == nil then
		return
	end 
	initialiseServer()
	recieveData()
end

start()