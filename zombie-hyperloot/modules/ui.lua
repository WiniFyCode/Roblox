--[[
    UI Module - Zombie Hyperloot
    Fluent UI setup + tất cả tabs
]]

local UI = {}
local Config, Combat, ESP, Movement, Map, Farm, HUD, Visuals = nil, nil, nil, nil, nil, nil, nil, nil

UI.Window = nil
UI.Fluent = nil
UI.SaveManager = nil
UI.InterfaceManager = nil

function UI.init(config, combat, esp, movement, map, farm, hud, visuals)
    Config = config
    Combat = combat
    ESP = esp
    Movement = movement
    Map = map
    Farm = farm
    HUD = hud
    Visuals = visuals
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
        MinimizeKey = Enum.KeyCode.RightControl
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
        Title = "Target Type",
        Values = {"Zombies", "Players", "All"},
        Default = Config.aimbotTargetMode,
        Callback = function(Value) Config.aimbotTargetMode = Value end
    })

    CombatTab:AddDropdown("AimbotPriorityMode", {
        Title = "Priority",
        Values = {"Nearest", "Farthest", "LowestHealth", "HighestHealth"},
        Default = Config.aimbotPriorityMode,
        Callback = function(Value) Config.aimbotPriorityMode = Value end
    })

    CombatTab:AddDropdown("AimbotAimPart", {
        Title = "Aim Part",
        Values = {"Head", "UpperTorso", "HumanoidRootPart", "Random"},
        Default = Config.aimbotAimPart,
        Callback = function(Value) Config.aimbotAimPart = Value end
    })

    CombatTab:AddToggle("AimbotHoldMouse2", {
        Title = "Hold Right Click",
        Default = Config.aimbotHoldMouse2,
        Callback = function(Value) Config.aimbotHoldMouse2 = Value end
    })

    CombatTab:AddToggle("AimbotAutoFire", {
        Title = "Auto Fire (Mouse1)",
        Default = Config.aimbotAutoFireEnabled,
        Callback = function(Value)
            Config.aimbotAutoFireEnabled = Value
            if not Value and Combat.setAutoFireActive then
                Combat.setAutoFireActive(false)
            end
        end
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

    CombatTab:AddToggle("AimbotWallCheck", {
        Title = "Wall Check (Decoration)",
        Default = Config.aimbotWallCheckEnabled,
        Callback = function(Value) Config.aimbotWallCheckEnabled = Value end
    })

    CombatTab:AddSlider("AimbotSmoothness", {
        Title = "Smoothness",
        Description = "0 = Instant Lock | Higher = Smoother/Slower",
        Default = Config.aimbotSmoothness,
        Min = 0, Max = 0.9, Rounding = 2,
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
        Min = 10, Max = 60, Rounding = 0,
        Callback = function(Value) Config.skill1010Interval = Value end
    })

    CombatTab:AddSlider("Skill1002Interval", {
        Title = "Skill 1002 Interval (s)",
        Default = Config.skill1002Interval,
        Min = 15, Max = 60, Rounding = 0,
        Callback = function(Value) Config.skill1002Interval = Value end
    })

    CombatTab:AddSection("Auto Aim Camera (360°)")

    CombatTab:AddToggle("AutoAimCamera", {
        Title = "Auto Aim Camera",
        Description = "Camera tự động nhắm mục tiêu 360 độ",
        Default = Config.autoAimCameraEnabled,
        Callback = function(Value)
            Config.autoAimCameraEnabled = Value
            if Value then
                Combat.startAutoAimCamera()
            else
                Combat.stopAutoAimCamera()
            end
        end
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

    ESPTab:AddToggle("ESPZombieHighlight", {
        Title = "Zombie Highlight",
        Default = Config.espZombieHighlight,
        Callback = function(Value)
            Config.espZombieHighlight = Value
            if not Value then
                for zombie, highlight in pairs(ESP.zombieHighlights) do
                    ESP.removeZombieHighlight(zombie)
                end
            end
        end
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

    ESPTab:AddToggle("ESPPlayerHighlight", {
        Title = "Player Highlight",
        Default = Config.espPlayerHighlight,
        Callback = function(Value)
            Config.espPlayerHighlight = Value
            if not Value then
                for player, highlight in pairs(ESP.playerHighlights) do
                    ESP.removePlayerHighlight(player)
                end
            end
        end
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
        Min = -360, Max = 360, Rounding = 1,
        Callback = function(Value) Config.cameraOffsetX = Value end
    })

    MovementTab:AddSlider("CameraOffsetY", {
        Title = "Camera Offset Y",
        Default = Config.cameraOffsetY,
        Min = -360, Max = 360, Rounding = 1,
        Callback = function(Value) Config.cameraOffsetY = Value end
    })

    MovementTab:AddSlider("CameraOffsetZ", {
        Title = "Camera Offset Z",
        Default = Config.cameraOffsetZ,
        Min = -360, Max = 360, Rounding = 1,
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

    MapTab:AddSection("Supply ESP")

    MapTab:AddToggle("SupplyESP", {
        Title = "Supply ESP (Right Side)",
        Description = "Hiển thị tất cả Supply items bên phải màn hình",
        Default = Config.supplyESPEnabled,
        Callback = function(Value)
            Config.supplyESPEnabled = Value
            if Value then
                Map.startSupplyESP()
            else
                Map.stopSupplyESP()
            end
        end
    })

    MapTab:AddDropdown("SupplyESPPosition", {
        Title = "Supply Position",
        Values = {"Left", "Right"},
        Default = Config.supplyESPPosition,
        Callback = function(Value)
            Config.supplyESPPosition = Value
            Map.updateSupplyPosition()
        end
    })

    MapTab:AddButton({
        Title = "Refresh Supply List",
        Description = "Tìm lại tất cả Supply items ngay lập tức",
        Callback = function()
            if Config.supplyESPEnabled then
                Map.updateSupplyDisplay()
            end
        end
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

    FarmTab:AddSection("Potions - Common")

    FarmTab:AddButton({
        Title = "Common Attack (Buy + Drink)",
        Callback = function()
            if Farm and Farm.buyAndDrinkPotion then
                Farm.buyAndDrinkPotion("CommonAttack")
            end
        end
    })

    FarmTab:AddButton({
        Title = "Common Health (Buy + Drink)",
        Callback = function()
            if Farm and Farm.buyAndDrinkPotion then
                Farm.buyAndDrinkPotion("CommonHealth")
            end
        end
    })

    FarmTab:AddButton({
        Title = "Common Luck (Buy + Drink)",
        Callback = function()
            if Farm and Farm.buyAndDrinkPotion then
                Farm.buyAndDrinkPotion("CommonLuck")
            end
        end
    })

    FarmTab:AddSection("Potions - Rare")

    FarmTab:AddButton({
        Title = "Rare Attack (Buy + Drink)",
        Callback = function()
            if Farm and Farm.buyAndDrinkPotion then
                Farm.buyAndDrinkPotion("RareAttack")
            end
        end
    })

    FarmTab:AddButton({
        Title = "Rare Health (Buy + Drink)",
        Callback = function()
            if Farm and Farm.buyAndDrinkPotion then
                Farm.buyAndDrinkPotion("RareHealth")
            end
        end
    })

    FarmTab:AddButton({
        Title = "Rare Luck (Buy + Drink)",
        Callback = function()
            if Farm and Farm.buyAndDrinkPotion then
                Farm.buyAndDrinkPotion("RareLuck")
            end
        end
    })

    FarmTab:AddSection("Codes")

    FarmTab:AddButton({
        Title = "Redeem All Codes",
        Description = "RAID1212, CHRISTMAS, UPD1212",
        Callback = function()
            Farm.redeemAllCodes()
        end
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
            Right Ctrl - Open/Close Menu
            
            Supply ESP - Hiển thị bên trái màn hình
            Auto refresh mỗi 15 giây
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
            • Right Ctrl - Toggle menu
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
-- 🔹 HUD Customization Tab
function UI.createHUDTab()
    local HUDTab = UI.Window:AddTab({ Title = "HUD Customize" })

    HUDTab:AddToggle("CustomHUD", {
        Title = "Enable Custom HUD",
        Description = "Bật/tắt custom HUD",
        Default = false,
        Callback = function(Value)
            HUD.toggleCustomHUD(Value)
        end
    })

    HUDTab:AddToggle("ApplyToOtherPlayers", {
        Title = "Apply to Other Players",
        Description = "Áp dụng custom HUD cho tất cả players khác",
        Default = true,
        Callback = function(Value)
            HUD.toggleApplyToOtherPlayers(Value)
        end
    })

    HUDTab:AddSection("Visibility Settings")

    HUDTab:AddToggle("TitleVisible", {
        Title = "Show Title",
        Default = true,
        Callback = function(Value)
            HUD.titleVisible = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDTab:AddToggle("PlayerNameVisible", {
        Title = "Show Player Name",
        Default = true,
        Callback = function(Value)
            HUD.playerNameVisible = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDTab:AddToggle("ClassVisible", {
        Title = "Show Class",
        Default = true,
        Callback = function(Value)
            HUD.classVisible = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDTab:AddToggle("LevelVisible", {
        Title = "Show Level",
        Default = true,
        Callback = function(Value)
            HUD.levelVisible = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDTab:AddSection("Lobby UI")

    HUDTab:AddToggle("LobbyPlayerInfoVisible", {
        Title = "Show Lobby PlayerInfo",
        Description = "Hiện/ẩn PlayerInfo trong Lobby",
        Default = true,
        Callback = function(Value)
            HUD.toggleLobbyPlayerInfo(Value)
        end
    })

    HUDTab:AddSection("EXP Display")

    HUDTab:AddToggle("ExpDisplay", {
        Title = "Show EXP Display",
        Description = "Hiển thị EXP ở góc phải dưới màn hình",
        Default = true,
        Callback = function(Value)
            HUD.toggleExpDisplay(Value)
        end
    })

    HUDTab:AddSection("Text Customization")

    HUDTab:AddInput("CustomTitle", {
        Title = "Custom Title",
        Description = "Để trống để giữ nguyên",
        Default = "CHEATER",
        Placeholder = "Enter title...",
        Callback = function(Value)
            HUD.customTitle = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDTab:AddInput("CustomPlayerName", {
        Title = "Custom Player Name",
        Description = "Để trống để giữ nguyên",
        Default = "WiniFy",
        Placeholder = "Enter name...",
        Callback = function(Value)
            HUD.customPlayerName = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDTab:AddInput("CustomClass", {
        Title = "Custom Class",
        Description = "Để trống để giữ nguyên",
        Default = "",
        Placeholder = "Enter class...",
        Callback = function(Value)
            HUD.customClass = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDTab:AddInput("CustomLevel", {
        Title = "Custom Level",
        Description = "Để trống để giữ nguyên",
        Default = "",
        Placeholder = "Enter level...",
        Callback = function(Value)
            HUD.customLevel = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDTab:AddSection("Title Gradient Colors")

    HUDTab:AddColorpicker("TitleGradient1", {
        Title = "Title Color 1",
        Default = Color3.fromRGB(255, 0, 0), -- Red
        Callback = function(Value)
            HUD.titleGradientColor1 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDTab:AddColorpicker("TitleGradient2", {
        Title = "Title Color 2",
        Default = Color3.fromRGB(255, 255, 255), -- White
        Callback = function(Value)
            HUD.titleGradientColor2 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDTab:AddSection("Player Name Gradient Colors")

    HUDTab:AddColorpicker("PlayerNameGradient1", {
        Title = "Name Color 1",
        Default = HUD.playerNameGradientColor1 or Color3.fromRGB(255, 255, 255),
        Callback = function(Value)
            HUD.playerNameGradientColor1 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDTab:AddColorpicker("PlayerNameGradient2", {
        Title = "Name Color 2",
        Default = HUD.playerNameGradientColor2 or Color3.fromRGB(255, 255, 255),
        Callback = function(Value)
            HUD.playerNameGradientColor2 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDTab:AddSection("Class Gradient Colors")

    HUDTab:AddColorpicker("ClassGradient1", {
        Title = "Class Color 1",
        Default = HUD.classGradientColor1 or Color3.fromRGB(255, 255, 255),
        Callback = function(Value)
            HUD.classGradientColor1 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDTab:AddColorpicker("ClassGradient2", {
        Title = "Class Color 2",
        Default = HUD.classGradientColor2 or Color3.fromRGB(255, 255, 255),
        Callback = function(Value)
            HUD.classGradientColor2 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDTab:AddSection("Level Gradient Colors")

    HUDTab:AddColorpicker("LevelGradient1", {
        Title = "Level Color 1",
        Default = HUD.levelGradientColor1 or Color3.fromRGB(255, 255, 255),
        Callback = function(Value)
            HUD.levelGradientColor1 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDTab:AddColorpicker("LevelGradient2", {
        Title = "Level Color 2",
        Default = HUD.levelGradientColor2 or Color3.fromRGB(255, 255, 255),
        Callback = function(Value)
            HUD.levelGradientColor2 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDTab:AddSection("Actions")

    HUDTab:AddButton({
        Title = "Apply Changes",
        Description = "Áp dụng tất cả thay đổi",
        Callback = function()
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDTab:AddButton({
        Title = "Reset to Original",
        Description = "Khôi phục HUD về ban đầu",
        Callback = function()
            HUD.restoreOriginalHUD()
        end
    })

    return HUDTab
end



----------------------------------------------------------
-- 🔹 Visuals Tab
function UI.createVisualsTab()
    local VisualsTab = UI.Window:AddTab({ Title = "Visuals" })

    VisualsTab:AddSection("Fog")

    VisualsTab:AddToggle("RemoveFog", {
        Title = "Remove Fog",
        Description = "Xóa sương mù để nhìn xa hơn",
        Default = Config.removeFogEnabled,
        Callback = function(Value)
            Config.removeFogEnabled = Value
            Visuals.toggleRemoveFog(Value)
        end
    })

    VisualsTab:AddSection("Lighting")

    VisualsTab:AddToggle("Fullbright", {
        Title = "Fullbright",
        Description = "Làm sáng toàn bộ map",
        Default = Config.fullbrightEnabled,
        Callback = function(Value)
            Config.fullbrightEnabled = Value
            Visuals.toggleFullbright(Value)
        end
    })

    VisualsTab:AddSection("Time Control")

    VisualsTab:AddToggle("CustomTime", {
        Title = "Custom Time",
        Description = "Tùy chỉnh thời gian trong game",
        Default = Config.customTimeEnabled,
        Callback = function(Value)
            Config.customTimeEnabled = Value
            Visuals.toggleCustomTime(Value)
        end
    })

    VisualsTab:AddSlider("TimeValue", {
        Title = "Time (Hour)",
        Description = "0 = Midnight, 12 = Noon, 14 = Afternoon",
        Default = Config.customTimeValue,
        Min = 0, Max = 24, Rounding = 0,
        Callback = function(Value)
            Config.customTimeValue = Value
            if Config.customTimeEnabled then
                Visuals.setCustomTime(Value)
            end
        end
    })

    VisualsTab:AddSection("Effects")

    VisualsTab:AddToggle("RemoveEffects", {
        Title = "Auto Remove Effects",
        Description = "Tự động xóa effects khi dupe lần đầu",
        Default = Config.removeEffectsEnabled,
        Callback = function(Value) Config.removeEffectsEnabled = Value end
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
    UI.createFarmTab()
    UI.createVisualsTab()
    UI.createHUDTab()
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
end

return UI
