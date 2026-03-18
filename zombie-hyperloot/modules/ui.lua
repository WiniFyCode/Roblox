--[[
    UI Module - Zombie Hyperloot
    Obsidian UI setup + tất cả tabs
]]

local UI = {}
local Config, Combat, ESP, Movement, Map, Farm, HUD, Visuals, Character = nil, nil, nil, nil, nil, nil, nil, nil, nil

UI.Window = nil
UI.Library = nil
UI.SaveManager = nil
UI.ThemeManager = nil

function UI.init(config, combat, esp, movement, map, farm, hud, visuals, character)
    Config = config
    Combat = combat
    ESP = esp
    Movement = movement
    Map = map
    Farm = farm
    HUD = hud
    Visuals = visuals
    Character = character
end

function UI.loadLibraries()
    local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
    UI.Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
    UI.SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
    UI.ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
    
    -- Store Library reference in Config for notifications
    Config.UI.Library = UI.Library
    Config.UI.Fluent = UI.Library -- Keep for backward compatibility with notifications
    
    -- Store Toggles and Options for easy access
    UI.Toggles = UI.Library.Toggles
    UI.Options = UI.Library.Options
end


function UI.createWindow()
    UI.Library.ForceCheckbox = false
    UI.Library.ShowToggleFrameInKeybinds = true
    
    UI.Window = UI.Library:CreateWindow({
        Title = "Zombie Hyperloot",
        Footer = "by WiniFy | version: 2.0.0",
        NotifySide = "Right",
        ShowCustomCursor = true,
    })

    if UI.Library then
        UI.Library:Notify({
            Title = "Notice",
            Description = "I have stopped updating this script.",
            Time = 5,
        })
    end
end

----------------------------------------------------------
-- 🔹 Changelog Tab
function UI.createChangelogTab()
    local ChangelogTab = UI.Window:AddTab("Changelog", "scroll-text")
    
    local WarningGroup = ChangelogTab:AddLeftGroupbox("Important Warning", "warning")
    WarningGroup:AddLabel("⚠️ PLAY SOLO TO AVOID REPORTS ⚠️", true)

    local ChangelogGroup = ChangelogTab:AddLeftGroupbox("Version History", "history")
    
    -- Version 2.2.1 - Potion Toggle Feature
    ChangelogGroup:AddLabel("Version 2.2.1 - February 2, 2026", true)
    ChangelogGroup:AddLabel("• Added Potion Toggle: Buy + Drink vs Use from Inventory\n• Toggle between buying and using potions or using from inventory only\n• Updated all potion buttons (Common/Rare: Attack/Health/Luck) to respect toggle setting", true)
    ChangelogGroup:AddDivider()
    
    -- Version 2.2.0 - AFK Tab with Auto Draw Gift
    ChangelogGroup:AddLabel("Version 2.2.0 - February 2, 2026", true)
    ChangelogGroup:AddLabel("• Added AFK tab with Auto Draw Gift feature\n• Auto Draw Gift: Automatically draw gift every second\n• Toggle on/off functionality with notifications", true)
    ChangelogGroup:AddDivider()

    -- Version 2.1.0 - Loading Screen & Blacklist Update
    ChangelogGroup:AddLabel("Version 2.1.0 - January 23, 2026", true)
    ChangelogGroup:AddLabel("• Added Professional Loading Screen\n• Improved Module Loading System\n• Updated Blacklist System\n• Optimized Startup Performance", true)
    
    ChangelogGroup:AddDivider()

    -- Version 2.0.0 - Teleport System Overhaul
    ChangelogGroup:AddLabel("Version 2.0.0 - January 20, 2026", true)
    ChangelogGroup:AddLabel("• Major Teleport System Overhaul\n• Added Teleport Mode: Tween (Smooth) vs Instant (Fast)\n• Applied Teleport Mode to ALL teleports (Chest, Map Start, Supply, Task, Car, Camera Return)\n• Centralized Data management in Config\n• Added Task & Car teleport buttons in Supply ESP", true)
    
    ChangelogGroup:AddDivider()
    
    -- Version 1.9.9 - UNC Compatibility Fixes
    ChangelogGroup:AddLabel("Version 1.9.9 - January 19, 2026", true)
    ChangelogGroup:AddLabel("• Fixed UNC compatibility for Bunni executor\n• Fixed Gun Damage Dupe detection and hook setup\n• Fixed Noclip Cam compatibility\n• Improved executor function detection with dynamic re-checking", true)
    
    ChangelogGroup:AddDivider()
    
    -- Version 1.9.8 - UI Restructure & Chest Teleport Improvements
    ChangelogGroup:AddLabel("Version 1.9.8 - January 18, 2026", true)
    ChangelogGroup:AddLabel("• Restructured UI tabs for better usability\n• Merged Combat + ESP into \"Combat & ESP\" tab\n• Merged Movement + Map into \"Movement & Map\" tab\n• Merged Farm + Event into \"Farm & Event\" tab\n• Merged Visuals + HUD into \"Visuals & HUD\" tab\n• Separated Changelog into its own tab\n• Reduced from 12 tabs to 8 tabs for easier navigation\n• Added adjustable delay slider for chest teleport\n• Increased default chest teleport delay from 0.25s to 0.5s\n• Better control over teleport timing for improved stability", true)
    
    ChangelogGroup:AddDivider()
    
    -- Version 1.9.7 - Map & Server improvements
    ChangelogGroup:AddLabel("Version 1.9.7 - January 9, 2026", true)
    ChangelogGroup:AddLabel("• Add button Teleport to Main Game in Map tab", true)
    
    ChangelogGroup:AddDivider()
    
    -- Version 1.9.6 - Removed NoClip feature
    ChangelogGroup:AddLabel("Version 1.9.6 - January 8, 2026", true)
    ChangelogGroup:AddLabel("• Removed NoClip feature\n• Improved performance\n• Bug fixes and optimizations", true)
    
    ChangelogGroup:AddDivider()
    
    -- Version 1.0.0
    ChangelogGroup:AddLabel("Version 1.0.0 - October 23, 2025", true)
    ChangelogGroup:AddLabel("• Aimbot with FOV circle\n• ESP for Zombies, Players, Chests\n• Auto Farm features\n• Camera Teleport\n• Speed boost\n• Auto Skills for all characters\n• Map selection\n• And much more!", true)
    
    local InfoGroup = ChangelogTab:AddRightGroupbox("Information", "info")

    InfoGroup:AddLabel("Script: Zombie Hyperloot\nAuthor: WiniFy", true)
    InfoGroup:AddLabel("I have stopped updating this script.", true)
end

----------------------------------------------------------
-- 🔹 Server Tab
function UI.createServerTab()
    local ServerTab = UI.Window:AddTab("Server", "server")
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")

    local ServerInfoGroup = ServerTab:AddLeftGroupbox("Server Information", "server")
    ServerInfoGroup:AddLabel("Current server info:")
    ServerInfoGroup:AddLabel("PlaceId: " .. tostring(game.PlaceId))
    ServerInfoGroup:AddLabel("JobId: " .. tostring(game.JobId))
    ServerInfoGroup:AddLabel("Players: " .. tostring(#Config.Players:GetPlayers()) .. "/" .. tostring(Config.Players.MaxPlayers or "?"))

    ServerInfoGroup:AddButton({
        Text = "Rejoin Server",
        Func = function()
            TeleportService:Teleport(game.PlaceId, Config.localPlayer)
        end,
        Risky = true,
    })

    ServerInfoGroup:AddDivider()

    -- Auto Leave on Player Join
    local autoLeaveConnection = nil
    ServerInfoGroup:AddToggle("AutoLeaveOnJoin", {
        Text = "Auto Leave on Player Join",
        Tooltip = "Automatically leave game when another player joins",
        Default = Config.autoLeaveOnJoinEnabled,
        Callback = function(Value)
            Config.autoLeaveOnJoinEnabled = Value
            
            if Value then
                -- Connect listener
                if autoLeaveConnection then
                    autoLeaveConnection:Disconnect()
                end
                autoLeaveConnection = Config.Players.PlayerAdded:Connect(function(player)
                    if Config.autoLeaveOnJoinEnabled and player ~= Config.localPlayer then
                        if UI.Library then
                            UI.Library:Notify({
                                Title = "Auto Leave",
                                Description = "Player joined: " .. player.Name .. " - Leaving game...",
                                Time = 2,
                            })
                        end
                        task.wait(0.5)
                        Config.localPlayer:Kick("Auto Leave: Player joined")
                    end
                end)
            else
                -- Disconnect listener
                if autoLeaveConnection then
                    autoLeaveConnection:Disconnect()
                    autoLeaveConnection = nil
                end
            end
            
            if UI.Library then
                UI.Library:Notify({
                    Title = "Server",
                    Description = Value and "Auto Leave enabled" or "Auto Leave disabled",
                    Time = 2,
                })
            end
        end
    })

    ServerInfoGroup:AddDivider()

    -- Auto Leave on Player Nearby
    local autoLeaveNearbyEnabled = false
    local autoLeaveNearbyDistance = 200
    local autoLeaveNearbyConnection = nil
    local autoLeaveNearbyTriggered = false

    ServerInfoGroup:AddToggle("AutoLeaveOnNearby", {
        Text = "Auto Leave on Player Nearby",
        Tooltip = "Automatically leave game when another player is within range",
        Default = false,
        Callback = function(Value)
            autoLeaveNearbyEnabled = Value
            autoLeaveNearbyTriggered = false
            
            if Value then
                -- Start checking loop
                if autoLeaveNearbyConnection then
                    autoLeaveNearbyConnection:Disconnect()
                end
                autoLeaveNearbyConnection = Config.RunService.Heartbeat:Connect(function()
                    if not autoLeaveNearbyEnabled or autoLeaveNearbyTriggered then return end
                    
                    local localChar = Config.localPlayer and Config.localPlayer.Character
                    local localHRP = localChar and localChar:FindFirstChild("HumanoidRootPart")
                    if not localHRP then return end
                    
                    for _, player in ipairs(Config.Players:GetPlayers()) do
                        if player ~= Config.localPlayer then
                            local char = player.Character
                            local hrp = char and char:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                local distance = (localHRP.Position - hrp.Position).Magnitude
                                if distance <= autoLeaveNearbyDistance then
                                    autoLeaveNearbyTriggered = true
                                    if UI.Library then
                                        UI.Library:Notify({
                                            Title = "Auto Leave",
                                            Description = player.Name .. " is " .. math.floor(distance) .. " studs away - Leaving game...",
                                            Time = 2,
                                        })
                                    end
                                    task.wait(0.5)
                                    Config.localPlayer:Kick("Auto Leave: Player nearby (" .. player.Name .. ")")
                                    return
                                end
                            end
                        end
                    end
                end)
            else
                -- Disconnect loop
                if autoLeaveNearbyConnection then
                    autoLeaveNearbyConnection:Disconnect()
                    autoLeaveNearbyConnection = nil
                end
            end
            
            if UI.Library then
                UI.Library:Notify({
                    Title = "Server",
                    Description = Value and "Auto Leave Nearby enabled" or "Auto Leave Nearby disabled",
                    Time = 2,
                })
            end
        end
    })

    ServerInfoGroup:AddSlider("AutoLeaveNearbyDistance", {
        Text = "Leave Distance (studs)",
        Default = 200,
        Min = 100,
        Max = 500,
        Rounding = 0,
        Callback = function(Value)
            autoLeaveNearbyDistance = Value
        end
    })

    local ServerListGroup = ServerTab:AddRightGroupbox("Server List", "server")
    local serverList = {}
    local serverListDisplay = {}
    local serverDropdown = ServerListGroup:AddDropdown("ZHServerList", {
        Values = {},
        Text = "Server List",
    })

    ServerListGroup:AddButton({
        Text = "Refresh server list",
        Func = function()
            local success, result = pcall(function()
                return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" ..
                    game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
            end)

            if not success or not result or not result.data then
                if UI.Library then
                    UI.Library:Notify({
                        Title = "Server",
                        Description = "Failed to load server list",
                        Time = 3,
                    })
                end
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
                    local display = string.format("%d/%s|ping: %s|fps: %s|%s", currentPlayers, maxPlayers, tostring(ping), tostring(fps), shortId)
                    table.insert(serverList, server)
                    table.insert(serverListDisplay, display)
                end
            end

            if #serverListDisplay == 0 then
                if UI.Library then
                    UI.Library:Notify({
                        Title = "Server",
                        Description = "No other servers found",
                        Time = 3,
                    })
                end
            else
                if UI.Library then
                    UI.Library:Notify({
                        Title = "Server",
                        Description = "Refreshed " .. tostring(#serverListDisplay) .. " servers",
                        Time = 3,
                    })
                end
            end

            if serverDropdown and serverDropdown.SetValues then
                serverDropdown:SetValues(serverListDisplay)
            end
        end,
    })

    ServerListGroup:AddButton({
        Text = "Join Selected Server",
        Func = function()
            local Options = UI.Library and UI.Library.Options
            if not Options or not Options.ZHServerList then
                if UI.Library then
                    UI.Library:Notify({
                        Title = "Server",
                        Description = "You haven't selected any server",
                        Time = 3,
                    })
                end
                return
            end

            local selected = Options.ZHServerList.Value
            if not selected or selected == "" then
                if UI.Library then
                    UI.Library:Notify({
                        Title = "Server",
                        Description = "You haven't selected any server",
                        Time = 3,
                    })
                end
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
                if UI.Library then
                    UI.Library:Notify({
                        Title = "Server",
                        Description = "Selected server not found",
                        Time = 3,
                    })
                end
                return
            end

            local serverData = serverList[selectedIndex]
            if serverData and serverData.id then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, serverData.id, Config.localPlayer)
            else
                if UI.Library then
                    UI.Library:Notify({
                        Title = "Server",
                        Description = "Invalid server data",
                        Time = 3,
                    })
                end
            end
        end,
        Risky = true,
    })

    ServerListGroup:AddButton({
        Text = "Server Hop",
        Func = function()
            local success, servers = pcall(function()
                return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" ..
                    game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
            end)

            if not success or not servers or not servers.data then
                if UI.Library then
                    UI.Library:Notify({
                        Title = "Server",
                        Description = "Failed to load server list",
                        Time = 3,
                    })
                end
                return
            end

            for _, server in pairs(servers.data) do
                if server.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, Config.localPlayer)
                    break
                end
            end
        end,
        Risky = true,
    })

    return ServerTab
end

----------------------------------------------------------
-- 🔹 Combat & ESP Tab (Merged)
function UI.createCombatESPTab()
    local CombatESPTab = UI.Window:AddTab("Combat & ESP", "sword")
    
    -- Left Groupbox: Combat
    local CombatLeftGroup = CombatESPTab:AddLeftGroupbox("Combat")

    CombatLeftGroup:AddToggle("Aimbot", {
        Text = "Aimbot",
        Default = Config.aimbotEnabled,
        Callback = function(Value)
            Config.aimbotEnabled = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "Aimbot",
                    Description = Value and "Aimbot enabled" or "Aimbot disabled",
                    Time = 2
                })
            end
        end
    })

    CombatLeftGroup:AddDivider()

    CombatLeftGroup:AddDropdown("AimbotTargetMode", {
        Text = "Target Type",
        Values = {"Zombies", "Players", "All"},
        Default = Config.aimbotTargetMode,
        Callback = function(Value)
            Config.aimbotTargetMode = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "Aimbot",
                    Description = "Target Type: " .. Value,
                    Time = 2
                })
            end
        end
    })

    CombatLeftGroup:AddDropdown("AimbotPriorityMode", {
        Text = "Priority",
        Values = {"Nearest", "Farthest", "LowestHealth", "HighestHealth"},
        Default = Config.aimbotPriorityMode,
        Callback = function(Value)
            Config.aimbotPriorityMode = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "Aimbot",
                    Description = "Priority: " .. Value,
                    Time = 2
                })
            end
        end
    })

    CombatLeftGroup:AddDropdown("AimbotAimPart", {
        Text = "Aim Part",
        Values = {"Head", "UpperTorso", "HumanoidRootPart", "Random"},
        Default = Config.aimbotAimPart,
        Callback = function(Value)
            Config.aimbotAimPart = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "Aimbot",
                    Description = "Aim Part: " .. Value,
                    Time = 2
                })
            end
        end
    })

    CombatLeftGroup:AddToggle("AimbotHoldMouse2", {
        Text = "Hold Right Click",
        Default = Config.aimbotHoldMouse2,
        Callback = function(Value)
            Config.aimbotHoldMouse2 = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "Aimbot",
                    Description = Value and "Hold Right Click enabled" or "Hold Right Click disabled",
                    Time = 2
                })
            end
        end
    })

    CombatLeftGroup:AddToggle("AimbotAutoFire", {
        Text = "Auto Fire (Mouse1)",
        Default = Config.aimbotAutoFireEnabled,
        Callback = function(Value)
            Config.aimbotAutoFireEnabled = Value
            if not Value and Combat.setAutoFireActive then
                Combat.setAutoFireActive(false)
            end
            if UI.Library then
                UI.Library:Notify({
                    Title = "Aimbot",
                    Description = Value and "Auto Fire enabled" or "Auto Fire disabled",
                    Time = 2
                })
            end
        end
    })

    CombatLeftGroup:AddToggle("AimbotFOV", {
        Text = "FOV Circle",
        Default = Config.aimbotFOVEnabled,
        Callback = function(Value)
            Config.aimbotFOVEnabled = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "Aimbot",
                    Description = Value and "FOV Circle enabled" or "FOV Circle disabled",
                    Time = 2
                })
            end
        end
    })

    CombatLeftGroup:AddSlider("AimbotFOVRadius", {
        Text = "FOV Radius",
        Default = Config.aimbotFOVRadius,
        Min = 50, Max = 500, Rounding = 0,
        Callback = function(Value) Config.aimbotFOVRadius = Value end
    })

    CombatLeftGroup:AddToggle("AimbotWallCheck", {
        Text = "Wall Check (Decoration)",
        Default = Config.aimbotWallCheckEnabled,
        Callback = function(Value)
            Config.aimbotWallCheckEnabled = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "Aimbot",
                    Description = Value and "Wall Check enabled" or "Wall Check disabled",
                    Time = 2
                })
            end
        end
    })

    CombatLeftGroup:AddSlider("AimbotSmoothness", {
        Text = "Smoothness",
        Tooltip = "0 = Instant Lock | Higher = Smoother/Slower",
        Default = Config.aimbotSmoothness,
        Min = 0, Max = 0.9, Rounding = 2,
        Callback = function(Value) Config.aimbotSmoothness = Value end
    })

    CombatLeftGroup:AddSlider("AimbotPrediction", {
        Text = "Prediction",
        Default = Config.aimbotPrediction,
        Min = 0, Max = 0.2, Rounding = 3,
        Callback = function(Value) Config.aimbotPrediction = Value end
    })

    CombatLeftGroup:AddDivider()

    CombatLeftGroup:AddToggle("Hitbox", {
        Text = "Hitbox Expander",
        Default = Config.hitboxEnabled,
        Callback = function(Value)
            Config.hitboxEnabled = Value
            Combat.updateAllHitboxes(Value)
            if UI.Library then
                UI.Library:Notify({
                    Title = "Hitbox",
                    Description = Value and "Hitbox Expander enabled" or "Hitbox Expander disabled",
                    Time = 2
                })
            end
        end
    })

    CombatLeftGroup:AddToggle("FiringRangePriority", {
        Text = "Target Dummies",
        Tooltip = "Enable: auto skill prioritizes dummies in Map.FiringRange",
        Default = Config.firingRangePriorityEnabled,
        Callback = function(Value)
            Config.firingRangePriorityEnabled = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "FiringRange",
                    Description = Value and "FiringRange (dummy) priority enabled" or "FiringRange priority disabled",
                    Time = 2
                })
            end
        end
    })

    CombatLeftGroup:AddSlider("HitboxSize", {
        Text = "Hitbox Size",
        Default = 4, Min = 1, Max = 20, Rounding = 1,
        Callback = function(Value)
            Config.hitboxSize = Vector3.new(Value, Value, Value)
        end
    })

    CombatLeftGroup:AddDivider()

    CombatLeftGroup:AddToggle("TrigerSkillDupeEnabled", {
        Text = "Enable Gun Damage Dupe",
        Default = Config.trigerSkillDupeEnabled,
        Callback = function(Value)
            Config.trigerSkillDupeEnabled = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "Gun Damage Dupe",
                    Description = Value and "Gun Damage Dupe enabled" or "Gun Damage Dupe disabled",
                    Time = 2
                })
            end
        end
    })

    CombatLeftGroup:AddSlider("TrigerSkillDupeCount", {
        Text = "Dupe Count",
        Default = Config.trigerSkillDupeCount,
        Min = 1, Max = 20, Rounding = 0,
        Callback = function(Value) Config.trigerSkillDupeCount = Value end
    })

    CombatLeftGroup:AddDivider()

    CombatLeftGroup:AddToggle("AutoRotate", {
        Text = "Aimbot 360°",
        Tooltip = "Enable feature, then press L in-game to toggle",
        Default = Config.autoRotateEnabled,
        Callback = function(Value)
            Config.autoRotateEnabled = Value

            -- Nếu tắt toggle trong menu thì tắt hẳn auto rotate
            if not Value then
                Config.autoRotateActive = false
                Combat.toggleAutoRotate(false)
            end

            if UI.Library then
                UI.Library:Notify({
                    Title = "Auto Rotate",
                    Description = Value and "Aimbot 360° enabled" or "Aimbot 360° disabled",
                    Time = 2
                })
            end
        end
    })

    CombatLeftGroup:AddSlider("AutoRotateSmoothness", {
        Text = "Rotation Smoothness",
        Tooltip = "0 = Instant Lock | Higher = Smoother/Slower",
        Default = Config.autoRotateSmoothness,
        Min = 0, Max = 0.9, Rounding = 2,
        Callback = function(Value)
            Config.autoRotateSmoothness = Value
            Combat.setRotationSmoothness(Value)
        end
    })

    -- Right Groupbox: ESP
    local ESPRightGroup = CombatESPTab:AddRightGroupbox("ESP")

    ESPRightGroup:AddDivider()
    ESPRightGroup:AddLabel("Zombie ESP")

    ESPRightGroup:AddToggle("ESPZombie", {
        Text = "ESP Zombie",
        Default = Config.espZombieEnabled,
        Callback = function(Value)
            Config.espZombieEnabled = Value
            if not Value then
                ESP.clearZombieESP()
                for _, data in pairs(ESP.zombieESPObjects) do
                    ESP.hideZombieESP(data)
                end
            end
            if UI.Library then
                UI.Library:Notify({
                    Title = "ESP",
                    Description = Value and "Zombie ESP enabled" or "Zombie ESP disabled",
                    Time = 2
                })
            end
        end
    })

    ESPRightGroup:AddLabel("Zombie ESP Color"):AddColorPicker("ESPZombieColor", {
        Default = Config.espColorZombie,
        Title = "Zombie ESP Color",
        Callback = function(Value) Config.espColorZombie = Value end
    })

    ESPRightGroup:AddToggle("ESPZombieBoxes", {
        Text = "Zombie Boxes",
        Default = Config.espZombieBoxes,
        Callback = function(Value)
            Config.espZombieBoxes = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "ESP",
                    Description = Value and "Zombie Boxes enabled" or "Zombie Boxes disabled",
                    Time = 2
                })
            end
        end
    })

    ESPRightGroup:AddToggle("ESPZombieTracers", {
        Text = "Zombie Tracers",
        Default = Config.espZombieTracers,
        Callback = function(Value)
            Config.espZombieTracers = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "ESP",
                    Description = Value and "Zombie Tracers enabled" or "Zombie Tracers disabled",
                    Time = 2
                })
            end
        end
    })

    ESPRightGroup:AddToggle("ESPZombieNames", {
        Text = "Zombie Names",
        Default = Config.espZombieNames,
        Callback = function(Value)
            Config.espZombieNames = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "ESP",
                    Description = Value and "Zombie Names enabled" or "Zombie Names disabled",
                    Time = 2
                })
            end
        end
    })

    ESPRightGroup:AddToggle("ESPZombieHealth", {
        Text = "Zombie Health Bars",
        Default = Config.espZombieHealth,
        Callback = function(Value)
            Config.espZombieHealth = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "ESP",
                    Description = Value and "Zombie Health Bars enabled" or "Zombie Health Bars disabled",
                    Time = 2
                })
            end
        end
    })

    ESPRightGroup:AddToggle("ESPZombieHighlight", {
        Text = "Zombie Highlight",
        Default = Config.espZombieHighlight,
        Callback = function(Value)
            Config.espZombieHighlight = Value
            if not Value then
                for zombie, highlight in pairs(ESP.zombieHighlights) do
                    ESP.removeZombieHighlight(zombie)
                end
            end
            if UI.Library then
                UI.Library:Notify({
                    Title = "ESP",
                    Description = Value and "Zombie Highlight enabled" or "Zombie Highlight disabled",
                    Time = 2
                })
            end
        end
    })

    ESPRightGroup:AddDivider()
    ESPRightGroup:AddLabel("Chest ESP")

    ESPRightGroup:AddToggle("ESPChest", {
        Text = "ESP Chest",
        Default = Config.espChestEnabled,
        Callback = function(Value)
            Config.espChestEnabled = Value
            if Value then ESP.applyChestESP() else ESP.clearChestESP() end
            if UI.Library then
                UI.Library:Notify({
                    Title = "ESP",
                    Description = Value and "Chest ESP enabled" or "Chest ESP disabled",
                    Time = 2
                })
            end
        end
    })

    ESPRightGroup:AddLabel("Chest ESP Color"):AddColorPicker("ESPChestColor", {
        Default = Config.espColorChest,
        Title = "Chest ESP Color",
        Callback = function(Value)
            Config.espColorChest = Value
            ESP.refreshChestHighlights(Value)
        end
    })

    ESPRightGroup:AddDivider()
    ESPRightGroup:AddLabel("Player ESP")

    ESPRightGroup:AddToggle("ESPPlayer", {
        Text = "ESP Player",
        Default = Config.espPlayerEnabled,
        Callback = function(Value)
            Config.espPlayerEnabled = Value
            if not Value then
                for _, data in pairs(ESP.playerESPObjects) do
                    ESP.hidePlayerESP(data)
                end
            end
            if UI.Library then
                UI.Library:Notify({
                    Title = "ESP",
                    Description = Value and "Player ESP enabled" or "Player ESP disabled",
                    Time = 2
                })
            end
        end
    })

    ESPRightGroup:AddLabel("Player ESP Color"):AddColorPicker("ESPPlayerColor", {
        Default = Config.espColorPlayer,
        Title = "Player ESP Color",
        Callback = function(Value) Config.espColorPlayer = Value end
    })

    ESPRightGroup:AddLabel("Enemy ESP Color"):AddColorPicker("ESPEnemyColor", {
        Default = Config.espColorEnemy,
        Title = "Enemy ESP Color",
        Callback = function(Value) Config.espColorEnemy = Value end
    })

    ESPRightGroup:AddToggle("ESPPlayerBoxes", {
        Text = "Player Boxes",
        Default = Config.espPlayerBoxes,
        Callback = function(Value) Config.espPlayerBoxes = Value end
    })

    ESPRightGroup:AddToggle("ESPPlayerTracers", {
        Text = "Player Tracers",
        Default = Config.espPlayerTracers,
        Callback = function(Value)
            Config.espPlayerTracers = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "ESP",
                    Description = Value and "Player Tracers enabled" or "Player Tracers disabled",
                    Time = 2
                })
            end
        end
    })

    ESPRightGroup:AddToggle("ESPPlayerNames", {
        Text = "Player Names",
        Default = Config.espPlayerNames,
        Callback = function(Value)
            Config.espPlayerNames = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "ESP",
                    Description = Value and "Player Names enabled" or "Player Names disabled",
                    Time = 2
                })
            end
        end
    })

    ESPRightGroup:AddToggle("ESPPlayerHealth", {
        Text = "Player Health Bars",
        Default = Config.espPlayerHealth,
        Callback = function(Value)
            Config.espPlayerHealth = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "ESP",
                    Description = Value and "Player Health Bars enabled" or "Player Health Bars disabled",
                    Time = 2
                })
            end
        end
    })

    ESPRightGroup:AddToggle("ESPPlayerTeamCheck", {
        Text = "Team Check",
        Default = Config.espPlayerTeamCheck,
        Callback = function(Value)
            Config.espPlayerTeamCheck = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "ESP",
                    Description = Value and "Team Check enabled" or "Team Check disabled",
                    Time = 2
                })
            end
        end
    })

    ESPRightGroup:AddToggle("ESPPlayerHighlight", {
        Text = "Player Highlight",
        Default = Config.espPlayerHighlight,
        Callback = function(Value)
            Config.espPlayerHighlight = Value
            if not Value then
                for player, highlight in pairs(ESP.playerHighlights) do
                    ESP.removePlayerHighlight(player)
                end
            end
            if UI.Library then
                UI.Library:Notify({
                    Title = "ESP",
                    Description = Value and "Player Highlight enabled" or "Player Highlight disabled",
                    Time = 2
                })
            end
        end
    })

    return CombatESPTab
end

----------------------------------------------------------
-- 🔹 Movement & Map Tab (Merged)
function UI.createMovementMapTab()
    local MovementMapTab = UI.Window:AddTab("Movement & Map", "move")
    
    -- Left Groupbox: Movement
    local MovementLeftGroup = MovementMapTab:AddLeftGroupbox("Movement")

    MovementLeftGroup:AddToggle("Speed", {
        Text = "Speed Boost",
        Default = Config.speedEnabled,
        Callback = function(Value)
            Config.speedEnabled = Value
            Movement.applySpeed()
            if UI.Library then
                UI.Library:Notify({
                    Title = "Movement",
                    Description = Value and "Speed Boost enabled" or "Speed Boost disabled",
                    Time = 2
                })
            end
        end
    })

    MovementLeftGroup:AddSlider("SpeedValue", {
        Text = "Speed Bonus",
        Default = Config.speedValue,
        Min = 1, Max = 100, Rounding = 1,
        Callback = function(Value)
            Config.speedValue = Value
            if Config.speedEnabled then Movement.applySpeed() end
        end
    })

    MovementLeftGroup:AddToggle("AntiAFK", {
        Text = "Anti AFK",
        Tooltip = "Prevents being kicked for inactivity",
        Default = Config.antiAFKEnabled,
        Callback = function(Value)
            Config.antiAFKEnabled = Value
            Movement.applyAntiAFK()
            if UI.Library then
                UI.Library:Notify({
                    Title = "Movement",
                    Description = Value and "Anti AFK enabled" or "Anti AFK disabled",
                    Time = 2
                })
            end
        end
    })

    MovementLeftGroup:AddToggle("HipHeight", {
        Text = "Hip Height (Fly)",
        Default = Config.hipHeightEnabled,
        Callback = function(Value)
            Config.hipHeightEnabled = Value
            Movement.applyHipHeight()
            if UI.Library then
                UI.Library:Notify({
                    Title = "Movement",
                    Description = Value and "Hip Height enabled" or "Hip Height disabled",
                    Time = 2
                })
            end
        end
    })

    MovementLeftGroup:AddSlider("HipHeightValue", {
        Text = "Hip Height",
        Default = Config.hipHeight,
        Min = 0, Max = 50, Rounding = 1,
        Callback = function(Value)
            Config.hipHeight = Value
            if Movement and Config.hipHeightEnabled then
                Movement.setHipHeight(Value)
            end
        end
    })

    MovementLeftGroup:AddDivider()
    MovementLeftGroup:AddLabel("Camera Teleport")

    MovementLeftGroup:AddToggle("CameraTeleport", {
        Text = "Camera Teleport (X)",
        Default = Config.cameraTeleportEnabled,
        Callback = function(Value)
            Config.cameraTeleportEnabled = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "Camera Teleport",
                    Description = Value and "Camera Teleport enabled" or "Camera Teleport disabled",
                    Time = 2
                })
            end
        end
    })

    MovementLeftGroup:AddDropdown("CameraTargetMode", {
        Text = "Target Mode",
        Values = {"LowestHealth", "Nearest"},
        Default = Config.cameraTargetMode,
        Callback = function(Value)
            Config.cameraTargetMode = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "Camera Teleport",
                    Description = "Target Mode: " .. Value,
                    Time = 2
                })
            end
        end
    })

    MovementLeftGroup:AddSlider("CameraTeleportWaveDelay", {
        Text = "Wave Wait Time (s)",
        Default = Config.cameraTeleportWaveDelay,
        Min = 0, Max = 15, Rounding = 0,
        Callback = function(Value) Config.cameraTeleportWaveDelay = Value end
    })

    MovementLeftGroup:AddToggle("TeleportToLastZombie", {
        Text = "Teleport to Last Zombie",
        Default = Config.teleportToLastZombie,
        Callback = function(Value)
            Config.teleportToLastZombie = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "Camera Teleport",
                    Description = Value and "Teleport to Last Zombie enabled" or "Teleport to Last Zombie disabled",
                    Time = 2
                })
            end
        end
    })

    MovementLeftGroup:AddDivider()
    MovementLeftGroup:AddLabel("Camera Offset")

    MovementLeftGroup:AddSlider("CameraOffsetX", {
        Text = "Camera Offset X",
        Default = Config.cameraOffsetX,
        Min = -360, Max = 360, Rounding = 1,
        Callback = function(Value) Config.cameraOffsetX = Value end
    })

    MovementLeftGroup:AddSlider("CameraOffsetY", {
        Text = "Camera Offset Y",
        Default = Config.cameraOffsetY,
        Min = -360, Max = 360, Rounding = 1,
        Callback = function(Value) Config.cameraOffsetY = Value end
    })

    MovementLeftGroup:AddSlider("CameraOffsetZ", {
        Text = "Camera Offset Z",
        Default = Config.cameraOffsetZ,
        Min = -360, Max = 360, Rounding = 1,
        Callback = function(Value) Config.cameraOffsetZ = Value end
    })

    -- Right Groupbox: Map
    local MapRightGroup = MovementMapTab:AddRightGroupbox("Map")

    MapRightGroup:AddDivider()

    local mapDisplayNames = {
        "Exclusion [1001]",
        "Virus Laboratory [1002]",
        "Biology Laboratory [1003]",
        "The Backrooms [1004]",
        "Wave Mode [102]",
        "Raid Mode [201]",
    }

    local mapIdByDisplay = {
        ["Exclusion [1001]"] = 1001,
        ["Virus Laboratory [1002]"] = 1002,
        ["Biology Laboratory [1003]"] = 1003,
        ["The Backrooms [1004]"] = 1004,
        ["Wave Mode [102]"] = 102,
        ["Raid Mode [201]"] = 201,
    }

    MapRightGroup:AddDropdown("MapWorld", {
        Text = "Map",
        Values = mapDisplayNames,
        Default = mapDisplayNames[1],
        Callback = function(Value)
            local id = mapIdByDisplay[Value]
            if id then Config.selectedWorldId = id end
        end
    })

    MapRightGroup:AddDropdown("MapDifficulty", {
        Text = "Difficulty",
        Values = {"1 - Normal", "2 - Hard", "3 - Nightmare"},
        Default = "1 - Normal",
        Callback = function(Value)
            local num = tonumber(string.match(Value, "^(%d+)"))
            if num then Config.selectedDifficulty = num end
        end
    })

    MapRightGroup:AddSlider("MapMaxCount", {
        Text = "Max Players",
        Default = Config.selectedMaxCount,
        Min = 1, Max = 4, Rounding = 0,
        Callback = function(Value) Config.selectedMaxCount = Value end
    })

    MapRightGroup:AddToggle("MapFriendOnly", {
        Text = "Friend Only",
        Default = Config.selectedFriendOnly,
        Callback = function(Value) Config.selectedFriendOnly = Value end
    })

    MapRightGroup:AddButton({
        Text = "Teleport & Start Map",
        Func = function()
            Map.teleportToWaitAreaAndStart()
            if UI.Library then
                local mapName = "Unknown"
                for display, id in pairs(mapIdByDisplay) do
                    if id == Config.selectedWorldId then
                        mapName = display
                        break
                    end
                end
                UI.Library:Notify({
                    Title = "Map Teleport",
                    Description = "Teleporting to " .. mapName .. "...",
                    Time = 3
                })
            end
        end
    })

    MapRightGroup:AddButton({
        Text = "Replay Match",
        Tooltip = "Replay the current match",
        Func = function()
            Map.replayCurrentMatch()
            if UI.Library then
                UI.Library:Notify({
                    Title = "Replay",
                    Description = "Replay request sent!",
                    Time = 2
                })
            end
        end
    })

    MapRightGroup:AddButton({
        Text = "Teleport to Main Game",
        Tooltip = "Teleport to the main game",
        Func = function()
            Map.teleportToMainGame()
            if UI.Library then
                UI.Library:Notify({
                    Title = "Map",
                    Description = "Teleporting to main game...",
                    Time = 3
                })
            end
        end
    })

    MapRightGroup:AddDivider()

    MapRightGroup:AddToggle("SupplyESP", {
        Text = "Supply ESP (Right Side)",
        Tooltip = "Display all Supply items on the right side of the screen",
        Default = Config.supplyESPEnabled,
        Callback = function(Value)
            Config.supplyESPEnabled = Value
            if Value then
                Map.startSupplyESP()
            else
                Map.stopSupplyESP()
            end
            if UI.Library then
                UI.Library:Notify({
                    Title = "Supply ESP",
                    Description = Value and "Supply ESP enabled" or "Supply ESP disabled",
                    Time = 2
                })
            end
        end
    })

    MapRightGroup:AddDropdown("SupplyESPPosition", {
        Text = "Supply Position",
        Values = {"Left", "Right"},
        Default = Config.supplyESPPosition,
        Callback = function(Value)
            Config.supplyESPPosition = Value
            Map.updateSupplyPosition()
        end
    })

    MapRightGroup:AddButton({
        Text = "Refresh Supply List",
        Tooltip = "Find all Supply items instantly",
        Func = function()
            if Config.supplyESPEnabled then
                Map.updateSupplyDisplay()
                if UI.Library then
                    local supplyCount = #Map.supplyItems
                    UI.Library:Notify({
                        Title = "Supply ESP",
                        Description = "Found " .. supplyCount .. " supply item(s)",
                        Time = 2
                    })
                end
            else
                if UI.Library then
                    UI.Library:Notify({
                        Title = "Supply ESP",
                        Description = "Please enable Supply ESP first",
                        Time = 2
                    })
                end
            end
        end
    })

    MapRightGroup:AddDivider()

    MapRightGroup:AddToggle("AutoDoor", {
        Text = "Auto Open Door",
        Tooltip = "Automatically open doors when available (check every 5s)",
        Default = Config.autoDoorEnabled,
        Callback = function(Value)
            Config.autoDoorEnabled = Value
            Map.toggleAutoDoor(Value)
            if UI.Library then
                UI.Library:Notify({
                    Title = "Map",
                    Description = Value and "Auto Open Door enabled" or "Auto Open Door disabled",
                    Time = 2
                })
            end
        end
    })

    return MovementMapTab
end

----------------------------------------------------------
-- 🔹 Farm & Event Tab (Merged)
function UI.createFarmEventTab()
    local FarmEventTab = UI.Window:AddTab("Farm & Event", "package")
    
    -- Left Groupbox: Farm
    local FarmLeftGroup = FarmEventTab:AddLeftGroupbox("Farm")

    FarmLeftGroup:AddDropdown("TeleportMode", {
        Values = {"Tween", "Instant"},
        Default = Config.teleportMode or "Tween",
        Multi = false,
        Text = "Teleport Mode",
        Tooltip = "Select teleport mode (Tween: Smooth, Instant: Fast)",
        Callback = function(Value)
            Config.teleportMode = Value
        end
    })

    FarmLeftGroup:AddSlider("TeleportTweenSpeed", {
        Text = "Tween Speed (s)",
        Default = Config.teleportTweenSpeed or 1,
        Min = 0.5, Max = 5, Rounding = 1,
        Callback = function(Value)
            Config.teleportTweenSpeed = Value
        end
    })

    FarmLeftGroup:AddSlider("ChestTeleportDelay", {
        Text = "Chest Teleport Delay (s)",
        Tooltip = "Delay time between chests when teleporting",
        Default = Config.chestTeleportDelay or 0.5,
        Min = 0.5, Max = 2.0, Rounding = 1,
        Callback = function(Value)
            Config.chestTeleportDelay = Value
        end
    })

    FarmLeftGroup:AddDivider()

    FarmLeftGroup:AddToggle("AutoBulletBox", {
        Text = "Auto BulletBox + Items",
        Default = Config.autoBulletBoxEnabled,
        Callback = function(Value)
            Config.autoBulletBoxEnabled = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "Farm",
                    Description = Value and "Auto BulletBox enabled" or "Auto BulletBox disabled",
                    Time = 2
                })
            end
        end
    })

    FarmLeftGroup:AddToggle("Teleport", {
        Text = "Auto Chest (T Key)",
        Default = Config.teleportEnabled,
        Callback = function(Value)
            Config.teleportEnabled = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "Farm",
                    Description = Value and "Auto Chest enabled" or "Auto Chest disabled",
                    Time = 2
                })
            end
        end
    })

    FarmLeftGroup:AddButton({
        Text = "Teleport to All Chests",
        Func = function()
            if Farm and Farm.teleportToAllChests then
                print("[Farm] Teleporting to all chests...")
                Farm.teleportToAllChests()
                if UI.Library then
                    UI.Library:Notify({
                        Title = "Farm",
                        Description = "Teleporting to all chests...",
                        Time = 2
                    })
                end
            end
        end
    })

    FarmLeftGroup:AddDivider()
    
    FarmLeftGroup:AddToggle("PotionBuyAndDrink", {
        Text = "Potion: Buy + Drink",
        Default = Config.potionBuyAndDrinkEnabled,
        Tooltip = "ON: Buy and use | OFF: Use from inventory only",
        Callback = function(Value)
            Config.potionBuyAndDrinkEnabled = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "Potion",
                    Description = Value and "Potion: Buy + Drink enabled" or "Potion: Use from inventory only",
                    Time = 2
                })
            end
        end
    })
    
    FarmLeftGroup:AddLabel("Potions - Common")

    FarmLeftGroup:AddButton({
        Text = "Common Attack",
        Func = function()
            if Config.potionBuyAndDrinkEnabled then
                if Farm and Farm.buyAndDrinkPotion then
                    Farm.buyAndDrinkPotion("CommonAttack")
                    if UI.Library then
                        UI.Library:Notify({
                            Title = "Potion",
                            Description = "Common Attack potion purchased and consumed!",
                            Time = 3
                        })
                    end
                end
            else
                if Farm and Farm.drinkPotion then
                    Farm.drinkPotion("CommonAttack")
                    if UI.Library then
                        UI.Library:Notify({
                            Title = "Potion",
                            Description = "Common Attack potion consumed from inventory!",
                            Time = 3
                        })
                    end
                end
            end
        end
    })

    FarmLeftGroup:AddButton({
        Text = "Common Health",
        Func = function()
            if Config.potionBuyAndDrinkEnabled then
                if Farm and Farm.buyAndDrinkPotion then
                    Farm.buyAndDrinkPotion("CommonHealth")
                    if UI.Library then
                        UI.Library:Notify({
                            Title = "Potion",
                            Description = "Common Health potion purchased and consumed!",
                            Time = 3
                        })
                    end
                end
            else
                if Farm and Farm.drinkPotion then
                    Farm.drinkPotion("CommonHealth")
                    if UI.Library then
                        UI.Library:Notify({
                            Title = "Potion",
                            Description = "Common Health potion consumed from inventory!",
                            Time = 3
                        })
                    end
                end
            end
        end
    })

    FarmLeftGroup:AddButton({
        Text = "Common Luck",
        Func = function()
            if Config.potionBuyAndDrinkEnabled then
                if Farm and Farm.buyAndDrinkPotion then
                    Farm.buyAndDrinkPotion("CommonLuck")
                    if UI.Library then
                        UI.Library:Notify({
                            Title = "Potion",
                            Description = "Common Luck potion purchased and consumed!",
                            Time = 3
                        })
                    end
                end
            else
                if Farm and Farm.drinkPotion then
                    Farm.drinkPotion("CommonLuck")
                    if UI.Library then
                        UI.Library:Notify({
                            Title = "Potion",
                            Description = "Common Luck potion consumed from inventory!",
                            Time = 3
                        })
                    end
                end
            end
        end
    })

    FarmLeftGroup:AddDivider()
    FarmLeftGroup:AddLabel("Potions - Rare")

    FarmLeftGroup:AddButton({
        Text = "Rare Attack",
        Func = function()
            if Config.potionBuyAndDrinkEnabled then
                if Farm and Farm.buyAndDrinkPotion then
                    Farm.buyAndDrinkPotion("RareAttack")
                    if UI.Library then
                        UI.Library:Notify({
                            Title = "Potion",
                            Description = "Rare Attack potion purchased and consumed!",
                            Time = 3
                        })
                    end
                end
            else
                if Farm and Farm.drinkPotion then
                    Farm.drinkPotion("RareAttack")
                    if UI.Library then
                        UI.Library:Notify({
                            Title = "Potion",
                            Description = "Rare Attack potion consumed from inventory!",
                            Time = 3
                        })
                    end
                end
            end
        end
    })

    FarmLeftGroup:AddButton({
        Text = "Rare Health",
        Func = function()
            if Config.potionBuyAndDrinkEnabled then
                if Farm and Farm.buyAndDrinkPotion then
                    Farm.buyAndDrinkPotion("RareHealth")
                    if UI.Library then
                        UI.Library:Notify({
                            Title = "Potion",
                            Description = "Rare Health potion purchased and consumed!",
                            Time = 3
                        })
                    end
                end
            else
                if Farm and Farm.drinkPotion then
                    Farm.drinkPotion("RareHealth")
                    if UI.Library then
                        UI.Library:Notify({
                            Title = "Potion",
                            Description = "Rare Health potion consumed from inventory!",
                            Time = 3
                        })
                    end
                end
            end
        end
    })

    FarmLeftGroup:AddButton({
        Text = "Rare Luck",
        Func = function()
            if Config.potionBuyAndDrinkEnabled then
                if Farm and Farm.buyAndDrinkPotion then
                    Farm.buyAndDrinkPotion("RareLuck")
                    if UI.Library then
                        UI.Library:Notify({
                            Title = "Potion",
                            Description = "Rare Luck potion purchased and consumed!",
                            Time = 3
                        })
                    end
                end
            else
                if Farm and Farm.drinkPotion then
                    Farm.drinkPotion("RareLuck")
                    if UI.Library then
                        UI.Library:Notify({
                            Title = "Potion",
                            Description = "Rare Luck potion consumed from inventory!",
                            Time = 3
                        })
                    end
                end
            end
        end
    })

    FarmLeftGroup:AddDivider()
    FarmLeftGroup:AddLabel("Codes")

    FarmLeftGroup:AddButton({
        Text = "Redeem All Codes",
        Tooltip = "RAID1212, CHRISTMAS, UPD1212",
        Func = function()
            Farm.redeemAllCodes()
            if UI.Library then
                UI.Library:Notify({
                    Title = "Codes",
                    Description = "Redeemed all codes! (RAID1212, CHRISTMAS, UPD1212)",
                    Time = 3
                })
            end
        end
    })

    -- Right Groupbox: Event
    local EventRightGroup = FarmEventTab:AddRightGroupbox("Event")

    EventRightGroup:AddDivider()

    EventRightGroup:AddToggle("ESPBob", {
        Text = "ESP Bob",
        Tooltip = "Display ESP for Bob",
        Default = Config.espBobEnabled,
        Callback = function(Value)
            Config.espBobEnabled = Value
            if Value then
                ESP.startBobESP()
            else
                ESP.stopBobESP()
            end
            if UI.Library then
                UI.Library:Notify({
                    Title = "Bob ESP",
                    Description = Value and "Bob ESP enabled" or "Bob ESP disabled",
                    Time = 2
                })
            end
        end
    })

    EventRightGroup:AddLabel("Bob ESP Color"):AddColorPicker("ESPBobColor", {
        Default = Config.espColorBob,
        Title = "Bob ESP Color",
        Callback = function(Value)
            Config.espColorBob = Value
            -- Refresh highlights with new color
            for model, highlight in pairs(ESP.bobHighlights) do
                if highlight then
                    highlight.FillColor = Value
                    highlight.OutlineColor = Value
                end
            end
            -- Refresh Drawing text color
            for model, data in pairs(ESP.bobESPObjects) do
                if data.Name then
                    data.Name.Color = Value
                end
            end
        end
    })

    EventRightGroup:AddButton({
        Text = "Teleport to Bob",
        Tooltip = "Teleport to the nearest Bob",
        Func = function()
            local success = ESP.teleportToBob()
            if success then
                if UI.Library then
                    UI.Library:Notify({
                        Title = "Bob ESP",
                        Description = "Teleported to Bob!",
                        Time = 2
                    })
                end
            else
                if UI.Library then
                    UI.Library:Notify({
                        Title = "Bob ESP",
                        Description = "Bob not found!",
                        Time = 2
                    })
                end
            end
        end
    })

    EventRightGroup:AddDivider()

    EventRightGroup:AddToggle("AutoBuyChristmasGiftBox", {
        Text = "Auto Buy Christmas Gift Box",
        Tooltip = "Automatically buy Christmas Gift Box every second",
        Default = Config.autoBuyChristmasGiftBoxEnabled,
        Callback = function(Value)
            Config.autoBuyChristmasGiftBoxEnabled = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "Event",
                    Description = Value and "Auto Buy Christmas Gift Box enabled" or "Auto Buy Christmas Gift Box disabled",
                    Time = 2
                })
            end
        end
    })

    EventRightGroup:AddToggle("AutoBuySantaClausGift", {
        Text = "Auto Buy Santa Claus Gift",
        Tooltip = "Automatically buy Santa Claus Gift every second",
        Default = Config.autoBuySantaClausGiftEnabled,
        Callback = function(Value)
            Config.autoBuySantaClausGiftEnabled = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "Event",
                    Description = Value and "Auto Buy Santa Claus Gift enabled" or "Auto Buy Santa Claus Gift disabled",
                    Time = 2
                })
            end
        end
    })

    return FarmEventTab
end

----------------------------------------------------------
-- 🔹 Character Tab
function UI.createCharacterTab()
    local CharacterTab = UI.Window:AddTab("Character", "user")
    local CharacterGroup = CharacterTab:AddLeftGroupbox("Character")

    CharacterGroup:AddDivider()

    local displayList, displayToId = Character.getCharacterDisplayList()

    if not displayList or #displayList == 0 then
        displayList = {"Failed to read character data (join a game first)"}
        displayToId = {}
    end

    -- Lấy character đang equip để set default
    local currentCharacterId = Character.getCurrentCharacterId()
    local defaultDisplay = nil

    -- Tìm display string của character đang equip
    if currentCharacterId and displayToId then
        for display, id in pairs(displayToId) do
            if id == currentCharacterId then
                defaultDisplay = display
                break
            end
        end
    end

    -- Fallback nếu không tìm thấy
    if not defaultDisplay then
        defaultDisplay = displayList[1]
    end

    if displayToId and displayToId[defaultDisplay] then
        Config.selectedCharacterId = displayToId[defaultDisplay]
        Config.selectedCharacterDisplay = defaultDisplay
    end

    CharacterGroup:AddDropdown("SelectedCharacter", {
        Text = "Character",
        Values = displayList,
        Default = defaultDisplay,
        Callback = function(Value)
            Config.selectedCharacterDisplay = Value
            local idMap = Character.DisplayToId or displayToId or {}
            local selectedId = idMap[Value]
            if selectedId then
                Config.selectedCharacterId = selectedId
            end
            if UI.Library then
                UI.Library:Notify({
                    Title = "Character",
                    Description = "Selected: " .. Value,
                    Time = 2
                })
            end
        end
    })

    CharacterGroup:AddButton({
        Text = "Equip Selected Character",
        Tooltip = "Equip the selected character (and use for Auto Skill)",
        Func = function()
            local id = Config.selectedCharacterId
            if not id then
                if UI.Library then
                    UI.Library:Notify({
                        Title = "Character",
                        Description = "No character selected in dropdown!",
                        Time = 3
                    })
                end
                return
            end

            local success, err = Character.equipCharacter(id)

            if UI.Library then
                if success then
                    UI.Library:Notify({
                        Title = "Character",
                        Description = "Sent request to equip character " .. tostring(Config.selectedCharacterDisplay or id),
                        Time = 3
                    })
                else
                    UI.Library:Notify({
                        Title = "Character",
                        Description = "Equip failed: " .. tostring(err),
                        Time = 3
                    })
                end
            end

            -- Sau khi equip thành công, restart toàn bộ Auto Skill loops cho character mới
            if success then
                task.delay(1, function()
                    if not Config.scriptUnloaded then
                        Character.startAllSkillLoops()
                    end
                end)
            end
        end
    })

    CharacterGroup:AddDivider()

    -- Auto Skill toggle
    CharacterGroup:AddToggle("AutoSkill", {
        Text = "Auto Skill",
        Tooltip = "Automatically use skills based on equipped character",
        Default = Config.autoSkillEnabled,
        Callback = function(Value)
            Config.autoSkillEnabled = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "Character",
                    Description = Value and "Auto Skill enabled" or "Auto Skill disabled",
                    Time = 2
                })
            end
        end
    })

    -- Helper function để tạo label với highlight
    local function getCharacterLabel(name, id)
        if currentCharacterId == id then
            return "► " .. name .. " (EQUIPPED)"
        end
        return name
    end

    -- If we cannot get current character, show info and skip skill group
    if not currentCharacterId then
        CharacterGroup:AddLabel("Unable to detect current character - join the game, equip a character, then reopen the menu.")
        return CharacterTab
    end

    -- Chỉ hiển thị group skill của đúng nhân vật hiện tại
    if currentCharacterId == 1006 then
        -- Armsmaster (1006)
        local ArmsmasterGroup = CharacterTab:AddRightGroupbox(getCharacterLabel("Armsmaster (1006)", 1006))
        ArmsmasterGroup:AddToggle("ArmsmasterUltimateEnabled", {
            Text = "Enable Ultimate",
            Default = Config.armsmasterUltimateEnabled,
            Callback = function(Value) Config.armsmasterUltimateEnabled = Value end
        })
        ArmsmasterGroup:AddSlider("ArmsmasterUltimateInterval", {
            Text = "Ultimate Interval (s)",
            Default = Config.armsmasterUltimateInterval,
            Min = 15, Max = 60, Rounding = 0,
            Callback = function(Value) Config.armsmasterUltimateInterval = Value end
        })
        ArmsmasterGroup:AddToggle("ArmsmasterFSkillEnabled", {
            Text = "Enable Skill (F) - Healing",
            Default = Config.armsmasterFSkillEnabled,
            Callback = function(Value) Config.armsmasterFSkillEnabled = Value end
        })
        ArmsmasterGroup:AddSlider("ArmsmasterFSkillInterval", {
            Text = "Skill (F) Interval (s)",
            Default = Config.armsmasterFSkillInterval,
            Min = 20, Max = 60, Rounding = 0,
            Callback = function(Value) Config.armsmasterFSkillInterval = Value end
        })

    elseif currentCharacterId == 1003 then
        -- Wraith (1003)
        local WraithGroup = CharacterTab:AddRightGroupbox(getCharacterLabel("Wraith (1003)", 1003))
        WraithGroup:AddToggle("WraithUltimateEnabled", {
            Text = "Enable Ultimate (G)",
            Default = Config.wraithUltimateEnabled,
            Callback = function(Value) Config.wraithUltimateEnabled = Value end
        })
        WraithGroup:AddSlider("WraithUltimateInterval", {
            Text = "Ultimate (G) Interval (s)",
            Default = Config.wraithUltimateInterval,
            Min = 0.3, Max = 10, Rounding = 1,
            Callback = function(Value) Config.wraithUltimateInterval = Value end
        })
        WraithGroup:AddToggle("WraithQSkillEnabled", {
            Text = "Enable Skill (Q)",
            Default = Config.wraithQSkillEnabled,
            Callback = function(Value) Config.wraithQSkillEnabled = Value end
        })
        WraithGroup:AddSlider("WraithQSkillInterval", {
            Text = "Skill (Q) Interval (s)",
            Default = Config.wraithQSkillInterval,
            Min = 5, Max = 30, Rounding = 0,
            Callback = function(Value) Config.wraithQSkillInterval = Value end
        })
        WraithGroup:AddToggle("WraithFSkillEnabled", {
            Text = "Enable Skill (F) - Healing",
            Default = Config.wraithFSkillEnabled,
            Callback = function(Value) Config.wraithFSkillEnabled = Value end
        })
        WraithGroup:AddSlider("WraithFSkillInterval", {
            Text = "Skill (F) Interval (s)",
            Default = Config.wraithFSkillInterval,
            Min = 20, Max = 60, Rounding = 0,
            Callback = function(Value) Config.wraithFSkillInterval = Value end
        })

    elseif currentCharacterId == 1001 then
        -- Assault (1001)
        local AssaultGroup = CharacterTab:AddRightGroupbox(getCharacterLabel("Assault (1001)", 1001))
        AssaultGroup:AddToggle("AssaultUltimateEnabled", {
            Text = "Enable Ultimate (G)",
            Default = Config.assaultUltimateEnabled,
            Callback = function(Value) Config.assaultUltimateEnabled = Value end
        })
        AssaultGroup:AddSlider("AssaultUltimateInterval", {
            Text = "Ultimate (G) Interval (s)",
            Default = Config.assaultUltimateInterval,
            Min = 0.3, Max = 10, Rounding = 1,
            Callback = function(Value) Config.assaultUltimateInterval = Value end
        })
        AssaultGroup:AddToggle("AssaultQSkillEnabled", {
            Text = "Enable Skill (Q)",
            Default = Config.assaultQSkillEnabled,
            Callback = function(Value) Config.assaultQSkillEnabled = Value end
        })
        AssaultGroup:AddSlider("AssaultQSkillInterval", {
            Text = "Skill (Q) Interval (s)",
            Default = Config.assaultQSkillInterval,
            Min = 9, Max = 30, Rounding = 0,
            Callback = function(Value) Config.assaultQSkillInterval = Value end
        })
        AssaultGroup:AddToggle("AssaultFSkillEnabled", {
            Text = "Enable Skill (F) - Healing",
            Default = Config.assaultFSkillEnabled,
            Callback = function(Value) Config.assaultFSkillEnabled = Value end
        })
        AssaultGroup:AddSlider("AssaultFSkillInterval", {
            Text = "Skill (F) Interval (s)",
            Default = Config.assaultFSkillInterval,
            Min = 20, Max = 30, Rounding = 0,
            Callback = function(Value) Config.assaultFSkillInterval = Value end
        })

    elseif currentCharacterId == 1005 then
        -- Ninja (1005)
        local NinjaGroup = CharacterTab:AddRightGroupbox(getCharacterLabel("Ninja (1005)", 1005))
        NinjaGroup:AddToggle("NinjaUltimateEnabled", {
            Text = "Enable Ultimate (G)",
            Default = Config.ninjaUltimateEnabled,
            Callback = function(Value) Config.ninjaUltimateEnabled = Value end
        })
        NinjaGroup:AddSlider("NinjaUltimateInterval", {
            Text = "Ultimate (G) Interval (s)",
            Default = Config.ninjaUltimateInterval,
            Min = 0.3, Max = 10, Rounding = 1,
            Callback = function(Value) Config.ninjaUltimateInterval = Value end
        })

        NinjaGroup:AddDropdown("NinjaUltimateTargetMode", {
            Text = "Ultimate Target Mode",
            Values = {"Single", "Multi"},
            Default = Config.ninjaUltimateTargetMode or "Single",
            Callback = function(Value)
                Config.ninjaUltimateTargetMode = Value
                if UI.Library then
                    UI.Library:Notify({
                        Title = "Ninja Ultimate",
                        Description = "Target Mode: " .. Value,
                        Time = 2
                    })
                end
            end
        })

        NinjaGroup:AddToggle("NinjaQSkillEnabled", {
            Text = "Enable Skill (Q)",
            Default = Config.ninjaQSkillEnabled,
            Callback = function(Value) Config.ninjaQSkillEnabled = Value end
        })
        NinjaGroup:AddSlider("NinjaQSkillInterval", {
            Text = "Skill (Q) Interval (s)",
            Default = Config.ninjaQSkillInterval,
            Min = 9, Max = 30, Rounding = 0,
            Callback = function(Value) Config.ninjaQSkillInterval = Value end
        })

        NinjaGroup:AddToggle("NinjaFSkillEnabled", {
            Text = "Enable Skill (F) - Healing",
            Default = Config.ninjaFSkillEnabled,
            Callback = function(Value) Config.ninjaFSkillEnabled = Value end
        })
        NinjaGroup:AddSlider("NinjaFSkillInterval", {
            Text = "Skill (F) Interval (s)",
            Default = Config.ninjaFSkillInterval or 20,
            Min = 20, Max = 30, Rounding = 0,
            Callback = function(Value) Config.ninjaFSkillInterval = Value end
        })

    elseif currentCharacterId == 1004 then
        -- Flag Bearer (1004)
        local FlagBearerGroup = CharacterTab:AddRightGroupbox(getCharacterLabel("Flag Bearer (1004)", 1004))
        FlagBearerGroup:AddToggle("FlagBearerUltimateEnabled", {
            Text = "Enable Ultimate",
            Default = Config.flagBearerUltimateEnabled,
            Callback = function(Value) Config.flagBearerUltimateEnabled = Value end
        })
        FlagBearerGroup:AddSlider("FlagBearerUltimateInterval", {
            Text = "Ultimate Interval (s)",
            Default = Config.flagBearerUltimateInterval,
            Min = 5, Max = 20, Rounding = 0,
            Callback = function(Value) Config.flagBearerUltimateInterval = Value end
        })
        FlagBearerGroup:AddToggle("FlagBearerFSkillEnabled", {
            Text = "Enable Skill (F) - Healing",
            Default = Config.flagBearerFSkillEnabled,
            Callback = function(Value) Config.flagBearerFSkillEnabled = Value end
        })
        FlagBearerGroup:AddSlider("FlagBearerFSkillInterval", {
            Text = "Skill (F) Interval (s)",
            Default = Config.flagBearerFSkillInterval,
            Min = 20, Max = 30, Rounding = 0,
            Callback = function(Value) Config.flagBearerFSkillInterval = Value end
        })

    elseif currentCharacterId == 1007 then
        -- Witch (1007)
        local WitchGroup = CharacterTab:AddRightGroupbox(getCharacterLabel("Witch (1007)", 1007))
        WitchGroup:AddToggle("WitchUltimateEnabled", {
            Text = "Enable Ultimate",
            Default = Config.witchUltimateEnabled,
            Callback = function(Value) Config.witchUltimateEnabled = Value end
        })
        WitchGroup:AddSlider("WitchUltimateInterval", {
            Text = "Ultimate Interval (s)",
            Default = Config.witchUltimateInterval,
            Min = 15, Max = 30, Rounding = 0,
            Callback = function(Value) Config.witchUltimateInterval = Value end
        })
        WitchGroup:AddToggle("WitchGSkillEnabled", {
            Text = "Enable Skill (G)",
            Default = Config.witchGSkillEnabled,
            Callback = function(Value) Config.witchGSkillEnabled = Value end
        })
        WitchGroup:AddSlider("WitchGSkillInterval", {
            Text = "Skill (G) Interval (s)",
            Default = Config.witchGSkillInterval,
            Min = 0.7, Max = 10, Rounding = 1,
            Callback = function(Value) Config.witchGSkillInterval = Value end
        })
        WitchGroup:AddToggle("WitchFSkillEnabled", {
            Text = "Enable Skill (F)",
            Default = Config.witchFSkillEnabled,
            Callback = function(Value) Config.witchFSkillEnabled = Value end
        })
        WitchGroup:AddSlider("WitchFSkillInterval", {
            Text = "Skill (F) Interval (s)",
            Default = Config.witchFSkillInterval,
            Min = 0.7, Max = 10, Rounding = 1,
            Callback = function(Value) Config.witchFSkillInterval = Value end
        })
    else
        -- Trường hợp character không nằm trong danh sách trên
        CharacterGroup:AddLabel("Nhân vật hiện tại chưa có cấu hình Auto Skill riêng.")
    end

    return CharacterTab
end



----------------------------------------------------------
-- 🔹 Settings Tab
function UI.createSettingsTab(cleanupCallback)
    local SettingsTab = UI.Window:AddTab("Settings", "settings")
    local MenuGroup = SettingsTab:AddLeftGroupbox("Menu", "wrench")

    MenuGroup:AddToggle("KeybindMenuOpen", {
        Default = UI.Library.KeybindFrame.Visible,
        Text = "Open Keybind Menu",
        Callback = function(value)
            UI.Library.KeybindFrame.Visible = value
            if UI.Library then
                UI.Library:Notify({
                    Title = "Settings",
                    Description = value and "Keybind Menu opened" or "Keybind Menu closed",
                    Time = 2
                })
            end
        end,
    })

    MenuGroup:AddToggle("ShowCustomCursor", {
        Text = "Custom Cursor",
        Default = true,
        Callback = function(Value)
            UI.Library.ShowCustomCursor = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "Settings",
                    Description = Value and "Custom Cursor enabled" or "Custom Cursor disabled",
                    Time = 2
                })
            end
        end,
    })

    MenuGroup:AddDropdown("NotificationSide", {
        Values = { "Left", "Right" },
        Default = "Right",
        Text = "Notification Side",
        Callback = function(Value)
            UI.Library:SetNotifySide(Value)
            if UI.Library then
                UI.Library:Notify({
                    Title = "Settings",
                    Description = "Notification side: " .. Value,
                    Time = 2
                })
            end
        end,
    })

    MenuGroup:AddDropdown("DPIDropdown", {
        Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
        Default = "100%",
        Text = "DPI Scale",
        Callback = function(Value)
            Value = Value:gsub("%%", "")
            local DPI = tonumber(Value)
            UI.Library:SetDPIScale(DPI)
            if UI.Library then
                UI.Library:Notify({
                    Title = "Settings",
                    Description = "DPI Scale: " .. Value .. "%",
                    Time = 2
                })
            end
        end,
    })

    MenuGroup:AddDivider()
    MenuGroup:AddLabel("Reset Script")

    MenuGroup:AddButton({
        Text = "Unload Script",
        Tooltip = "Unload all scripts and delete GUI",
        Func = function()
            if UI.Library then
                UI.Library:Notify({
                    Title = "Script",
                    Description = "Unloading script...",
                    Time = 2
                })
            end
            task.wait(0.1)
            -- Unload Obsidian UI library (this will trigger OnUnload callback which calls cleanupCallback)
            if UI.Library then
                UI.Library:Unload()
            end
        end
    })

    MenuGroup:AddDivider()
    MenuGroup:AddLabel("Menu bind")
        :AddKeyPicker("MenuKeybind", { 
            Default = "RightShift", 
            NoUI = true, 
            Text = "Menu keybind",
            Mode = "Toggle"
        })

    -- Set menu keybind
    UI.Library.ToggleKeybind = UI.Library.Options.MenuKeybind

    -- Keybinds Section
    local KeybindsGroup = SettingsTab:AddRightGroupbox("Keybinds")

    KeybindsGroup:AddDivider()
    KeybindsGroup:AddLabel("Feature Keybinds")

    KeybindsGroup:AddLabel("Auto Rotate (Toggle)"):AddKeyPicker("AutoRotateKey", {
        Default = "L",
        Mode = "Toggle",
        Text = "Auto Rotate 360°",
        NoUI = false,
        Callback = function(Value)
            if Value then
                -- Chỉ bật/tắt trạng thái active, vẫn phải được phép bởi toggle trong Movement
                if not Config.autoRotateEnabled then
                    return
                end

                Config.autoRotateActive = not (Config.autoRotateActive or false)
                if Combat and Combat.toggleAutoRotate then
                    Combat.toggleAutoRotate(Config.autoRotateActive)
                end
            end
        end
    })

    KeybindsGroup:AddLabel("Camera Teleport (Toggle)"):AddKeyPicker("CameraTeleportKey", {
        Default = "X",
        Mode = "Toggle",
        Text = "Camera Teleport to Zombies",
        NoUI = false,
        Callback = function(Value)
            -- Camera teleport logic is handled in main.lua InputBegan handler
        end
    })

    KeybindsGroup:AddLabel("Auto Chest (Press)"):AddKeyPicker("ChestTeleportKey", {
        Default = "T",
        Mode = "Press",
        Text = "Teleport to All Chests",
        NoUI = false,
        Callback = function()
            if Farm and Farm.teleportToAllChests then
                print("[UI] Teleport to All Chests button clicked")
                Farm.teleportToAllChests()
            else
                print("[UI] Farm module not found or teleportToAllChests function missing")
            end
        end
    })

    KeybindsGroup:AddDivider()
    KeybindsGroup:AddLabel("Utility Keybinds")

    KeybindsGroup:AddLabel("Unload Script"):AddKeyPicker("UnloadKey", {
        Default = "End",
        Mode = "Press",
        Text = "Unload Script",
        NoUI = false,
        Callback = function()
            if cleanupCallback then cleanupCallback() end
            task.wait(0.1)
            if UI.Library then
                UI.Library:Unload()
            end
        end
    })

    -- Connect keybinds to actual keys in config
    task.spawn(function()
        task.wait(0.5) -- Wait for UI to fully load
        if UI.Library and UI.Library.Options then
            local Options = UI.Library.Options
            
            -- Update config keys when keybinds change
            if Options.AutoRotateKey then
                Options.AutoRotateKey:OnChanged(function()
                    Config.autoRotateToggleKey = Options.AutoRotateKey.Value
                end)
            end
            
            if Options.CameraTeleportKey then
                Options.CameraTeleportKey:OnChanged(function()
                    Config.cameraTeleportKey = Options.CameraTeleportKey.Value
                end)
            end
            
            if Options.ChestTeleportKey then
                Options.ChestTeleportKey:OnChanged(function()
                    Config.teleportKey = Options.ChestTeleportKey.Value
                end)
            end
            
            if Options.UnloadKey then
                Options.UnloadKey:OnChanged(function()
                    Config.unloadKey = Options.UnloadKey.Value
                end)
            end
        end
    end)

    -- Config Save / Load
    UI.SaveManager:SetLibrary(UI.Library)
    UI.ThemeManager:SetLibrary(UI.Library)
    UI.SaveManager:IgnoreThemeSettings()
    UI.SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
    UI.SaveManager:SetFolder("ZombieHyperloot/Configs")
    UI.SaveManager:BuildConfigSection(SettingsTab)
    UI.ThemeManager:ApplyToTab(SettingsTab)
    UI.SaveManager:LoadAutoloadConfig()

    return SettingsTab
end

----------------------------------------------------------
-- 🔹 Visuals & HUD Tab (Merged)
function UI.createVisualsHUDTab()
    local VisualsHUDTab = UI.Window:AddTab("Visuals & HUD", "eye")
    
    -- Left Groupbox: Visuals
    local VisualsLeftGroup = VisualsHUDTab:AddLeftGroupbox("Visuals")

    VisualsLeftGroup:AddDivider()

    VisualsLeftGroup:AddToggle("RemoveFog", {
        Text = "Remove Fog",
        Tooltip = "Remove fog to see further",
        Default = Config.removeFogEnabled,
        Callback = function(Value)
            Config.removeFogEnabled = Value
            Visuals.toggleRemoveFog(Value)
            if UI.Library then
                UI.Library:Notify({
                    Title = "Visuals",
                    Description = Value and "Remove Fog enabled" or "Remove Fog disabled",
                    Time = 2
                })
            end
        end
    })

    VisualsLeftGroup:AddDivider()

    VisualsLeftGroup:AddToggle("Fullbright", {
        Text = "Fullbright",
        Tooltip = "Make the entire map brighter",
        Default = Config.fullbrightEnabled,
        Callback = function(Value)
            Config.fullbrightEnabled = Value
            Visuals.toggleFullbright(Value)
            if UI.Library then
                UI.Library:Notify({
                    Title = "Visuals",
                    Description = Value and "Fullbright enabled" or "Fullbright disabled",
                    Time = 2
                })
            end
        end
    })

    VisualsLeftGroup:AddDivider()

    VisualsLeftGroup:AddToggle("CustomTime", {
        Text = "Custom Time",
        Tooltip = "Customize time in game",
        Default = Config.customTimeEnabled,
        Callback = function(Value)
            Config.customTimeEnabled = Value
            Visuals.toggleCustomTime(Value)
            if UI.Library then
                UI.Library:Notify({
                    Title = "Visuals",
                    Description = Value and "Custom Time enabled" or "Custom Time disabled",
                    Time = 2
                })
            end
        end
    })

    VisualsLeftGroup:AddSlider("TimeValue", {
        Text = "Time (Hour)",
        Tooltip = "0 = Midnight, 12 = Noon, 14 = Afternoon",
        Default = Config.customTimeValue,
        Min = 0, Max = 24, Rounding = 0,
        Callback = function(Value)
            Config.customTimeValue = Value
            if Config.customTimeEnabled then
                Visuals.setCustomTime(Value)
            end
        end
    })

    VisualsLeftGroup:AddDivider()

    VisualsLeftGroup:AddToggle("RemoveEffects", {
        Text = "Auto Remove Effects",
        Tooltip = "Automatically remove effects when duping for the first time",
        Default = Config.removeEffectsEnabled,
        Callback = function(Value)
            Config.removeEffectsEnabled = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "Visuals",
                    Description = Value and "Auto Remove Effects enabled" or "Auto Remove Effects disabled",
                    Time = 2
                })
            end
        end
    })

    -- Right Groupbox: HUD Customization
    local HUDRightGroup = VisualsHUDTab:AddRightGroupbox("HUD Customization")

    HUDRightGroup:AddToggle("CustomHUD", {
        Text = "Enable Custom HUD",
        Tooltip = "Bật/tắt custom HUD",
        Default = false,
        Callback = function(Value)
            HUD.toggleCustomHUD(Value)
            if UI.Library then
                UI.Library:Notify({
                    Title = "HUD",
                    Description = Value and "Custom HUD enabled" or "Custom HUD disabled",
                    Time = 2
                })
            end
        end
    })

    HUDRightGroup:AddToggle("ApplyToOtherPlayers", {
        Text = "Apply to Other Players",
        Tooltip = "Áp dụng custom HUD cho tất cả players khác",
        Default = true,
        Callback = function(Value)
            HUD.toggleApplyToOtherPlayers(Value)
            if UI.Library then
                UI.Library:Notify({
                    Title = "HUD",
                    Description = Value and "Apply to Other Players enabled" or "Apply to Other Players disabled",
                    Time = 2
                })
            end
        end
    })

    HUDRightGroup:AddDivider()
    HUDRightGroup:AddLabel("Visibility Settings")

    HUDRightGroup:AddToggle("TitleVisible", {
        Text = "Show Title",
        Default = true,
        Callback = function(Value)
            HUD.titleVisible = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDRightGroup:AddToggle("PlayerNameVisible", {
        Text = "Show Player Name",
        Default = true,
        Callback = function(Value)
            HUD.playerNameVisible = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDRightGroup:AddToggle("ClassVisible", {
        Text = "Show Class",
        Default = true,
        Callback = function(Value)
            HUD.classVisible = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDRightGroup:AddToggle("LevelVisible", {
        Text = "Show Level",
        Default = true,
        Callback = function(Value)
            HUD.levelVisible = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDRightGroup:AddDivider()
    HUDRightGroup:AddLabel("EXP Display")

    HUDRightGroup:AddToggle("ExpDisplay", {
        Text = "Show EXP Display",
        Tooltip = "Display EXP at the bottom right of the screen",
        Default = true,
        Callback = function(Value)
            if UI.Library then
                UI.Library:Notify({
                    Title = "HUD",
                    Description = Value and "EXP Display enabled" or "EXP Display disabled",
                    Time = 2
                })
            end
            HUD.toggleExpDisplay(Value)
        end
    })

    HUDRightGroup:AddDivider()
    HUDRightGroup:AddLabel("Text Customization")

    HUDRightGroup:AddInput("CustomTitle", {
        Text = "Custom Title",
        Tooltip = "Leave empty to keep original",
        Default = "CHEATER",
        Placeholder = "Enter title...",
        Callback = function(Value)
            HUD.customTitle = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDRightGroup:AddInput("CustomPlayerName", {
        Text = "Custom Player Name",
        Tooltip = "Leave empty to keep original",
        Default = "WiniFy",
        Placeholder = "Enter name...",
        Callback = function(Value)
            HUD.customPlayerName = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDRightGroup:AddInput("CustomClass", {
        Text = "Custom Class",
        Tooltip = "Leave empty to keep original",
        Default = "",
        Placeholder = "Enter class...",
        Callback = function(Value)
            HUD.customClass = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDRightGroup:AddInput("CustomLevel", {
        Text = "Custom Level",
        Tooltip = "Leave empty to keep original",
        Default = "",
        Placeholder = "Enter level...",
        Callback = function(Value)
            HUD.customLevel = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDRightGroup:AddDivider()
    HUDRightGroup:AddLabel("Actions")

    HUDRightGroup:AddButton({
        Text = "Apply Changes",
        Tooltip = "Apply all changes",
        Func = function()
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
                if UI.Library then
                    UI.Library:Notify({
                        Title = "HUD",
                        Description = "HUD changes applied!",
                        Time = 2
                    })
                end
            else
                if UI.Library then
                    UI.Library:Notify({
                        Title = "HUD",
                        Description = "Please enable Custom HUD first",
                        Time = 2
                    })
                end
            end
        end
    })

    HUDRightGroup:AddButton({
        Text = "Reset to Original",
        Tooltip = "Restore HUD to original",
        Func = function()
            HUD.restoreOriginalHUD()
            if UI.Library then
                UI.Library:Notify({
                    Title = "HUD",
                    Description = "HUD restored to original!",
                    Time = 2
                })
            end
        end
    })

    -- Add a second right groupbox for Gradient Colors (since we need more space)
    local HUDGradientGroup = VisualsHUDTab:AddRightGroupbox("Gradient Colors")

    HUDGradientGroup:AddDivider()
    HUDGradientGroup:AddLabel("Title Gradient Colors")

    HUDGradientGroup:AddLabel("Title Color 1"):AddColorPicker("TitleGradient1", {
        Default = Color3.fromRGB(255, 0, 0), -- Red
        Title = "Title Color 1",
        Callback = function(Value)
            HUD.titleGradientColor1 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDGradientGroup:AddLabel("Title Color 2"):AddColorPicker("TitleGradient2", {
        Default = Color3.fromRGB(255, 255, 255), -- White
        Title = "Title Color 2",
        Callback = function(Value)
            HUD.titleGradientColor2 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDGradientGroup:AddDivider()
    HUDGradientGroup:AddLabel("Player Name Gradient Colors")

    HUDGradientGroup:AddLabel("Name Color 1"):AddColorPicker("PlayerNameGradient1", {
        Default = HUD.playerNameGradientColor1 or Color3.fromRGB(255, 255, 255),
        Title = "Name Color 1",
        Callback = function(Value)
            HUD.playerNameGradientColor1 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDGradientGroup:AddLabel("Name Color 2"):AddColorPicker("PlayerNameGradient2", {
        Default = HUD.playerNameGradientColor2 or Color3.fromRGB(255, 255, 255),
        Title = "Name Color 2",
        Callback = function(Value)
            HUD.playerNameGradientColor2 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDGradientGroup:AddDivider()
    HUDGradientGroup:AddLabel("Class Gradient Colors")

    HUDGradientGroup:AddLabel("Class Color 1"):AddColorPicker("ClassGradient1", {
        Default = HUD.classGradientColor1 or Color3.fromRGB(255, 255, 255),
        Title = "Class Color 1",
        Callback = function(Value)
            HUD.classGradientColor1 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDGradientGroup:AddLabel("Class Color 2"):AddColorPicker("ClassGradient2", {
        Default = HUD.classGradientColor2 or Color3.fromRGB(255, 255, 255),
        Title = "Class Color 2",
        Callback = function(Value)
            HUD.classGradientColor2 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDGradientGroup:AddDivider()
    HUDGradientGroup:AddLabel("Level Gradient Colors")

    HUDGradientGroup:AddLabel("Level Color 1"):AddColorPicker("LevelGradient1", {
        Default = HUD.levelGradientColor1 or Color3.fromRGB(255, 255, 255),
        Title = "Level Color 1",
        Callback = function(Value)
            HUD.levelGradientColor1 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDGradientGroup:AddLabel("Level Color 2"):AddColorPicker("LevelGradient2", {
        Default = HUD.levelGradientColor2 or Color3.fromRGB(255, 255, 255),
        Title = "Level Color 2",
        Callback = function(Value)
            HUD.levelGradientColor2 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    return VisualsHUDTab
end

----------------------------------------------------------
-- 🔹 Build All Tabs
function UI.buildAllTabs(cleanupCallback)
    -- Use merged tabs
    UI.createChangelogTab()        -- Changelog (separate tab)
    UI.createCombatESPTab()        -- Combat & ESP merged
    UI.createMovementMapTab()      -- Movement & Map merged
    UI.createFarmEventTab()        -- Farm & Event merged
    UI.createCharacterTab()       -- Character (unchanged)
    UI.createAFKTab()             -- AFK tab
    UI.createVisualsHUDTab()       -- Visuals & HUD merged
    UI.createServerTab()           -- Server (unchanged)
    UI.createSettingsTab(cleanupCallback)  -- Settings
    
    -- Setup OnUnload callback for Obsidian UI
    if UI.Library and cleanupCallback then
        UI.Library:OnUnload(function()
            cleanupCallback()
        end)
    end
end

----------------------------------------------------------
-- 🔹 AFK Tab
function UI.createAFKTab()
    local AFKTab = UI.Window:AddTab("AFK", "gift")
    local AFKGroup = AFKTab:AddLeftGroupbox("AFK Features", "gift")

    AFKGroup:AddToggle("AutoDrawGift", {
        Text = "Auto Draw Gift",
        Default = false,
        Tooltip = "Automatically draw gift every second",
        Callback = function(Value)
            if Value then
                if not UI._afkDrawConnection then
                    UI._afkDrawConnection = task.spawn(function()
                        while UI.Toggles.AutoDrawGift and UI.Toggles.AutoDrawGift.Value do
                            local args = {940454352}
                            game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
                            task.wait(1)
                        end
                    end)
                end
                
                if UI.Library then
                    UI.Library:Notify({
                        Title = "AFK",
                        Description = "Auto Draw Gift enabled",
                        Time = 2
                    })
                end
            else
                if UI._afkDrawConnection then
                    UI._afkDrawConnection = nil
                end
                
                if UI.Library then
                    UI.Library:Notify({
                        Title = "AFK",
                        Description = "Auto Draw Gift disabled",
                        Time = 2
                    })
                end
            end
        end
    })
end

----------------------------------------------------------
-- 🔹 Cleanup
function UI.cleanup()
    -- Stop AFK draw connection
    if UI._afkDrawConnection then
        UI._afkDrawConnection = nil
    end
    
    if UI.Window and UI.Window.Destroy then
        pcall(function() UI.Window:Destroy() end)
    end
end

return UI
