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
end

function UI.createWindow()
    UI.Library.ForceCheckbox = false
    UI.Library.ShowToggleFrameInKeybinds = true
    
    UI.Window = UI.Library:CreateWindow({
        Title = "Zombie Hyperloot",
        Footer = "by WiniFy",
        NotifySide = "Right",
        ShowCustomCursor = true,
    })
end

----------------------------------------------------------
-- 🔹 Combat Tab
function UI.createCombatTab()
    local CombatTab = UI.Window:AddTab("Combat", "sword")
    local CombatLeftGroup = CombatTab:AddLeftGroupbox("Combat")

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

    -- Right Groupbox
    local CombatRightGroup = CombatTab:AddRightGroupbox("Combat Settings")

    CombatRightGroup:AddDivider()

    CombatRightGroup:AddToggle("Hitbox", {
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

    CombatRightGroup:AddSlider("HitboxSize", {
        Text = "Hitbox Size",
        Default = 4, Min = 1, Max = 20, Rounding = 1,
        Callback = function(Value)
            Config.hitboxSize = Vector3.new(Value, Value, Value)
        end
    })

    CombatRightGroup:AddDivider()

    CombatRightGroup:AddToggle("TrigerSkillDupeEnabled", {
        Text = "Enable TrigerSkill Dupe",
        Default = Config.trigerSkillDupeEnabled,
        Callback = function(Value)
            Config.trigerSkillDupeEnabled = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "TrigerSkill Dupe",
                    Description = Value and "TrigerSkill Dupe enabled" or "TrigerSkill Dupe disabled",
                    Time = 2
                })
            end
        end
    })

    CombatRightGroup:AddSlider("TrigerSkillDupeCount", {
        Text = "Dupe Count",
        Default = Config.trigerSkillDupeCount,
        Min = 1, Max = 20, Rounding = 0,
        Callback = function(Value) Config.trigerSkillDupeCount = Value end
    })

    CombatRightGroup:AddDivider()

    CombatRightGroup:AddToggle("AutoRotate", {
        Text = "Aimbot 360°",
        Tooltip = "Camera automatically rotates to the nearest zombie (press R to toggle)",
        Default = Config.autoRotateEnabled,
        Callback = function(Value)
            Config.autoRotateEnabled = Value
            Combat.toggleAutoRotate(Value)
            if UI.Library then
                UI.Library:Notify({
                    Title = "Auto Rotate",
                    Description = Value and "Aimbot 360° enabled" or "Aimbot 360° disabled",
                    Time = 2
                })
            end
        end
    })

    CombatRightGroup:AddSlider("AutoRotateSmoothness", {
        Text = "Rotation Smoothness",
        Tooltip = "0 = Instant Lock | Higher = Smoother/Slower",
        Default = Config.autoRotateSmoothness,
        Min = 0, Max = 0.9, Rounding = 2,
        Callback = function(Value)
            Config.autoRotateSmoothness = Value
            Combat.setRotationSmoothness(Value)
        end
    })

    return CombatTab
end


----------------------------------------------------------
-- 🔹 ESP Tab
function UI.createESPTab()
    local ESPTab = UI.Window:AddTab("ESP", "eye")
    local ESPLeftGroup = ESPTab:AddLeftGroupbox("ESP")

    ESPLeftGroup:AddDivider()
    ESPLeftGroup:AddLabel("Zombie ESP")

    ESPLeftGroup:AddToggle("ESPZombie", {
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

    ESPLeftGroup:AddLabel("Zombie ESP Color"):AddColorPicker("ESPZombieColor", {
        Default = Config.espColorZombie,
        Title = "Zombie ESP Color",
        Callback = function(Value) Config.espColorZombie = Value end
    })

    ESPLeftGroup:AddToggle("ESPZombieBoxes", {
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

    ESPLeftGroup:AddToggle("ESPZombieTracers", {
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

    ESPLeftGroup:AddToggle("ESPZombieNames", {
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

    ESPLeftGroup:AddToggle("ESPZombieHealth", {
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

    ESPLeftGroup:AddToggle("ESPZombieHighlight", {
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

    ESPLeftGroup:AddDivider()
    ESPLeftGroup:AddLabel("Chest ESP")

    ESPLeftGroup:AddToggle("ESPChest", {
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

    ESPLeftGroup:AddLabel("Chest ESP Color"):AddColorPicker("ESPChestColor", {
        Default = Config.espColorChest,
        Title = "Chest ESP Color",
        Callback = function(Value)
            Config.espColorChest = Value
            ESP.refreshChestHighlights(Value)
        end
    })

    -- Right Groupbox
    local ESPRightGroup = ESPTab:AddRightGroupbox("Player ESP")

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


    return ESPTab
end

----------------------------------------------------------
-- 🔹 Movement Tab
function UI.createMovementTab()
    local MovementTab = UI.Window:AddTab("Movement", "move")
    local MovementLeftGroup = MovementTab:AddLeftGroupbox("Movement")

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

    MovementLeftGroup:AddToggle("NoClip", {
        Text = "NoClip",
        Default = Config.noClipEnabled,
        Callback = function(Value)
            Config.noClipEnabled = Value
            Movement.applyNoClip()
            if UI.Library then
                UI.Library:Notify({
                    Title = "Movement",
                    Description = Value and "NoClip enabled" or "NoClip disabled",
                    Time = 2
                })
            end
        end
    })

    MovementLeftGroup:AddToggle("AntiZombie", {
        Text = "Anti-Zombie",
        Default = Config.antiZombieEnabled,
        Callback = function(Value)
            Config.antiZombieEnabled = Value
            Movement.applyAntiZombie()
            if UI.Library then
                UI.Library:Notify({
                    Title = "Movement",
                    Description = Value and "Anti-Zombie enabled" or "Anti-Zombie disabled",
                    Time = 2
                })
            end
        end
    })

    MovementLeftGroup:AddSlider("HipHeight", {
        Text = "HipHeight",
        Default = Config.hipHeightValue,
        Min = 0, Max = 200, Rounding = 1,
        Callback = function(Value)
            Config.hipHeightValue = Value
            if Config.antiZombieEnabled then Movement.applyAntiZombie() end
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

    -- Right Groupbox
    local MovementRightGroup = MovementTab:AddRightGroupbox("Camera Teleport")

    MovementRightGroup:AddDivider()
    MovementRightGroup:AddLabel("Camera Teleport")

    MovementRightGroup:AddToggle("CameraTeleport", {
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

    MovementRightGroup:AddDropdown("CameraTargetMode", {
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

    MovementRightGroup:AddSlider("CameraTeleportWaveDelay", {
        Text = "Wave Wait Time (s)",
        Default = Config.cameraTeleportWaveDelay,
        Min = 0, Max = 15, Rounding = 0,
        Callback = function(Value) Config.cameraTeleportWaveDelay = Value end
    })

    MovementRightGroup:AddToggle("TeleportToLastZombie", {
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

    MovementRightGroup:AddDivider()
    MovementRightGroup:AddLabel("Camera Offset")

    MovementRightGroup:AddSlider("CameraOffsetX", {
        Text = "Camera Offset X",
        Default = Config.cameraOffsetX,
        Min = -360, Max = 360, Rounding = 1,
        Callback = function(Value) Config.cameraOffsetX = Value end
    })

    MovementRightGroup:AddSlider("CameraOffsetY", {
        Text = "Camera Offset Y",
        Default = Config.cameraOffsetY,
        Min = -360, Max = 360, Rounding = 1,
        Callback = function(Value) Config.cameraOffsetY = Value end
    })

    MovementRightGroup:AddSlider("CameraOffsetZ", {
        Text = "Camera Offset Z",
        Default = Config.cameraOffsetZ,
        Min = -360, Max = 360, Rounding = 1,
        Callback = function(Value) Config.cameraOffsetZ = Value end
    })

    return MovementTab
end


----------------------------------------------------------
-- 🔹 Map Tab
function UI.createMapTab()
    local MapTab = UI.Window:AddTab("Map", "map-pin")
    local MapGroup = MapTab:AddLeftGroupbox("Map")

    MapGroup:AddDivider()

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

    MapGroup:AddDropdown("MapWorld", {
        Text = "Map",
        Values = mapDisplayNames,
        Default = mapDisplayNames[1],
        Callback = function(Value)
            local id = mapIdByDisplay[Value]
            if id then Config.selectedWorldId = id end
        end
    })

    MapGroup:AddDropdown("MapDifficulty", {
        Text = "Difficulty",
        Values = {"1 - Normal", "2 - Hard", "3 - Nightmare"},
        Default = "1 - Normal",
        Callback = function(Value)
            local num = tonumber(string.match(Value, "^(%d+)"))
            if num then Config.selectedDifficulty = num end
        end
    })

    MapGroup:AddSlider("MapMaxCount", {
        Text = "Max Players",
        Default = Config.selectedMaxCount,
        Min = 1, Max = 4, Rounding = 0,
        Callback = function(Value) Config.selectedMaxCount = Value end
    })

    MapGroup:AddToggle("MapFriendOnly", {
        Text = "Friend Only",
        Default = Config.selectedFriendOnly,
        Callback = function(Value) Config.selectedFriendOnly = Value end
    })

    MapGroup:AddButton({
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

    MapGroup:AddButton({
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

    MapGroup:AddDivider()

    MapGroup:AddToggle("SupplyESP", {
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

    MapGroup:AddDropdown("SupplyESPPosition", {
        Text = "Supply Position",
        Values = {"Left", "Right"},
        Default = Config.supplyESPPosition,
        Callback = function(Value)
            Config.supplyESPPosition = Value
            Map.updateSupplyPosition()
        end
    })

    MapGroup:AddButton({
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

    MapGroup:AddDivider()

    MapGroup:AddToggle("AutoDoor", {
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

    return MapTab
end

----------------------------------------------------------
-- 🔹 Event Tab
function UI.createEventTab()
    local EventTab = UI.Window:AddTab("Event", "calendar")
    local EventGroup = EventTab:AddLeftGroupbox("Event")

    EventGroup:AddDivider()

    EventGroup:AddToggle("ESPBob", {
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

    EventGroup:AddLabel("Bob ESP Color"):AddColorPicker("ESPBobColor", {
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

    EventGroup:AddButton({
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

    EventGroup:AddDivider()

    EventGroup:AddToggle("AutoBuyChristmasGiftBox", {
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

    return EventTab
end

----------------------------------------------------------
-- 🔹 Farm Tab
function UI.createFarmTab()
    local FarmTab = UI.Window:AddTab("Farm", "package")
    local FarmGroup = FarmTab:AddLeftGroupbox("Farm")

    FarmGroup:AddToggle("AutoBulletBox", {
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

    FarmGroup:AddToggle("Teleport", {
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

    FarmGroup:AddDivider()
    FarmGroup:AddLabel("Potions - Common")

    FarmGroup:AddButton({
        Text = "Common Attack (Buy + Drink)",
        Func = function()
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
        end
    })

    FarmGroup:AddButton({
        Text = "Common Health (Buy + Drink)",
        Func = function()
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
        end
    })

    FarmGroup:AddButton({
        Text = "Common Luck (Buy + Drink)",
        Func = function()
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
        end
    })

    FarmGroup:AddDivider()
    FarmGroup:AddLabel("Potions - Rare")

    FarmGroup:AddButton({
        Text = "Rare Attack (Buy + Drink)",
        Func = function()
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
        end
    })

    FarmGroup:AddButton({
        Text = "Rare Health (Buy + Drink)",
        Func = function()
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
        end
    })

    FarmGroup:AddButton({
        Text = "Rare Luck (Buy + Drink)",
        Func = function()
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
        end
    })

    FarmGroup:AddDivider()
    FarmGroup:AddLabel("Codes")

    FarmGroup:AddButton({
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

    return FarmTab
end


----------------------------------------------------------
-- 🔹 Character Tab
function UI.createCharacterTab()
    local CharacterTab = UI.Window:AddTab("Character", "user")
    local CharacterGroup = CharacterTab:AddLeftGroupbox("Character")

    CharacterGroup:AddDivider()

    local displayList, displayToId = Character.getCharacterDisplayList()

    if not displayList or #displayList == 0 then
        displayList = {"Không đọc được dữ liệu (vào game trước đã)"}
        displayToId = {}
    end

    local function findIndex(list, value)
        for index, item in ipairs(list) do
            if item == value then
                return index
            end
        end
        return nil
    end

    local defaultDisplay = Config.selectedCharacterDisplay
    if not defaultDisplay or not findIndex(displayList, defaultDisplay) then
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
        end
    })

    CharacterGroup:AddDivider()

    -- Lấy character ID hiện tại để quyết định hiển thị skill nào
    local currentCharacterId = Character.getCurrentCharacterId()
    
    -- Create Auto Skill toggle with dynamic tooltip
    local autoSkillTooltip = "Automatically use the appropriate skill for the current character"
    if currentCharacterId == 1006 then
        autoSkillTooltip = "Automatically use Armsmaster Ultimate + Healing"
    elseif currentCharacterId == 1003 then
        autoSkillTooltip = "Automatically use Wraith Ultimate + Healing"
    elseif currentCharacterId == 1001 then
        autoSkillTooltip = "Automatically use Assault Ultimate + Grenade (E) + Healing"
    elseif currentCharacterId == 1004 then
        autoSkillTooltip = "Automatically use Flag Bearer Ultimate + Healing"
    elseif currentCharacterId == 1007 then
        autoSkillTooltip = "Automatically use Witch Ultimate + G Skill + Healing"
    elseif currentCharacterId then
        autoSkillTooltip = "Automatically use Healing (this character doesn't have a unique ultimate)"
    end

    CharacterGroup:AddToggle("AutoSkill", {
        Text = "Auto Skill",
        Tooltip = autoSkillTooltip,
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

    -- Healing Skill Toggle (bật/tắt Skill F)
    CharacterGroup:AddToggle("HealingSkillEnabled", {
        Text = "Enable F Skill (Healing)",
        Tooltip = "Toggle Skill F - All characters have this healing skill",
        Default = Config.healingSkillEnabled,
        Callback = function(Value)
            Config.healingSkillEnabled = Value
            if UI.Library then
                UI.Library:Notify({
                    Title = "Character",
                    Description = Value and "F Skill (Healing) enabled" or "F Skill (Healing) disabled",
                    Time = 2
                })
            end
        end
    })

    -- Healing Skill Interval (luôn hiển thị - character nào cũng có)
    CharacterGroup:AddSlider("HealingSkillInterval", {
        Text = "F Skill (Healing) Interval (s)",
        Tooltip = "Skill F - All characters have",
        Default = Config.healingSkillInterval,
        Min = 15, Max = 60, Rounding = 0,
        Callback = function(Value) Config.healingSkillInterval = Value end
    })

    -- Armsmaster Ultimate (only show when character = 1006)
    if currentCharacterId == 1006 then
        CharacterGroup:AddSlider("ArmsmasterUltimateInterval", {
            Text = "Armsmaster Ultimate Interval (s)",
            Default = Config.armsmasterUltimateInterval,
            Min = 15, Max = 60, Rounding = 0,
            Callback = function(Value) Config.armsmasterUltimateInterval = Value end
        })
    end

    -- Wraith Ultimate (chỉ hiển thị khi character = 1003)
    if currentCharacterId == 1003 then
        CharacterGroup:AddSlider("WraithUltimateInterval", {
            Text = "Wraith Ultimate Interval (s)",
            Default = Config.wraithUltimateInterval,
            Min = 0.3, Max = 20, Rounding = 1,
            Callback = function(Value) Config.wraithUltimateInterval = Value end
        })
    end

    -- Assault Ultimate (chỉ hiển thị khi character = 1001)
    if currentCharacterId == 1001 then
        CharacterGroup:AddToggle("AssaultUltimateEnabled", {
            Text = "Enable Ultimate (G)",
            Tooltip = "Toggle Assault Ultimate skill",
            Default = Config.assaultUltimateEnabled,
            Callback = function(Value)
                Config.assaultUltimateEnabled = Value
                if UI.Library then
                    UI.Library:Notify({
                        Title = "Character",
                        Description = Value and "Assault Ultimate enabled" or "Assault Ultimate disabled",
                        Time = 2
                    })
                end
            end
        })

        CharacterGroup:AddSlider("AssaultUltimateInterval", {
            Text = "Ultimate (G) Interval (s)",
            Default = Config.assaultUltimateInterval,
            Min = 0.3, Max = 20, Rounding = 1,
            Callback = function(Value) Config.assaultUltimateInterval = Value end
        })


    end

    -- Flag Bearer Ultimate (chỉ hiển thị khi character = 1004)
    if currentCharacterId == 1004 then
        CharacterGroup:AddSlider("FlagBearerUltimateInterval", {
            Text = "Flag Bearer Ultimate Interval (s)",
            Default = Config.flagBearerUltimateInterval,
            Min = 5, Max = 60, Rounding = 0,
            Callback = function(Value) Config.flagBearerUltimateInterval = Value end
        })
    end

    -- Witch (1007) - Ultimate + Skill G
    if currentCharacterId == 1007 then
        CharacterGroup:AddToggle("WitchUltimateEnabled", {
            Text = "Enable Witch Ultimate",
            Tooltip = "Toggle Witch Ultimate skill (1012)",
            Default = Config.witchUltimateEnabled,
            Callback = function(Value)
                Config.witchUltimateEnabled = Value
                if UI.Library then
                    UI.Library:Notify({
                        Title = "Character",
                        Description = Value and "Witch Ultimate enabled" or "Witch Ultimate disabled",
                        Time = 2
                    })
                end
            end
        })

        CharacterGroup:AddSlider("WitchUltimateInterval", {
            Text = "Witch Ultimate Interval (s)",
            Default = Config.witchUltimateInterval,
            Min = 15, Max = 60, Rounding = 0,
            Callback = function(Value) Config.witchUltimateInterval = Value end
        })

        CharacterGroup:AddToggle("WitchGSkillEnabled", {
            Text = "Enable Witch Skill (G)",
            Tooltip = "Toggle Witch Skill (G, 1013) - auto aims at nearest zombie",
            Default = Config.witchGSkillEnabled,
            Callback = function(Value)
                Config.witchGSkillEnabled = Value
                if UI.Library then
                    UI.Library:Notify({
                        Title = "Character",
                        Description = Value and "Witch Skill (G) enabled" or "Witch Skill (G) disabled",
                        Time = 2
                    })
                end
            end
        })

        CharacterGroup:AddSlider("WitchGSkillInterval", {
            Text = "Witch Skill (G) Interval (s)",
            Default = Config.witchGSkillInterval,
            Min = 0.5, Max = 20, Rounding = 1,
            Callback = function(Value) Config.witchGSkillInterval = Value end
        })
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
        Default = "R",
        Mode = "Toggle",
        Text = "Auto Rotate 360°",
        NoUI = false,
        Callback = function(Value)
            if Value then
                Config.autoRotateEnabled = not Config.autoRotateEnabled
                if Combat and Combat.toggleAutoRotate then
                    Combat.toggleAutoRotate(Config.autoRotateEnabled)
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

    KeybindsGroup:AddLabel("Anti-Zombie (Toggle)"):AddKeyPicker("AntiZombieKey", {
        Default = "M",
        Mode = "Toggle",
        Text = "Toggle Anti-Zombie",
        NoUI = false,
        Callback = function(Value)
            if Value then
                Config.antiZombieEnabled = not Config.antiZombieEnabled
                if Movement and Movement.applyAntiZombie then
                    Movement.applyAntiZombie()
                end
            end
        end
    })

    KeybindsGroup:AddLabel("Auto Chest (Press)"):AddKeyPicker("ChestTeleportKey", {
        Default = "T",
        Mode = "Press",
        Text = "Teleport to All Chests",
        NoUI = false,
        Callback = function()
            if Farm and Farm.teleportToAllChests then
                Farm.teleportToAllChests()
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
            
            if Options.AntiZombieKey then
                Options.AntiZombieKey:OnChanged(function()
                    Config.hipHeightToggleKey = Options.AntiZombieKey.Value
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
-- 🔹 Info Tab
function UI.createInfoTab()
    local InfoTab = UI.Window:AddTab("Info", "info")
    local InfoGroup = InfoTab:AddLeftGroupbox("Info")

    InfoGroup:AddLabel("Controls", true)
    InfoGroup:AddLabel([[
            Right Click - Activate Aimbot (if enabled)
            T Key - Auto Open All Chests  
            X Key - Camera Teleport to Zombies
            M Key - Toggle Anti-Zombie
            N Key - Toggle Noclip Cam
            R Key - Toggle Auto Rotate 360°
            Right Ctrl - Open/Close Menu
            
            Auto Rotate 360° - Camera tự xoay tới zombie gần nhất
            Supply ESP - Hiển thị bên trái màn hình
            Auto refresh mỗi 15 giây
]], true)

    InfoGroup:AddDivider()
    InfoGroup:AddLabel("Tips", true)
    InfoGroup:AddLabel([[
            • Combine Aimbot + Hitbox for maximum efficiency
            • Use ESP to track zombies through walls
            • ESP Player shows enemies through walls with boxes
            • Anti-Zombie keeps you safe from attacks
            • Auto Skill provides continuous damage
            • Camera Teleport is great for farming
            • Auto Chest collects all loot instantly
            • Aimbot targets both zombies and players
            • Auto Rotate 360° (R key) tự động nhắm zombie gần nhất
]], true)

    InfoGroup:AddDivider()
    InfoGroup:AddLabel("Cleanup", true)
    InfoGroup:AddLabel([[
            • End key - Unload script & cleanup everything
            • Right Ctrl - Toggle menu
            • Camera Teleport (X) tự tắt aimbot, tự bật lại khi kết thúc
]], true)

    InfoGroup:AddDivider()
    InfoGroup:AddLabel("Important", true)
    InfoGroup:AddLabel([[
            • Some features may not work in all games
            • Use responsibly to avoid detection
            • Adjust settings based on your playstyle
            • Disable features if experiencing lag
]], true)

    return InfoTab
end

----------------------------------------------------------
-- 🔹 HUD Customization Tab
function UI.createHUDTab()
    local HUDTab = UI.Window:AddTab("HUD Customize", "monitor")
    local HUDLeftGroup = HUDTab:AddLeftGroupbox("HUD Settings")

    HUDLeftGroup:AddToggle("CustomHUD", {
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

    HUDLeftGroup:AddToggle("ApplyToOtherPlayers", {
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

    HUDLeftGroup:AddDivider()
    HUDLeftGroup:AddLabel("Visibility Settings")

    HUDLeftGroup:AddToggle("TitleVisible", {
        Text = "Show Title",
        Default = true,
        Callback = function(Value)
            HUD.titleVisible = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDLeftGroup:AddToggle("PlayerNameVisible", {
        Text = "Show Player Name",
        Default = true,
        Callback = function(Value)
            HUD.playerNameVisible = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDLeftGroup:AddToggle("ClassVisible", {
        Text = "Show Class",
        Default = true,
        Callback = function(Value)
            HUD.classVisible = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDLeftGroup:AddToggle("LevelVisible", {
        Text = "Show Level",
        Default = true,
        Callback = function(Value)
            HUD.levelVisible = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDLeftGroup:AddDivider()
    HUDLeftGroup:AddLabel("EXP Display")

    HUDLeftGroup:AddToggle("ExpDisplay", {
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

    HUDLeftGroup:AddDivider()
    HUDLeftGroup:AddLabel("Text Customization")

    HUDLeftGroup:AddInput("CustomTitle", {
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

    HUDLeftGroup:AddInput("CustomPlayerName", {
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

    HUDLeftGroup:AddInput("CustomClass", {
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

    HUDLeftGroup:AddInput("CustomLevel", {
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

    HUDLeftGroup:AddDivider()
    HUDLeftGroup:AddLabel("Actions")

    HUDLeftGroup:AddButton({
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

    HUDLeftGroup:AddButton({
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

    -- Right Groupbox
    local HUDRightGroup = HUDTab:AddRightGroupbox("Gradient Colors")

    HUDRightGroup:AddDivider()
    HUDRightGroup:AddLabel("Title Gradient Colors")

    HUDRightGroup:AddLabel("Title Color 1"):AddColorPicker("TitleGradient1", {
        Default = Color3.fromRGB(255, 0, 0), -- Red
        Title = "Title Color 1",
        Callback = function(Value)
            HUD.titleGradientColor1 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDRightGroup:AddLabel("Title Color 2"):AddColorPicker("TitleGradient2", {
        Default = Color3.fromRGB(255, 255, 255), -- White
        Title = "Title Color 2",
        Callback = function(Value)
            HUD.titleGradientColor2 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDRightGroup:AddDivider()
    HUDRightGroup:AddLabel("Player Name Gradient Colors")

    HUDRightGroup:AddLabel("Name Color 1"):AddColorPicker("PlayerNameGradient1", {
        Default = HUD.playerNameGradientColor1 or Color3.fromRGB(255, 255, 255),
        Title = "Name Color 1",
        Callback = function(Value)
            HUD.playerNameGradientColor1 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDRightGroup:AddLabel("Name Color 2"):AddColorPicker("PlayerNameGradient2", {
        Default = HUD.playerNameGradientColor2 or Color3.fromRGB(255, 255, 255),
        Title = "Name Color 2",
        Callback = function(Value)
            HUD.playerNameGradientColor2 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDRightGroup:AddDivider()
    HUDRightGroup:AddLabel("Class Gradient Colors")

    HUDRightGroup:AddLabel("Class Color 1"):AddColorPicker("ClassGradient1", {
        Default = HUD.classGradientColor1 or Color3.fromRGB(255, 255, 255),
        Title = "Class Color 1",
        Callback = function(Value)
            HUD.classGradientColor1 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDRightGroup:AddLabel("Class Color 2"):AddColorPicker("ClassGradient2", {
        Default = HUD.classGradientColor2 or Color3.fromRGB(255, 255, 255),
        Title = "Class Color 2",
        Callback = function(Value)
            HUD.classGradientColor2 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDRightGroup:AddDivider()
    HUDRightGroup:AddLabel("Level Gradient Colors")

    HUDRightGroup:AddLabel("Level Color 1"):AddColorPicker("LevelGradient1", {
        Default = HUD.levelGradientColor1 or Color3.fromRGB(255, 255, 255),
        Title = "Level Color 1",
        Callback = function(Value)
            HUD.levelGradientColor1 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDRightGroup:AddLabel("Level Color 2"):AddColorPicker("LevelGradient2", {
        Default = HUD.levelGradientColor2 or Color3.fromRGB(255, 255, 255),
        Title = "Level Color 2",
        Callback = function(Value)
            HUD.levelGradientColor2 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    return HUDTab
end



----------------------------------------------------------
-- 🔹 Visuals Tab
function UI.createVisualsTab()
    local VisualsTab = UI.Window:AddTab("Visuals", "eye")
    local VisualsLeftGroup = VisualsTab:AddLeftGroupbox("Visuals")

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

    return VisualsTab
end

----------------------------------------------------------
-- 🔹 Build All Tabs
function UI.buildAllTabs(cleanupCallback)
    UI.createCombatTab()
    UI.createESPTab()
    UI.createMovementTab()
    UI.createMapTab()
    UI.createEventTab()
    UI.createFarmTab()
    UI.createCharacterTab()
    UI.createVisualsTab()
    UI.createHUDTab()
    UI.createSettingsTab(cleanupCallback)
    UI.createInfoTab()
    
    -- Setup OnUnload callback for Obsidian UI
    if UI.Library and cleanupCallback then
        UI.Library:OnUnload(function()
            cleanupCallback()
        end)
    end
end

----------------------------------------------------------
-- 🔹 Cleanup
function UI.cleanup()
    if UI.Window and UI.Window.Destroy then
        pcall(function() UI.Window:Destroy() end)
    end
end

return UI
