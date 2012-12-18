-- Call back function registration

-- Default level to lower channel when whispers come in
-- volume boost is -50 to +20 dB (not linear since we are dealing with dB's)
-- Options: -6,-10,-14,-50
local whisperChannelLevel = -6

-- Control if plugin is enabled
local isWhisperQuietEnabled = true

-- Default menu id
local moduleMenuItemID = 0

local menuIDs = {
	MENU_ID_GLOBAL_1  = 1,
	MENU_ID_GLOBAL_2  = 2,
	MENU_ID_GLOBAL_3  = 3,
	MENU_ID_GLOBAL_4  = 4,
	MENU_ID_GLOBAL_5  = 5,
	MENU_ID_GLOBAL_6  = 6
}

-- Initialize some maps
tableWhispers = {}
tableWhispersProxy = {}

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

local function onMenuItemEvent(serverConnectionHandlerID, menuType, menuItemID, selectedItemID)
	print("Whisper Quiet: onMenuItemEvent: " .. serverConnectionHandlerID .. " " .. menuType .. " " .. menuItemID .. " " .. selectedItemID)
	if menuItemID == 1 then
		isWhisperQuietEnabled = true
		ts3.printMessageToCurrentTab("===Whisper Quiet Enabled===") 
		--ts3.printMessageToCurrentTab("Active speakers in your current channel will have their transmit volume lowered when whispers are active")
	elseif menuItemID == 2 then
		isWhisperQuietEnabled = false
		ts3.printMessageToCurrentTab("===Whisper Quiet Disabled===") 
    elseif menuItemID == 3 then
	    whisperChannelLevel = -6
    elseif menuItemID == 4 then
	    whisperChannelLevel = -10
	elseif menuItemID == 5 then
	    whisperChannelLevel = -14
	elseif menutItemID == 6 then
	    whisperChannelLevel = -50
	else
		print("ERROR: Plugin menu command sent that is not recognized")
	end
end

local function onTalkStatusChangeEvent(serverConnectionHandlerID, status, isReceivedWhisper, clientID)
    --Debug:
    --print("Test: onTalkStatusChangeEvent: " .. serverConnectionHandlerID .. " " .. status .. " " .. isReceivedWhisper .. " " .. clientID)
	if isWhisperQuietEnabled == true then
			-- Create a table holding all people whispering. 
		--We will keep channel volume low while length > 0 and set it back once the last whisper is done.    
		if isReceivedWhisper == 1 and status == 1 then
			-- Add the client to the whisper dictionary
			table.insert(tableWhispers, clientID)
			tableWhispersProxy[clientID] = 1
			--Debug print(#tableWhispers)
			-- Add a reference to the clientID to the array, want to do a map but I can't no way to determine size of a dictionary :/
		elseif isReceivedWhisper == 1 and status == 0 then
			for i=1, #tableWhispers do
				local removedClient = false
				if tableWhispers[i] == clientID then
					table.remove(tableWhispers, i)
					-- Remove the client from the whisper map
					removedClient = true
				end
			end
			tableWhispersProxy[clientID] = nil
			if removedClient == false then
				print("ERROR: client was not found in the array of whisperers... something went wrong")
			end
			--Debug print(#tableWhispers)
		end
		
		local currentChannelID = getCurrentChannel(serverConnectionHandlerID)

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
					local tempClientId = clientList[i]
					
					-- TODO Do not mute whisperer if they are in this channel
					if tableWhispersProxy[tempClientId] == nil then
						local error = ts3.setClientVolumeModifier(serverConnectionHandlerID, tempClientId, whisperChannelLevel)
					end
					
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
end

whisperQuiet_events = {
	menuIDs = menuIDs,
	moduleMenuItemID = moduleMenuItemID,
	onNewChannelEvent = onNewChannelEvent,
	onTalkStatusChangeEvent = onTalkStatusChangeEvent,
	onMenuItemEvent = onMenuItemEvent
}
