local clients = {}
local turtles = {}
local data = {}
local serverName = "server"
local serverProtocol = "serverLine"
local requestDataProtocol = "requestData"
local receiveDataProtocol = "transmitData"
local receiveTurtleProtocol = "registerTurtle"

local Button = {startX = 0, startY = 0, endX = 0, endY = 0, isActive = false}

function Button.new(startX, startY, endX, endY, isActive)
	local o = {}
	setmetatable(o,self)
	o.__index = self
	o.startX = startX
	o.startY = startY
	o.endX = endX
	o.endY = endY
	o.isActive = isActive
	return o
end

function Button:returnTable()
	local table = {
		startX = self.startX,
		startY = self.startY,
		endX = self.endX,
		endY = self.endY,
		isActive = self.isActive
	}
	return table
end

local function resetMonitor(monitor)
	monitor.clear()
	monitor.setCursorPos(1,1)
	monitor.setTextColour(colours.white)
end

local function getEnergyColour(stressPercentage)
	if stressPercentage >= 75 then
		return colours.red
	end
	if stressPercentage >= 50 then
		return colours.yellow
	end
	return colours.green
end

local function setCursorNextLine(monitor)
	local x, y = monitor.getCursorPos()
	monitor.setCursorPos(1,y+1)
end

local function writeLine(monitor, text, colour, addNewLine)
	monitor.setTextColour(colour)
	monitor.write(text)
	monitor.setTextColour(colours.white)
	if addNewLine then
		setCursorNextLine(monitor)
	end
end

local function drawButton(monitor, button)
	local width, height = monitor.getSize()
	local terminal = term.redirect(monitor)
	if button.isActive then
		paintutils.drawFilledBox(button.startX,button.startY,button.endX,button.endY, colors.red)
	else
		paintutils.drawFilledBox(button.startX,button.startY,button.endX,button.endY, colors.green)
	end
	monitor.setCursorPos(button.endX + 2, button.endY)
	monitor.setBackgroundColour(colors.black)
	
	term.redirect(terminal)
end

local function printTurtles(monitor)
	writeLine(monitor,"Active turtles:", colours.white, true)
	for id, turtle in pairs(turtles) do
		writeLine(monitor,turtle.turtleName .. "," .. turtle.state .. " ", colours.white, false)
		local width, height = monitor.getCursorPos()
		local button = turtles[id].button
		if button == nil then
			button = Button.new(width,height,width,height, false)
			turtles[id].button = button
		end
		drawButton(monitor, button)
		setCursorNextLine(monitor)
	end
end

local function printEnergyData(monitor, data)
	local stressPercentage = math.ceil(data.percentage)
	local energyColour = getEnergyColour(stressPercentage)
	local remainingCapacity = data.stressCapacity - data.currentStress
	local energyData = data.currentStress .. "/" .. data.stressCapacity .. "su " .. stressPercentage .. "%" .. "(" .. remainingCapacity .. "su remaining)"
	writeLine(monitor, energyData, energyColour, true)
end

local function displayData()
	while true do
		local monitor = peripheral.find("monitor")
		
		resetMonitor(monitor)
		monitor.setTextScale(1)
		writeLine(monitor,"Energy Network",colours.white, true)
		if next(data) ~= nil then
			printEnergyData(monitor,data)
		else
			writeLine(monitor,"No energy data found",colours.red, true)
		end
		writeLine(monitor,"",colours.white, true)
		if next(turtles) ~= nil then
			printTurtles(monitor)
		end
		sleep(1)
	end
end

local function transmitData()
	while true do
		if (next(data) == nil or next(clients) == nil) then
			sleep(1)
		else
			for index, value in pairs(clients) do
				rednet.send(index,data,requestDataProtocol)
			end
		end
		sleep(1)
	end
end 

local function debug(id,message,protocol)
	print(id)
	print(textutils.serialise(message))
	print(protocol)
end

local function recieveData()
	while true do
		local id, message, protocol = rednet.receive()
		debug(id,message,protocol)
		if message.sType == "lookup" then
			print("Discovery request sent to: " .. id)
		elseif protocol == requestDataProtocol then
			if next(data) == nil then
				rednet.send(id,nil,requestDataProtocol)
			else
				clients[id] = message.computerName
			end
		elseif protocol == receiveDataProtocol then
			data = message
		elseif protocol == receiveTurtleProtocol then
			turtles[id] = message
			while turtles[id].button == nil do
				print("Waiting for button")
				sleep(1)
			end
			rednet.send(id,"register complete",turtles[id].protocol)
		elseif string.find(protocol, "turtleCommand") then
			for key, value in pairs(message) do
				if key == "isActive" then
					turtles[id].button.isActive = value
				else
					turtles[id][key] = value
				end
			end
			-- print(textutils.serialise(turtles[id]))
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

local function initialiseServer()
	rednet.host(serverProtocol, serverName)
	print(serverName .. " started")
	print(serverProtocol .. " protocol online")
end

local function checkMonitorInput()
	local monitor = peripheral.find("monitor")
	while true do
		local event, side, x, y = os.pullEvent("monitor_touch")
		if next(turtles) ~= nil then
			for id, turtle in pairs(turtles) do
				if x >= turtle.button.startX and y >= turtle.button.startY and x <= turtle.button.endX and y <= turtle.button.endY and turtle.button.isActive == false then
					print("Activate for " .. id ..  " command send on protocol " ..turtle.protocol)
					rednet.send(id,"activate",turtle.protocol)
				end
			end
		end
		sleep(1)
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
	resetMonitor(monitor)
	return true
end

local function start()
	if setup() == nil then
		return
	end 
	initialiseServer()
	parallel.waitForAll(recieveData,transmitData,displayData,checkMonitorInput)
end

start()