--[[
    Misc Module - Universal Script
    Tab Misc - Anti AFK
]]

local Misc = {}
local Config = nil
local UI = nil

-- Variables
local antiAFKConnection = nil

----------------------------------------------------------
-- 🔹 Initialize
function Misc.init(config, ui)
	Config = config
	UI = ui
end

----------------------------------------------------------
-- 🔹 Create Tab
function Misc.createTab()
	local MiscGroup = UI.Tabs.Misc:AddLeftGroupbox("Misc", "settings")
	
	MiscGroup:AddToggle("AntiAFK", {
		Text = "Anti AFK",
		Default = false,
		Tooltip = "Prevent AFK kick",
	})
	
	-- Anti AFK
	UI.Toggles.AntiAFK:OnChanged(function()
		if UI.Toggles.AntiAFK.Value then
			if antiAFKConnection then
				antiAFKConnection:Disconnect()
			end
			antiAFKConnection = Config.RunService.Heartbeat:Connect(function()
				Config.VirtualUser:CaptureController()
				Config.VirtualUser:ClickButton2(Vector2.new())
			end)
		else
			if antiAFKConnection then
				antiAFKConnection:Disconnect()
				antiAFKConnection = nil
			end
		end
	end)
end

----------------------------------------------------------
-- 🔹 Cleanup
function Misc.cleanup()
	-- Disconnect Anti AFK
	if antiAFKConnection then
		antiAFKConnection:Disconnect()
		antiAFKConnection = nil
	end
end

return Misc

