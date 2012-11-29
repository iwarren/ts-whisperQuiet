-- Call back function registration

local whisperVolume = 0.80
tableWhispers = {}

-- volume boost is -50 to +20 dB (not linear since we are dealing with dB's)
local whisperLevel = 0 - 50 * (1 - whisperVolume)


-- helper functions
-- TODO move these to a different module
local function getCurrentChannel(serverConnectionHandlerID)
	local myClientID, error = ts3.getClientID(serverConnectionHandlerID)
	if error ~= ts3errors.ERROR_ok then
		print("Error getting own client ID: " .. error)
		return
	end
	
	-- Get Channel for the current client ID
	currentChannelID, error = ts3.getChannelOfClient(serverConnectionHandlerID, myClientID)
	if error ~= ts3errors.ERROR_ok then
		print("Error getting own channel: " .. error)
		return
	end
	return currentChannelID
end

-- Listener events
local function onNewChannelEvent(serverConnectionHandlerID, channelID, channelParentID)

end

local function onTalkStatusChangeEvent(serverConnectionHandlerID, status, isReceivedWhisper, clientID)
    print("TestModule: onTalkStatusChangeEvent: " .. serverConnectionHandlerID .. " " .. status .. " " .. isReceivedWhisper .. " " .. clientID)
	local currentChannelID = getCurrentChannel(serverConnectionHandlerID)

	-- Create a table holding all people whispering. 
	--We will keep channel volume low while length > 0 and set it back once the last whisper is done.    
	if isReceivedWhisper == 0 and status == 1 then
		-- Add the client to the whisper dictionary
		tableWhispers[clientID] = 1
		print("Current talkers: " .. #tableWhispers)
	elseif isReceivedWhisper == 0 and status == 0 then
		-- Remove the client from the whisper dictionary
		tableWhispers[clientID] = nil
		print("Current talkers: " .. #tableWhispers)
	end

	if isReceivedWhisper == 1 then
		-- This is the first whisper received
		-- we add the current client to the dictionary first so this should not be 0
		if status == 1 and #tableWhispers == 1 then
			local clientList, error = ts3.getChannelClientList(serverConnectionHandlerID, currentChannelID)
			
			if error ~= ts3errors.ERROR_ok then
				print("Error getting channel client list: " .. error)
				return
			end
			
			for i=1, #clientList do
				local tenpClientId = clientList[i]
				
				-- TODO Do not mute whisperer if they are in this channel
				local error = ts3.setClientVolumeModifier(serverConnectionHandlerID, tempClientId, whisperLevel)
				
				if error ~= ts3errors.ERROR_ok then
					print("Error setting client volume modifier: " .. error)
				end
			end
		elseif status == 1 and #tableWhispers > 1 then
			-- Do nothing, lots of chatter going on
		elseif status == 0 and #tableWhispers >= 1 then
			-- Do nothing, someone stopped talking, but others still are whispering you
		elseif status == 0 and # tableWhispers == 0 then
			-- We remove the client before this point so the dictionary can be 0 at this point
			local clientList, error = ts3.getChannelClientList(serverConnectionHandlerID, currentChannelID)
			if error ~= ts3errors.ERROR_ok then
				print("Error getting channel client list: " .. error)
				return
			end
			for i=1, #clientList do
				local clientId = clientList[i]
				
				local error = ts3.setClientVolumeModifier(serverConnectionHandlerID, clientId, 0)			
				if error ~= ts3errors.ERROR_ok then
					print("Error setting client volume modifier: " .. error)
				end
			end
		end
	end
end

whisperQuiet_events = {
	onNewChannelEvent = onNewChannelEvent,
	onTalkStatusChangeEvent = onTalkStatusChangeEvent
}
