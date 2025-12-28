--[[
    Server Module - Universal Script
    Tab Server - Server info, Server list
]]

local Server = {}
local Config = nil
local UI = nil

-- Variables
local serverList = {}
local serverListDisplay = {}
local serverDropdown = nil

----------------------------------------------------------
-- 🔹 Initialize
function Server.init(config, ui)
	Config = config
	UI = ui
end

----------------------------------------------------------
-- 🔹 Create Tab
function Server.createTab()
	local ServerInfoGroup = UI.Tabs.Server:AddLeftGroupbox("Server Information", "server")
	
	ServerInfoGroup:AddLabel("Current server info:")
	ServerInfoGroup:AddLabel("PlaceId: " .. tostring(game.PlaceId))
	ServerInfoGroup:AddLabel("JobId: " .. tostring(game.JobId))
	ServerInfoGroup:AddLabel("Players: " .. tostring(#Config.Players:GetPlayers()) .. "/" .. tostring(Config.Players.MaxPlayers or "?"))
	
	ServerInfoGroup:AddButton({
		Text = "Rejoin Server",
		Func = function()
			Config.TeleportService:Teleport(game.PlaceId, Config.LocalPlayer)
		end,
		Risky = true,
	})

	ServerInfoGroup:AddDivider()

	-- Auto Leave on Player Join
	local autoLeaveConnection = nil
	ServerInfoGroup:AddToggle("AutoLeaveOnJoin", {
		Text = "Auto Leave on Player Join",
		Tooltip = "Automatically leave game when another player joins",
		Default = false,
		Callback = function(Value)
			Config.autoLeaveOnJoinEnabled = Value
			
			if Value then
				-- Connect listener
				if autoLeaveConnection then
					autoLeaveConnection:Disconnect()
				end
				autoLeaveConnection = Config.Players.PlayerAdded:Connect(function(player)
					if Config.autoLeaveOnJoinEnabled and player ~= Config.LocalPlayer then
						UI.Library:Notify({
							Title = "Auto Leave",
							Description = "Player joined: " .. player.Name .. " - Leaving game...",
							Time = 2,
						})
						task.wait(0.5)
						Config.LocalPlayer:Kick("Auto Leave: Player joined")
					end
				end)
			else
				-- Disconnect listener
				if autoLeaveConnection then
					autoLeaveConnection:Disconnect()
					autoLeaveConnection = nil
				end
			end
			
			UI.Library:Notify({
				Title = "Server",
				Description = Value and "Auto Leave enabled" or "Auto Leave disabled",
				Time = 2,
			})
		end
	})
	
	local ServerListGroup = UI.Tabs.Server:AddRightGroupbox("Server List", "server")
	
	serverDropdown = ServerListGroup:AddDropdown("ServerList", {
		Values = {},
		Text = "Server List",
	})
	
	ServerListGroup:AddButton({
		Text = "Refresh server list",
		Func = function()
			local success, result = pcall(function()
				return Config.HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" ..
					game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
			end)
			
			if not success or not result or not result.data then
				UI.Library:Notify({
					Title = "Server",
					Description = "Failed to load server list",
					Time = 3,
				})
				return
			end
			
			serverList = {}
			serverListDisplay = {}
			
			for _, server in ipairs(result.data) do
				if server.id ~= game.JobId then
					local currentPlayers = server.playing or server.playerCount or 0
					local maxPlayers = server.maxPlayers or "?"
					local ping = server.ping or server.latency or "?"
					local fps = server.fps or "?"
					local shortId = typeof(server.id) == "string" and string.sub(server.id, 1, 6) or tostring(server.id)
					local display = string.format("%d/%s|ping: %s|fps: %s|%s", currentPlayers, maxPlayers, tostring(ping),
						tostring(fps), shortId)
					table.insert(serverList, server)
					table.insert(serverListDisplay, display)
				end
			end
			
			if #serverListDisplay == 0 then
				UI.Library:Notify({
					Title = "Server",
					Description = "No other servers found",
					Time = 3,
				})
			else
				UI.Library:Notify({
					Title = "Server",
					Description = "Refreshed " .. tostring(#serverListDisplay) .. " servers",
					Time = 3,
				})
			end
			
			serverDropdown:SetValues(serverListDisplay)
		end,
	})
	
	ServerListGroup:AddButton({
		Text = "Join Selected Server",
		Func = function()
			local selected = UI.Options.ServerList.Value
			
			if not selected or selected == "" then
				UI.Library:Notify({
					Title = "Server",
					Description = "You haven't selected any server",
					Time = 3,
				})
				return
			end
			
			local selectedIndex
			
			for i, display in ipairs(serverListDisplay) do
				if display == selected then
					selectedIndex = i
					break
				end
			end
			
			if not selectedIndex then
				UI.Library:Notify({
					Title = "Server",
					Description = "Selected server not found",
					Time = 3,
				})
				return
			end
			
			local serverData = serverList[selectedIndex]
			
			if serverData and serverData.id then
				Config.TeleportService:TeleportToPlaceInstance(game.PlaceId, serverData.id, Config.LocalPlayer)
			else
				UI.Library:Notify({
					Title = "Server",
					Description = "Invalid server data",
					Time = 3,
				})
			end
		end,
		Risky = true,
	})
	
	ServerListGroup:AddButton({
		Text = "Server Hop",
		Func = function()
			local servers = Config.HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" ..
			game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
			for _, server in pairs(servers.data) do
				if server.id ~= game.JobId then
					Config.TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, Config.LocalPlayer)
					break
				end
			end
		end,
		Risky = true,
	})
end

----------------------------------------------------------
-- 🔹 Cleanup
function Server.cleanup()
	-- No cleanup needed for Server module
	serverList = {}
	serverListDisplay = {}
end

return Server

