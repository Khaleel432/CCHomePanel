local serverName = "server"
local serverProtocol = "serverLine"
local receiveDataProtocol = "transmitData"

local function setup()
	local targetBlock = peripheral.find("create_target")
	local modem = peripheral.find("modem")
	if targetBlock == nil then
		printError("Unable to find target block")
		return nil
	end
	if modem == nil then
		printError("Unable to find modem")
		return nil
	end

	local blocks = {
		targetBlock = targetBlock,
		modem = modem
	}

	local modemName = peripheral.getName(modem)
	rednet.open(modemName)
	return blocks
end

local function getData(targetBlock)
	local currentStress = string.gsub(string.match(targetBlock.getLine(1),"%d[%d.,]*"),",", "")
	local stressCapacity = string.gsub(string.match(targetBlock.getLine(2),"%d[%d.,]*"),",", "")
	local percentage = (currentStress / stressCapacity) * 100
	local data = {
		currentStress = currentStress,
		stressCapacity = stressCapacity,
		percentage = percentage
	}
	return data
end

local function transmitData(serverId, data)
	rednet.send(serverId, data, receiveDataProtocol)
	return true
end

local function start()
	local blocks = setup();
	local serverId = rednet.lookup(serverProtocol, serverName)
	if blocks == nil then
		return
	end
	if serverId == nil then
		printError("Unable to find server")
		return nil
	end
	local targetBlock = blocks.targetBlock
	while true do
		local data = getData(targetBlock)
		transmitData(serverId,data)
		sleep(1)
	end
end

local function main()
	start()
end

main()