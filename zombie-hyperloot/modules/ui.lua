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

    MovementTab:AddSection("Camera Offset")

    MovementTab:AddSlider("CameraOffsetX", {
        Title = "Camera Offset X",
        Default = Config.cameraOffsetX,
        Min = -20, Max = 20, Rounding = 1,
        Callback = function(Value) Config.cameraOffsetX = Value end
    })

    MovementTab:AddSlider("CameraOffsetY", {
        Title = "Camera Offset Y",
        Default = Config.cameraOffsetY,
        Min = 0, Max = 50, Rounding = 1,
        Callback = function(Value) Config.cameraOffsetY = Value end
    })

    MovementTab:AddSlider("CameraOffsetZ", {
        Title = "Camera Offset Z",
        Default = Config.cameraOffsetZ,
        Min = -20, Max = 20, Rounding = 1,
        Callback = function(Value) Config.cameraOffsetZ = Value end
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

    MapTab:AddToggle("AutoReplay", {
        Title = "Auto Replay Match",
        Description = "Tự động replay khi kết thúc trận",
        Default = Config.autoReplayEnabled,
        Callback = function(Value) Config.autoReplayEnabled = Value end
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
            N Key - Toggle Noclip Cam
            Right Shift - Open/Close Menu
        ]]
    })

    InfoTab:AddParagraph({
        Title = "Tips",
        Content = [[
            • Combine Aimbot + Hitbox for maximum efficiency
            • Use ESP to track zombies through walls
            • ESP Player shows enemies through walls with boxes
            • Anti-Zombie keeps you safe from attacks
            • Auto Skill provides continuous damage
            • Camera Teleport is great for farming
            • Auto Chest collects all loot instantly
            • Aimbot targets both zombies and players
        ]]
    })

    InfoTab:AddParagraph({
        Title = "Cleanup",
        Content = [[
            • End key - Unload script & cleanup everything
            • Right Shift - Toggle menu
            • Camera Teleport (X) tự tắt aimbot, tự bật lại khi kết thúc
        ]]
    })

    InfoTab:AddParagraph({
        Title = "Important",
        Content = [[
            • Some features may not work in all games
            • Use responsibly to avoid detection
            • Adjust settings based on your playstyle
            • Disable features if experiencing lag
        ]]
    })

    return InfoTab
end

----------------------------------------------------------
-- 🔹 Quick Teleport Buttons (2 cột: Exit Door | Ammo/Supply)
-- Load 1 lần khi vào map, tự động cập nhật khi có item mới
UI.quickTeleportGui = nil
UI.mapWatcherConnection = nil
UI.supplyButtons = {}
UI.ammoButtons = {}

function UI.createQuickTeleportButtons()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "QuickTeleportButtons"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = Config.localPlayer:WaitForChild("PlayerGui")

    -- Main container chứa 2 cột (nhỏ hơn)
    local MainContainer = Instance.new("Frame")
    MainContainer.Name = "MainContainer"
    MainContainer.BackgroundTransparency = 1
    MainContainer.Size = UDim2.new(0, 170, 0, 200)
    MainContainer.Position = UDim2.new(1, -180, 0.5, -100)
    MainContainer.Parent = ScreenGui

    -- Cột trái (Exit Door + Task)
    local LeftColumn = Instance.new("Frame")
    LeftColumn.Name = "LeftColumn"
    LeftColumn.BackgroundTransparency = 1
    LeftColumn.Size = UDim2.new(0, 80, 1, 0)
    LeftColumn.Position = UDim2.new(0, 0, 0, 0)
    LeftColumn.Parent = MainContainer

    local LeftLayout = Instance.new("UIListLayout")
    LeftLayout.Padding = UDim.new(0, 2)
    LeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
    LeftLayout.Parent = LeftColumn

    local LeftPadding = Instance.new("UIPadding")
    LeftPadding.PaddingTop = UDim.new(0, 2)
    LeftPadding.Parent = LeftColumn

    -- Cột phải (Supply + Ammo)
    local RightColumn = Instance.new("Frame")
    RightColumn.Name = "RightColumn"
    RightColumn.BackgroundTransparency = 1
    RightColumn.Size = UDim2.new(0, 80, 1, 0)
    RightColumn.Position = UDim2.new(0, 85, 0, 0)
    RightColumn.Parent = MainContainer

    local RightLayout = Instance.new("UIListLayout")
    RightLayout.Padding = UDim.new(0, 2)
    RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
    RightLayout.Parent = RightColumn

    local RightPadding = Instance.new("UIPadding")
    RightPadding.PaddingTop = UDim.new(0, 2)
    RightPadding.Parent = RightColumn

    -- Helper tạo button
    local function createBtn(name, text, color, order, parent, position)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(0, 75, 0, 22)
        btn.BackgroundColor3 = color
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamBold
        btn.AutoButtonColor = false
        btn.LayoutOrder = order
        btn.Parent = parent
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn
        
        local hoverColor = color:Lerp(Color3.fromRGB(255, 255, 255), 0.35)
        btn.MouseEnter:Connect(function() btn.BackgroundColor3 = hoverColor end)
        btn.MouseLeave:Connect(function() btn.BackgroundColor3 = color end)
        
        -- Lưu vị trí vào button
        btn:SetAttribute("TargetX", position.X)
        btn:SetAttribute("TargetY", position.Y)
        btn:SetAttribute("TargetZ", position.Z)
        
        btn.MouseButton1Click:Connect(function()
            local pos = Vector3.new(
                btn:GetAttribute("TargetX"),
                btn:GetAttribute("TargetY"),
                btn:GetAttribute("TargetZ")
            )
            Map.teleportToPosition(pos)
        end)
        
        return btn
    end

    local leftOrder = 1
    local rightOrder = 1

    -- === TÌM VÀ TẠO NÚT EXIT DOOR ===
    local exitDoors = Map.findAllExitDoors()
    for i, pos in ipairs(exitDoors) do
        createBtn("Exit" .. i, "🚪 Exit " .. i, Color3.fromRGB(155, 89, 182), leftOrder, LeftColumn, pos)
        leftOrder = leftOrder + 1
    end
    
    -- === TÌM VÀ TẠO NÚT TASK ===
    local taskPos = Map.findTaskPosition()
    if taskPos then
        createBtn("Task", "📍 Task", Color3.fromRGB(52, 152, 219), leftOrder, LeftColumn, taskPos)
        leftOrder = leftOrder + 1
    end

    -- === TÌM VÀ TẠO NÚT SUPPLY ===
    local supplies = Map.findAllSupplyPiles()
    for i, pos in ipairs(supplies) do
        local btn = createBtn("Sup" .. i, "📦 Sup " .. i, Color3.fromRGB(241, 196, 15), rightOrder, RightColumn, pos)
        UI.supplyButtons[i] = btn
        rightOrder = rightOrder + 1
    end
    
    -- === TÌM VÀ TẠO NÚT AMMO ===
    local ammos = Map.findAllAmmo()
    for i, pos in ipairs(ammos) do
        local btn = createBtn("Ammo" .. i, "🔫 Ammo " .. i, Color3.fromRGB(230, 126, 34), rightOrder, RightColumn, pos)
        UI.ammoButtons[i] = btn
        rightOrder = rightOrder + 1
    end

    -- Hàm cập nhật vị trí Supply/Ammo
    local function updateSupplyAmmoPositions()
        -- Update Supply
        local newSupplies = Map.findAllSupplyPiles()
        for i, btn in pairs(UI.supplyButtons) do
            if newSupplies[i] then
                btn:SetAttribute("TargetX", newSupplies[i].X)
                btn:SetAttribute("TargetY", newSupplies[i].Y)
                btn:SetAttribute("TargetZ", newSupplies[i].Z)
            end
        end
        
        -- Update Ammo
        local newAmmos = Map.findAllAmmo()
        for i, btn in pairs(UI.ammoButtons) do
            if newAmmos[i] then
                btn:SetAttribute("TargetX", newAmmos[i].X)
                btn:SetAttribute("TargetY", newAmmos[i].Y)
                btn:SetAttribute("TargetZ", newAmmos[i].Z)
            end
        end
    end

    -- Lắng nghe Map thay đổi để cập nhật vị trí
    local map = Config.Workspace:FindFirstChild("Map")
    if map then
        UI.mapWatcherConnection = map.DescendantAdded:Connect(function(descendant)
            if Config.scriptUnloaded then return end
            -- Chỉ cập nhật khi có Ammo hoặc Supply spawn
            if descendant.Name == "Ammo" or tonumber(descendant.Name) then
                task.wait(0.5) -- Đợi object load xong
                updateSupplyAmmoPositions()
            end
        end)
    end

    -- Cập nhật kích thước container
    local leftCount = leftOrder - 1
    local rightCount = rightOrder - 1
    local maxCount = math.max(leftCount, rightCount, 1)
    local containerHeight = maxCount * 24 + 8
    MainContainer.Size = UDim2.new(0, 170, 0, containerHeight)
    MainContainer.Position = UDim2.new(1, -180, 0.5, -containerHeight / 2)

    UI.quickTeleportGui = ScreenGui
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
    
    -- Disconnect map watcher
    if UI.mapWatcherConnection then
        pcall(function() UI.mapWatcherConnection:Disconnect() end)
        UI.mapWatcherConnection = nil
    end
    
    -- Clear button references
    UI.supplyButtons = {}
    UI.ammoButtons = {}
    
    -- Xóa quick teleport buttons
    if UI.quickTeleportGui then
        pcall(function() UI.quickTeleportGui:Destroy() end)
        UI.quickTeleportGui = nil
    end
    
    local playerGui = Config.localPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        local quickGui = playerGui:FindFirstChild("QuickTeleportButtons")
        if quickGui then quickGui:Destroy() end
    end
end

return UI
