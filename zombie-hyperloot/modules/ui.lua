--[[
    UI Module - Zombie Hyperloot
    Fluent UI setup + tất cả tabs
]]

local UI = {}
local Config, Combat, ESP, Movement, Map, Farm = nil, nil, nil, nil, nil, nil

UI.Window = nil
UI.Fluent = nil
UI.SaveManager = nil
UI.InterfaceManager = nil

function UI.init(config, combat, esp, movement, map, farm)
    Config = config
    Combat = combat
    ESP = esp
    Movement = movement
    Map = map
    Farm = farm
end

function UI.loadLibraries()
    UI.Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    UI.SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
    UI.InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
end

function UI.createWindow()
    UI.Window = UI.Fluent:CreateWindow({
        Title = "Zombie Hyperloot",
        SubTitle = "by WiniFy",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = false,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.RightShift
    })
end

----------------------------------------------------------
-- 🔹 Combat Tab
function UI.createCombatTab()
    local CombatTab = UI.Window:AddTab({ Title = "Combat" })

    CombatTab:AddToggle("Aimbot", {
        Title = "Aimbot",
        Default = Config.aimbotEnabled,
        Callback = function(Value) Config.aimbotEnabled = Value end
    })

    CombatTab:AddSection("Aimbot Settings")

    CombatTab:AddDropdown("AimbotTargetMode", {
        Title = "Target Mode",
        Values = {"Zombies", "Players", "All"},
        Default = Config.aimbotTargetMode,
        Callback = function(Value) Config.aimbotTargetMode = Value end
    })

    CombatTab:AddDropdown("AimbotAimPart", {
        Title = "Aim Part",
        Values = {"Head", "UpperTorso", "HumanoidRootPart"},
        Default = Config.aimbotAimPart,
        Callback = function(Value) Config.aimbotAimPart = Value end
    })

    CombatTab:AddToggle("AimbotHoldMouse2", {
        Title = "Hold Right Click",
        Default = Config.aimbotHoldMouse2,
        Callback = function(Value) Config.aimbotHoldMouse2 = Value end
    })

    CombatTab:AddToggle("AimbotFOV", {
        Title = "FOV Circle",
        Default = Config.aimbotFOVEnabled,
        Callback = function(Value) Config.aimbotFOVEnabled = Value end
    })

    CombatTab:AddSlider("AimbotFOVRadius", {
        Title = "FOV Radius",
        Default = Config.aimbotFOVRadius,
        Min = 50, Max = 500, Rounding = 0,
        Callback = function(Value) Config.aimbotFOVRadius = Value end
    })

    CombatTab:AddSlider("AimbotSmoothness", {
        Title = "Smoothness",
        Default = Config.aimbotSmoothness,
        Min = 0, Max = 1, Rounding = 2,
        Callback = function(Value) Config.aimbotSmoothness = Value end
    })

    CombatTab:AddSlider("AimbotPrediction", {
        Title = "Prediction",
        Default = Config.aimbotPrediction,
        Min = 0, Max = 0.2, Rounding = 3,
        Callback = function(Value) Config.aimbotPrediction = Value end
    })

    CombatTab:AddSection("Hitbox Settings")

    CombatTab:AddToggle("Hitbox", {
        Title = "Hitbox Expander",
        Default = Config.hitboxEnabled,
        Callback = function(Value)
            Config.hitboxEnabled = Value
            Combat.updateAllHitboxes(Value)
        end
    })

    CombatTab:AddSlider("HitboxSize", {
        Title = "Hitbox Size",
        Default = 4, Min = 1, Max = 20, Rounding = 1,
        Callback = function(Value)
            Config.hitboxSize = Vector3.new(Value, Value, Value)
        end
    })

    CombatTab:AddSection("TrigerSkill Dupe")

    CombatTab:AddToggle("TrigerSkillDupeEnabled", {
        Title = "Enable TrigerSkill Dupe",
        Default = Config.trigerSkillDupeEnabled,
        Callback = function(Value) Config.trigerSkillDupeEnabled = Value end
    })

    CombatTab:AddSlider("TrigerSkillDupeCount", {
        Title = "Dupe Count",
        Default = Config.trigerSkillDupeCount,
        Min = 1, Max = 20, Rounding = 0,
        Callback = function(Value) Config.trigerSkillDupeCount = Value end
    })

    CombatTab:AddSection("Auto Skill")

    CombatTab:AddToggle("AutoSkill", {
        Title = "Auto Skill",
        Default = Config.autoSkillEnabled,
        Callback = function(Value)
            Config.autoSkillEnabled = Value
            if Value then
                task.spawn(function()
                    task.wait(1)
                    Combat.activateSkill1010()
                    task.wait(0.5)
                    Combat.activateSkill1002()
                end)
            end
        end
    })

    CombatTab:AddSlider("Skill1010Interval", {
        Title = "Skill 1010 Interval (s)",
        Default = Config.skill1010Interval,
        Min = 1, Max = 60, Rounding = 1,
        Callback = function(Value) Config.skill1010Interval = Value end
    })

    CombatTab:AddSlider("Skill1002Interval", {
        Title = "Skill 1002 Interval (s)",
        Default = Config.skill1002Interval,
        Min = 1, Max = 60, Rounding = 1,
        Callback = function(Value) Config.skill1002Interval = Value end
    })

    return CombatTab
end


----------------------------------------------------------
-- 🔹 ESP Tab
function UI.createESPTab()
    local ESPTab = UI.Window:AddTab({ Title = "ESP" })

    ESPTab:AddSection("Zombie ESP")

    ESPTab:AddToggle("ESPZombie", {
        Title = "ESP Zombie",
        Default = Config.espZombieEnabled,
        Callback = function(Value)
            Config.espZombieEnabled = Value
            if not Value then
                ESP.clearZombieESP()
                for _, data in pairs(ESP.zombieESPObjects) do
                    ESP.hideZombieESP(data)
                end
            end
        end
    })

    ESPTab:AddColorpicker("ESPZombieColor", {
        Title = "Zombie ESP Color",
        Default = Config.espColorZombie,
        Callback = function(Value) Config.espColorZombie = Value end
    })

    ESPTab:AddToggle("ESPZombieBoxes", {
        Title = "Zombie Boxes",
        Default = Config.espZombieBoxes,
        Callback = function(Value) Config.espZombieBoxes = Value end
    })

    ESPTab:AddToggle("ESPZombieTracers", {
        Title = "Zombie Tracers",
        Default = Config.espZombieTracers,
        Callback = function(Value) Config.espZombieTracers = Value end
    })

    ESPTab:AddToggle("ESPZombieNames", {
        Title = "Zombie Names",
        Default = Config.espZombieNames,
        Callback = function(Value) Config.espZombieNames = Value end
    })

    ESPTab:AddToggle("ESPZombieHealth", {
        Title = "Zombie Health Bars",
        Default = Config.espZombieHealth,
        Callback = function(Value) Config.espZombieHealth = Value end
    })

    ESPTab:AddSection("Chest ESP")

    ESPTab:AddToggle("ESPChest", {
        Title = "ESP Chest",
        Default = Config.espChestEnabled,
        Callback = function(Value)
            Config.espChestEnabled = Value
            if Value then ESP.applyChestESP() else ESP.clearChestESP() end
        end
    })

    ESPTab:AddColorpicker("ESPChestColor", {
        Title = "Chest ESP Color",
        Default = Config.espColorChest,
        Callback = function(Value)
            Config.espColorChest = Value
            ESP.refreshChestHighlights(Value)
        end
    })

    ESPTab:AddSection("Player ESP")

    ESPTab:AddToggle("ESPPlayer", {
        Title = "ESP Player",
        Default = Config.espPlayerEnabled,
        Callback = function(Value)
            Config.espPlayerEnabled = Value
            if not Value then
                for _, data in pairs(ESP.playerESPObjects) do
                    ESP.hidePlayerESP(data)
                end
            end
        end
    })

    ESPTab:AddColorpicker("ESPPlayerColor", {
        Title = "Player ESP Color",
        Default = Config.espColorPlayer,
        Callback = function(Value) Config.espColorPlayer = Value end
    })

    ESPTab:AddColorpicker("ESPEnemyColor", {
        Title = "Enemy ESP Color",
        Default = Config.espColorEnemy,
        Callback = function(Value) Config.espColorEnemy = Value end
    })

    ESPTab:AddToggle("ESPPlayerBoxes", {
        Title = "Player Boxes",
        Default = Config.espPlayerBoxes,
        Callback = function(Value) Config.espPlayerBoxes = Value end
    })

    ESPTab:AddToggle("ESPPlayerTracers", {
        Title = "Player Tracers",
        Default = Config.espPlayerTracers,
        Callback = function(Value) Config.espPlayerTracers = Value end
    })

    ESPTab:AddToggle("ESPPlayerNames", {
        Title = "Player Names",
        Default = Config.espPlayerNames,
        Callback = function(Value) Config.espPlayerNames = Value end
    })

    ESPTab:AddToggle("ESPPlayerHealth", {
        Title = "Player Health Bars",
        Default = Config.espPlayerHealth,
        Callback = function(Value) Config.espPlayerHealth = Value end
    })

    ESPTab:AddToggle("ESPPlayerTeamCheck", {
        Title = "Team Check",
        Default = Config.espPlayerTeamCheck,
        Callback = function(Value) Config.espPlayerTeamCheck = Value end
    })

    return ESPTab
end

----------------------------------------------------------
-- 🔹 Movement Tab
function UI.createMovementTab()
    local MovementTab = UI.Window:AddTab({ Title = "Movement" })

    MovementTab:AddToggle("Speed", {
        Title = "Speed Boost",
        Default = Config.speedEnabled,
        Callback = function(Value)
            Config.speedEnabled = Value
            Movement.applySpeed()
        end
    })

    MovementTab:AddSlider("SpeedValue", {
        Title = "Speed Bonus",
        Default = Config.speedValue,
        Min = 1, Max = 100, Rounding = 1,
        Callback = function(Value)
            Config.speedValue = Value
            if Config.speedEnabled then Movement.applySpeed() end
        end
    })

    MovementTab:AddToggle("NoClip", {
        Title = "NoClip",
        Default = Config.noClipEnabled,
        Callback = function(Value)
            Config.noClipEnabled = Value
            Movement.applyNoClip()
        end
    })

    MovementTab:AddToggle("AntiZombie", {
        Title = "Anti-Zombie",
        Default = Config.antiZombieEnabled,
        Callback = function(Value)
            Config.antiZombieEnabled = Value
            Movement.applyAntiZombie()
        end
    })

    MovementTab:AddSlider("HipHeight", {
        Title = "HipHeight",
        Default = Config.hipHeightValue,
        Min = 0, Max = 200, Rounding = 1,
        Callback = function(Value)
            Config.hipHeightValue = Value
            if Config.antiZombieEnabled then Movement.applyAntiZombie() end
        end
    })

    MovementTab:AddToggle("NoclipCam", {
        Title = "Noclip Cam",
        Default = Config.noclipCamEnabled,
        Callback = function(Value)
            Config.noclipCamEnabled = Value
            Movement.applyNoclipCam()
        end
    })

    MovementTab:AddSection("Camera Teleport")

    MovementTab:AddToggle("CameraTeleport", {
        Title = "Camera Teleport (X)",
        Default = Config.cameraTeleportEnabled,
        Callback = function(Value) Config.cameraTeleportEnabled = Value end
    })

    MovementTab:AddDropdown("CameraTargetMode", {
        Title = "Target Mode",
        Values = {"LowestHealth", "Nearest"},
        Default = Config.cameraTargetMode,
        Callback = function(Value) Config.cameraTargetMode = Value end
    })

    MovementTab:AddSlider("CameraTeleportWaveDelay", {
        Title = "Wave Wait Time (s)",
        Default = Config.cameraTeleportWaveDelay,
        Min = 0, Max = 15, Rounding = 0,
        Callback = function(Value) Config.cameraTeleportWaveDelay = Value end
    })

    MovementTab:AddToggle("TeleportToLastZombie", {
        Title = "Teleport to Last Zombie",
        Default = Config.teleportToLastZombie,
        Callback = function(Value) Config.teleportToLastZombie = Value end
    })

    return MovementTab
end


----------------------------------------------------------
-- 🔹 Map Tab
function UI.createMapTab()
    local MapTab = UI.Window:AddTab({ Title = "Map" })

    MapTab:AddSection("Auto Map Teleport")

    local mapDisplayNames = {
        "Exclusion [1001]",
        "Virus Laboratory [1002]",
        "Biology Laboratory [1003]",
        "Wave Mode [102]",
        "Raid Mode [201]",
    }

    local mapIdByDisplay = {
        ["Exclusion [1001]"] = 1001,
        ["Virus Laboratory [1002]"] = 1002,
        ["Biology Laboratory [1003]"] = 1003,
        ["Wave Mode [102]"] = 102,
        ["Raid Mode [201]"] = 201,
    }

    MapTab:AddDropdown("MapWorld", {
        Title = "Map",
        Values = mapDisplayNames,
        Default = mapDisplayNames[1],
        Callback = function(Value)
            local id = mapIdByDisplay[Value]
            if id then Config.selectedWorldId = id end
        end
    })

    MapTab:AddDropdown("MapDifficulty", {
        Title = "Difficulty",
        Values = {"1 - Normal", "2 - Hard", "3 - Nightmare"},
        Default = "1 - Normal",
        Callback = function(Value)
            local num = tonumber(string.match(Value, "^(%d+)"))
            if num then Config.selectedDifficulty = num end
        end
    })

    MapTab:AddSlider("MapMaxCount", {
        Title = "Max Players",
        Default = Config.selectedMaxCount,
        Min = 1, Max = 4, Rounding = 0,
        Callback = function(Value) Config.selectedMaxCount = Value end
    })

    MapTab:AddToggle("MapFriendOnly", {
        Title = "Friend Only",
        Default = Config.selectedFriendOnly,
        Callback = function(Value) Config.selectedFriendOnly = Value end
    })

    MapTab:AddButton({
        Title = "Teleport & Start Map",
        Callback = function() Map.teleportToWaitAreaAndStart() end
    })

    MapTab:AddButton({
        Title = "Replay Match",
        Callback = function() Map.replayCurrentMatch() end
    })

    return MapTab
end

----------------------------------------------------------
-- 🔹 Farm Tab
function UI.createFarmTab()
    local FarmTab = UI.Window:AddTab({ Title = "Farm" })

    FarmTab:AddToggle("AutoBulletBox", {
        Title = "Auto BulletBox + Items",
        Default = Config.autoBulletBoxEnabled,
        Callback = function(Value) Config.autoBulletBoxEnabled = Value end
    })

    FarmTab:AddToggle("Teleport", {
        Title = "Auto Chest (T Key)",
        Default = Config.teleportEnabled,
        Callback = function(Value) Config.teleportEnabled = Value end
    })

    return FarmTab
end

----------------------------------------------------------
-- 🔹 Settings Tab
function UI.createSettingsTab(cleanupCallback)
    local SettingsTab = UI.Window:AddTab({ Title = "Settings" })

    SettingsTab:AddSection("Reset Script")

    SettingsTab:AddButton({
        Title = "Unload Script",
        Description = "Unload toàn bộ script và xóa GUI",
        Callback = function()
            if cleanupCallback then cleanupCallback() end
        end
    })

    -- Config Save / Load
    UI.SaveManager:SetLibrary(UI.Fluent)
    UI.InterfaceManager:SetLibrary(UI.Fluent)
    UI.SaveManager:IgnoreThemeSettings()
    UI.SaveManager:SetIgnoreIndexes({})
    UI.InterfaceManager:SetFolder("ZombieHyperloot")
    UI.SaveManager:SetFolder("ZombieHyperloot/Configs")
    UI.InterfaceManager:BuildInterfaceSection(SettingsTab)
    UI.SaveManager:BuildConfigSection(SettingsTab)
    UI.SaveManager:LoadAutoloadConfig()

    return SettingsTab
end

----------------------------------------------------------
-- 🔹 Info Tab
function UI.createInfoTab()
    local InfoTab = UI.Window:AddTab({ Title = "Info" })

    InfoTab:AddParagraph({
        Title = "Controls",
        Content = [[
            Right Click - Activate Aimbot (if enabled)
            T Key - Auto Open All Chests  
            X Key - Camera Teleport to Zombies
            M Key - Toggle Anti-Zombie
            Right Shift - Open/Close Menu
        ]]
    })

    InfoTab:AddParagraph({
        Title = "Tips",
        Content = [[
            • Combine Aimbot + Hitbox for maximum efficiency
            • Use ESP to track zombies through walls
            • Anti-Zombie keeps you safe from attacks
            • Auto Skill provides continuous damage
            • Camera Teleport is great for farming
        ]]
    })

    return InfoTab
end

----------------------------------------------------------
-- 🔹 Quick Teleport Buttons
function UI.createQuickTeleportButtons()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "QuickTeleportButtons"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = Config.localPlayer:WaitForChild("PlayerGui")

    local Container = Instance.new("Frame")
    Container.Name = "Container"
    Container.BackgroundTransparency = 1
    Container.Size = UDim2.new(0, 170, 0, 200)
    Container.Position = UDim2.new(1, -190, 0.5, -100)
    Container.Parent = ScreenGui

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Padding = UDim.new(0, 5)
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = Container

    local UIPadding = Instance.new("UIPadding")
    UIPadding.PaddingTop = UDim.new(0, 10)
    UIPadding.PaddingRight = UDim.new(0, 10)
    UIPadding.Parent = Container

    local function createButton(name, text, color, callback)
        local button = Instance.new("TextButton")
        button.Name = name
        button.Size = UDim2.new(0, 150, 0, 34)
        button.BackgroundColor3 = color
        button.BorderSizePixel = 0
        button.Text = text
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 16
        button.Font = Enum.Font.GothamBold
        button.AutoButtonColor = false
        button.Parent = Container
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = button
        
        local hoverColor = color:Lerp(Color3.fromRGB(255, 255, 255), 0.35)
        button.MouseEnter:Connect(function() button.BackgroundColor3 = hoverColor end)
        button.MouseLeave:Connect(function() button.BackgroundColor3 = color end)
        button.MouseButton1Click:Connect(callback)
        
        return button
    end

    -- Task Button
    createButton("TaskBtn", "📍 Task", Color3.fromRGB(100, 150, 255), function()
        local pos = Map.findTaskPosition()
        if pos then
            local char = Config.localPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = CFrame.new(pos) end
        end
    end)

    -- Exit Door Button
    createButton("ExitBtn", "🚪 Exit Door", Color3.fromRGB(255, 100, 100), function()
        local doors = Map.findAllExitDoors()
        if #doors > 0 then
            local char = Config.localPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = CFrame.new(doors[1]) end
        end
    end)

    -- Supply Button
    createButton("SupplyBtn", "📦 Supply", Color3.fromRGB(100, 255, 100), function()
        local supplies = Map.findAllSupplyPiles()
        if #supplies > 0 then
            local char = Config.localPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = CFrame.new(supplies[1]) end
        end
    end)

    return ScreenGui
end

----------------------------------------------------------
-- 🔹 Build All Tabs
function UI.buildAllTabs(cleanupCallback)
    UI.createCombatTab()
    UI.createESPTab()
    UI.createMovementTab()
    UI.createMapTab()
    UI.createFarmTab()
    UI.createSettingsTab(cleanupCallback)
    UI.createInfoTab()
    UI.Window:SelectTab(1)
end

----------------------------------------------------------
-- 🔹 Cleanup
function UI.cleanup()
    if UI.Window and UI.Window.Destroy then
        pcall(function() UI.Window:Destroy() end)
    end
    
    local playerGui = Config.localPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        local quickGui = playerGui:FindFirstChild("QuickTeleportButtons")
        if quickGui then quickGui:Destroy() end
    end
end

return UI
