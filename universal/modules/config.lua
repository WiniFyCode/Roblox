--[[
    Config Module - Universal Script
    Shared configuration, services, variables, and helper functions
]]

local Config = {}

----------------------------------------------------------
-- 🔹 Services
Config.Players = game:GetService("Players")
Config.UserInputService = game:GetService("UserInputService")
Config.RunService = game:GetService("RunService")
Config.Workspace = game:GetService("Workspace")
Config.Lighting = game:GetService("Lighting")
Config.ReplicatedStorage = game:GetService("ReplicatedStorage")
Config.TeleportService = game:GetService("TeleportService")
Config.HttpService = game:GetService("HttpService")
Config.VirtualUser = game:GetService("VirtualUser")
Config.CoreGui = game:GetService("CoreGui")

----------------------------------------------------------
-- 🔹 Game Objects
Config.LocalPlayer = Config.Players.LocalPlayer
Config.Camera = Config.Workspace.CurrentCamera
Config.EntityFolder = Config.Workspace:FindFirstChild("Entity")

----------------------------------------------------------
-- 🔹 Character Variables (Shared State)
Config.character = nil
Config.humanoid = nil
Config.rootPart = nil

----------------------------------------------------------
-- 🔹 Get Character Function
function Config.getCharacter()
	Config.character = Config.LocalPlayer.Character
	if Config.character then
		Config.humanoid = Config.character:FindFirstChildOfClass("Humanoid")
		Config.rootPart = Config.character:FindFirstChild("HumanoidRootPart")
	end
	return Config.character, Config.humanoid, Config.rootPart
end

----------------------------------------------------------
-- 🔹 Helper Function - Mouse Click
function Config.mouse1click()
	-- Simulate mouse click bằng cách fire các connections
	local mouse = Config.LocalPlayer:GetMouse()
	if mouse then
		-- Fire Button1Down event
		for _, connection in pairs(getconnections(mouse.Button1Down)) do
			pcall(function()
				connection:Fire()
			end)
		end
		-- Fire Button1Up event
		task.wait(0.01)
		for _, connection in pairs(getconnections(mouse.Button1Up)) do
			pcall(function()
				connection:Fire()
			end)
		end
	end
end

----------------------------------------------------------
-- 🔹 Character Added Connection
Config.LocalPlayer.CharacterAdded:Connect(function()
	Config.getCharacter()
end)

-- Initialize character
Config.getCharacter()

return Config

