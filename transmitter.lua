local function transmit(data)
	local serverId = rednet.lookup("dataLine", "server")
	if serverId == nil then
		printError("Unable to find server")
		return nil
	end
	if not(rednet.send(serverId, data, "dataLine")) then
		printError("Lost connection to server")
		return nil
	end
	
	return true
	-- print(textutils.serialise({rednet.lookup("dataLine")}))
end

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
	local currentStress = string.match(targetBlock.getLine(1),"%d+")
	local stressCapacity = string.match(targetBlock.getLine(2),"%d+")
	local percentage = currentStress / stressCapacity * 100
	local data = {
		currentStress = currentStress,
		stressCapacity = stressCapacity,
		percentage = percentage
	}
	return data
end

local function start()
	local blocks = setup();
	if blocks == nil then
		return
	end
	local targetBlock = blocks.targetBlock
	while true do
		local data = getData(targetBlock)
		if transmit(data) == nil then
			return
		end
		sleep(1)
	end
end

local function main()
	start()
end

main()