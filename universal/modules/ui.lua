--[[
    UI Module - Universal Script
    Obsidian UI setup, Window, Tabs, and UI Settings tab
]]

local UI = {}
local Config = nil

UI.Window = nil
UI.Library = nil
UI.ThemeManager = nil
UI.SaveManager = nil
UI.Options = nil
UI.Toggles = nil
UI.Tabs = {}

----------------------------------------------------------
-- 🔹 Initialize
function UI.init(config)
	Config = config
end

----------------------------------------------------------
-- 🔹 Load Libraries
function UI.loadLibraries()
	local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
	UI.Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
	UI.ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
	UI.SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
	
	UI.Options = UI.Library.Options
	UI.Toggles = UI.Library.Toggles
end

----------------------------------------------------------
-- 🔹 Create Window
function UI.createWindow()
	UI.Library.ForceCheckbox = false
	UI.Library.ShowToggleFrameInKeybinds = true
	
	UI.Window = UI.Library:CreateWindow({
		Title = "WiniFy",
		Footer = "version: 1.0.0",
		NotifySide = "Right",
		ShowCustomCursor = false,
	})
end

----------------------------------------------------------
-- 🔹 Create Tabs
function UI.createTabs()
	UI.Tabs = {
		Main = UI.Window:AddTab("Main", "user"),
		Combat = UI.Window:AddTab("Combat", "sword"),
		Visuals = UI.Window:AddTab("Visuals", "eye"),
		Teleport = UI.Window:AddTab("Teleport", "map-pin"),
		Server = UI.Window:AddTab("Server", "server"),
		Misc = UI.Window:AddTab("Misc", "settings"),
		["UI Settings"] = UI.Window:AddTab("UI Settings", "settings"),
	}
end

----------------------------------------------------------
-- 🔹 Create UI Settings Tab
function UI.createUISettingsTab()
	local MenuGroup = UI.Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")
	
	MenuGroup:AddToggle("KeybindMenuOpen", {
		Default = UI.Library.KeybindFrame.Visible,
		Text = "Open Keybind Menu",
		Callback = function(value)
			UI.Library.KeybindFrame.Visible = value
		end,
	})
	
	MenuGroup:AddToggle("ShowCustomCursor", {
		Text = "Custom Cursor",
		Default = true,
		Callback = function(Value)
			UI.Library.ShowCustomCursor = Value
		end,
	})
	
	MenuGroup:AddDropdown("NotificationSide", {
		Values = { "Left", "Right" },
		Default = "Right",
		Text = "Notification Side",
		Callback = function(Value)
			UI.Library:SetNotifySide(Value)
		end,
	})
	
	MenuGroup:AddDivider()
	MenuGroup:AddLabel("Menu bind")
		:AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
	
	MenuGroup:AddButton({
		Text = "Unload",
		Func = function()
			UI.Library:Unload()
		end,
	})
	
	UI.Library.ToggleKeybind = UI.Options.MenuKeybind
	
	-- Save Manager & Theme Manager
	UI.ThemeManager:SetLibrary(UI.Library)
	UI.SaveManager:SetLibrary(UI.Library)
	
	UI.SaveManager:IgnoreThemeSettings()
	UI.SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
	
	UI.ThemeManager:SetFolder("UniversalScript")
	UI.SaveManager:SetFolder("UniversalScript")
	
	UI.SaveManager:BuildConfigSection(UI.Tabs["UI Settings"])
	UI.ThemeManager:ApplyToTab(UI.Tabs["UI Settings"])
	
	UI.SaveManager:LoadAutoloadConfig()
end

----------------------------------------------------------
-- 🔹 Setup Complete
function UI.setup()
	UI.loadLibraries()
	UI.createWindow()
	UI.createTabs()
	UI.createUISettingsTab()
	
	UI.Library:Notify({
		Title = "Universal Script",
		Description = "Loaded successfully!",
		Time = 5,
	})
end

----------------------------------------------------------
-- 🔹 Cleanup
function UI.cleanup()
	-- Cleanup sẽ được xử lý bởi Library:Unload()
	-- Các modules khác sẽ tự cleanup connections của mình
end

return UI

