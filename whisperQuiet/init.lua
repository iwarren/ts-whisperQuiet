--
-- Testmodule initialisation, this script is called via autoload mechanism when the
-- TeamSpeak 3 client starts.
--

require("ts3init")              -- Required for ts3RegisterModule
require("ts3defs")
require("whisperQuiet/events")  -- Forwarded TeamSpeak 3 callbacks

local MODULE_NAME = "whisperQuiet"

-- Create menus
local function createMenus(moduleMenuItemID)
	-- Store value added to menuIDs to be able to calculate menuIDs for this module again for setPluginMenuEnabled (see demo.lua)
	whisperQuiet_events.moduleMenuItemID = moduleMenuItemID

	return {
		{ts3defs.PluginMenuType.PLUGIN_MENU_TYPE_GLOBAL,  whisperQuiet_events.menuIDs.MENU_ID_GLOBAL_1,  "Whisper Quiet: Enable",  ""},
		{ts3defs.PluginMenuType.PLUGIN_MENU_TYPE_GLOBAL,  whisperQuiet_events.menuIDs.MENU_ID_GLOBAL_2,  "Whisper Quiet: Disable",  ""},
		{ts3defs.PluginMenuType.PLUGIN_MENU_TYPE_GLOBAL,  whisperQuiet_events.menuIDs.MENU_ID_GLOBAL_3,  "Whisper Quiet Ducking Level: 6 db",  ""},
		{ts3defs.PluginMenuType.PLUGIN_MENU_TYPE_GLOBAL,  whisperQuiet_events.menuIDs.MENU_ID_GLOBAL_4,  "Whisper Quiet Ducking Level: 10 db",  ""},
		{ts3defs.PluginMenuType.PLUGIN_MENU_TYPE_GLOBAL,  whisperQuiet_events.menuIDs.MENU_ID_GLOBAL_5,  "Whisper Quiet Ducking Level: 14 db",  ""},
		{ts3defs.PluginMenuType.PLUGIN_MENU_TYPE_GLOBAL,  whisperQuiet_events.menuIDs.MENU_ID_GLOBAL_6,  "Whisper Quiet Ducking Level: Squelched",  ""}
	}
end
	
-- Define which callbacks you want to receive in your module. Callbacks not mentioned
-- here will not be called. To avoid function name collisions, your callbacks should
-- be put into an own package.
local registeredEvents = {
	createMenus = createMenus,
	onTalkStatusChangeEvent = whisperQuiet_events.onTalkStatusChangeEvent,
	onMenuItemEvent = whisperQuiet_events.onMenuItemEvent
}

-- Register your callback functions with a unique module name.
ts3RegisterModule(MODULE_NAME, registeredEvents)
