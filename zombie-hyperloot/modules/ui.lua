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
    local CombatGroup = CombatTab:AddLeftGroupbox("Combat")

    CombatGroup:AddToggle("Aimbot", {
        Text = "Aimbot",
        Default = Config.aimbotEnabled,
        Callback = function(Value) Config.aimbotEnabled = Value end
    })

    CombatGroup:AddDivider()
    CombatGroup:AddLabel("Aimbot Settings")

    CombatGroup:AddDropdown("AimbotTargetMode", {
        Text = "Target Type",
        Values = {"Zombies", "Players", "All"},
        Default = Config.aimbotTargetMode,
        Callback = function(Value) Config.aimbotTargetMode = Value end
    })

    CombatGroup:AddDropdown("AimbotPriorityMode", {
        Text = "Priority",
        Values = {"Nearest", "Farthest", "LowestHealth", "HighestHealth"},
        Default = Config.aimbotPriorityMode,
        Callback = function(Value) Config.aimbotPriorityMode = Value end
    })

    CombatGroup:AddDropdown("AimbotAimPart", {
        Text = "Aim Part",
        Values = {"Head", "UpperTorso", "HumanoidRootPart", "Random"},
        Default = Config.aimbotAimPart,
        Callback = function(Value) Config.aimbotAimPart = Value end
    })

    CombatGroup:AddToggle("AimbotHoldMouse2", {
        Text = "Hold Right Click",
        Default = Config.aimbotHoldMouse2,
        Callback = function(Value) Config.aimbotHoldMouse2 = Value end
    })

    CombatGroup:AddToggle("AimbotAutoFire", {
        Text = "Auto Fire (Mouse1)",
        Default = Config.aimbotAutoFireEnabled,
        Callback = function(Value)
            Config.aimbotAutoFireEnabled = Value
            if not Value and Combat.setAutoFireActive then
                Combat.setAutoFireActive(false)
            end
        end
    })

    CombatGroup:AddToggle("AimbotFOV", {
        Text = "FOV Circle",
        Default = Config.aimbotFOVEnabled,
        Callback = function(Value) Config.aimbotFOVEnabled = Value end
    })

    CombatGroup:AddSlider("AimbotFOVRadius", {
        Text = "FOV Radius",
        Default = Config.aimbotFOVRadius,
        Min = 50, Max = 500, Rounding = 0,
        Callback = function(Value) Config.aimbotFOVRadius = Value end
    })

    CombatGroup:AddToggle("AimbotWallCheck", {
        Text = "Wall Check (Decoration)",
        Default = Config.aimbotWallCheckEnabled,
        Callback = function(Value) Config.aimbotWallCheckEnabled = Value end
    })

    CombatGroup:AddSlider("AimbotSmoothness", {
        Text = "Smoothness",
        Tooltip = "0 = Instant Lock | Higher = Smoother/Slower",
        Default = Config.aimbotSmoothness,
        Min = 0, Max = 0.9, Rounding = 2,
        Callback = function(Value) Config.aimbotSmoothness = Value end
    })

    CombatGroup:AddSlider("AimbotPrediction", {
        Text = "Prediction",
        Default = Config.aimbotPrediction,
        Min = 0, Max = 0.2, Rounding = 3,
        Callback = function(Value) Config.aimbotPrediction = Value end
    })

    CombatGroup:AddDivider()
    CombatGroup:AddLabel("Hitbox Settings")

    CombatGroup:AddToggle("Hitbox", {
        Text = "Hitbox Expander",
        Default = Config.hitboxEnabled,
        Callback = function(Value)
            Config.hitboxEnabled = Value
            Combat.updateAllHitboxes(Value)
        end
    })

    CombatGroup:AddSlider("HitboxSize", {
        Text = "Hitbox Size",
        Default = 4, Min = 1, Max = 20, Rounding = 1,
        Callback = function(Value)
            Config.hitboxSize = Vector3.new(Value, Value, Value)
        end
    })

    CombatGroup:AddDivider()
    CombatGroup:AddLabel("TrigerSkill Dupe")

    CombatGroup:AddToggle("TrigerSkillDupeEnabled", {
        Text = "Enable TrigerSkill Dupe",
        Default = Config.trigerSkillDupeEnabled,
        Callback = function(Value) Config.trigerSkillDupeEnabled = Value end
    })

    CombatGroup:AddSlider("TrigerSkillDupeCount", {
        Text = "Dupe Count",
        Default = Config.trigerSkillDupeCount,
        Min = 1, Max = 20, Rounding = 0,
        Callback = function(Value) Config.trigerSkillDupeCount = Value end
    })

    CombatGroup:AddDivider()
    CombatGroup:AddLabel("Auto Camera Rotation 360°")

    CombatGroup:AddToggle("AutoRotate", {
        Text = "Auto Rotate to Zombies 360°",
        Tooltip = "Camera automatically rotates to the nearest zombie (press R to toggle)",
        Default = Config.autoRotateEnabled,
        Callback = function(Value)
            Config.autoRotateEnabled = Value
            Combat.toggleAutoRotate(Value)
        end
    })

    CombatGroup:AddSlider("AutoRotateSmoothness", {
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
    local ESPGroup = ESPTab:AddLeftGroupbox("ESP")

    ESPGroup:AddDivider()
    ESPGroup:AddLabel("Zombie ESP")

    ESPGroup:AddToggle("ESPZombie", {
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
        end
    })

    ESPGroup:AddLabel("Zombie ESP Color"):AddColorPicker("ESPZombieColor", {
        Default = Config.espColorZombie,
        Title = "Zombie ESP Color",
        Callback = function(Value) Config.espColorZombie = Value end
    })

    ESPGroup:AddToggle("ESPZombieBoxes", {
        Text = "Zombie Boxes",
        Default = Config.espZombieBoxes,
        Callback = function(Value) Config.espZombieBoxes = Value end
    })

    ESPGroup:AddToggle("ESPZombieTracers", {
        Text = "Zombie Tracers",
        Default = Config.espZombieTracers,
        Callback = function(Value) Config.espZombieTracers = Value end
    })

    ESPGroup:AddToggle("ESPZombieNames", {
        Text = "Zombie Names",
        Default = Config.espZombieNames,
        Callback = function(Value) Config.espZombieNames = Value end
    })

    ESPGroup:AddToggle("ESPZombieHealth", {
        Text = "Zombie Health Bars",
        Default = Config.espZombieHealth,
        Callback = function(Value) Config.espZombieHealth = Value end
    })

    ESPGroup:AddToggle("ESPZombieHighlight", {
        Text = "Zombie Highlight",
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

    ESPGroup:AddDivider()
    ESPGroup:AddLabel("Chest ESP")

    ESPGroup:AddToggle("ESPChest", {
        Text = "ESP Chest",
        Default = Config.espChestEnabled,
        Callback = function(Value)
            Config.espChestEnabled = Value
            if Value then ESP.applyChestESP() else ESP.clearChestESP() end
        end
    })

    ESPGroup:AddLabel("Chest ESP Color"):AddColorPicker("ESPChestColor", {
        Default = Config.espColorChest,
        Title = "Chest ESP Color",
        Callback = function(Value)
            Config.espColorChest = Value
            ESP.refreshChestHighlights(Value)
        end
    })

    ESPGroup:AddDivider()
    ESPGroup:AddLabel("Player ESP")

    ESPGroup:AddToggle("ESPPlayer", {
        Text = "ESP Player",
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

    ESPGroup:AddLabel("Player ESP Color"):AddColorPicker("ESPPlayerColor", {
        Default = Config.espColorPlayer,
        Title = "Player ESP Color",
        Callback = function(Value) Config.espColorPlayer = Value end
    })

    ESPGroup:AddLabel("Enemy ESP Color"):AddColorPicker("ESPEnemyColor", {
        Default = Config.espColorEnemy,
        Title = "Enemy ESP Color",
        Callback = function(Value) Config.espColorEnemy = Value end
    })

    ESPGroup:AddToggle("ESPPlayerBoxes", {
        Text = "Player Boxes",
        Default = Config.espPlayerBoxes,
        Callback = function(Value) Config.espPlayerBoxes = Value end
    })

    ESPGroup:AddToggle("ESPPlayerTracers", {
        Text = "Player Tracers",
        Default = Config.espPlayerTracers,
        Callback = function(Value) Config.espPlayerTracers = Value end
    })

    ESPGroup:AddToggle("ESPPlayerNames", {
        Text = "Player Names",
        Default = Config.espPlayerNames,
        Callback = function(Value) Config.espPlayerNames = Value end
    })

    ESPGroup:AddToggle("ESPPlayerHealth", {
        Text = "Player Health Bars",
        Default = Config.espPlayerHealth,
        Callback = function(Value) Config.espPlayerHealth = Value end
    })

    ESPGroup:AddToggle("ESPPlayerTeamCheck", {
        Text = "Team Check",
        Default = Config.espPlayerTeamCheck,
        Callback = function(Value) Config.espPlayerTeamCheck = Value end
    })

    ESPGroup:AddToggle("ESPPlayerHighlight", {
        Text = "Player Highlight",
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
    local MovementTab = UI.Window:AddTab("Movement", "move")
    local MovementGroup = MovementTab:AddLeftGroupbox("Movement")

    MovementGroup:AddToggle("Speed", {
        Text = "Speed Boost",
        Default = Config.speedEnabled,
        Callback = function(Value)
            Config.speedEnabled = Value
            Movement.applySpeed()
        end
    })

    MovementGroup:AddSlider("SpeedValue", {
        Text = "Speed Bonus",
        Default = Config.speedValue,
        Min = 1, Max = 100, Rounding = 1,
        Callback = function(Value)
            Config.speedValue = Value
            if Config.speedEnabled then Movement.applySpeed() end
        end
    })

    MovementGroup:AddToggle("NoClip", {
        Text = "NoClip",
        Default = Config.noClipEnabled,
        Callback = function(Value)
            Config.noClipEnabled = Value
            Movement.applyNoClip()
        end
    })

    MovementGroup:AddToggle("AntiZombie", {
        Text = "Anti-Zombie",
        Default = Config.antiZombieEnabled,
        Callback = function(Value)
            Config.antiZombieEnabled = Value
            Movement.applyAntiZombie()
        end
    })

    MovementGroup:AddSlider("HipHeight", {
        Text = "HipHeight",
        Default = Config.hipHeightValue,
        Min = 0, Max = 200, Rounding = 1,
        Callback = function(Value)
            Config.hipHeightValue = Value
            if Config.antiZombieEnabled then Movement.applyAntiZombie() end
        end
    })

    MovementGroup:AddToggle("NoclipCam", {
        Text = "Noclip Cam",
        Default = Config.noclipCamEnabled,
        Callback = function(Value)
            Config.noclipCamEnabled = Value
            Movement.applyNoclipCam()
        end
    })

    MovementGroup:AddDivider()
    MovementGroup:AddLabel("Camera Teleport")

    MovementGroup:AddToggle("CameraTeleport", {
        Text = "Camera Teleport (X)",
        Default = Config.cameraTeleportEnabled,
        Callback = function(Value) Config.cameraTeleportEnabled = Value end
    })

    MovementGroup:AddDropdown("CameraTargetMode", {
        Text = "Target Mode",
        Values = {"LowestHealth", "Nearest"},
        Default = Config.cameraTargetMode,
        Callback = function(Value) Config.cameraTargetMode = Value end
    })

    MovementGroup:AddSlider("CameraTeleportWaveDelay", {
        Text = "Wave Wait Time (s)",
        Default = Config.cameraTeleportWaveDelay,
        Min = 0, Max = 15, Rounding = 0,
        Callback = function(Value) Config.cameraTeleportWaveDelay = Value end
    })

    MovementGroup:AddToggle("TeleportToLastZombie", {
        Text = "Teleport to Last Zombie",
        Default = Config.teleportToLastZombie,
        Callback = function(Value) Config.teleportToLastZombie = Value end
    })

    MovementGroup:AddDivider()
    MovementGroup:AddLabel("Camera Offset")

    MovementGroup:AddSlider("CameraOffsetX", {
        Text = "Camera Offset X",
        Default = Config.cameraOffsetX,
        Min = -360, Max = 360, Rounding = 1,
        Callback = function(Value) Config.cameraOffsetX = Value end
    })

    MovementGroup:AddSlider("CameraOffsetY", {
        Text = "Camera Offset Y",
        Default = Config.cameraOffsetY,
        Min = -360, Max = 360, Rounding = 1,
        Callback = function(Value) Config.cameraOffsetY = Value end
    })

    MovementGroup:AddSlider("CameraOffsetZ", {
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
    MapGroup:AddLabel("Auto Map Teleport")

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
        Func = function() Map.teleportToWaitAreaAndStart() end
    })

    MapGroup:AddToggle("AutoReplay", {
        Text = "Auto Replay Match",
        Tooltip = "Automatically replay when the match ends",
        Default = Config.autoReplayEnabled,
        Callback = function(Value) Config.autoReplayEnabled = Value end
    })

    MapGroup:AddDivider()
    MapGroup:AddLabel("Supply ESP")

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
            end
        end
    })

    MapGroup:AddDivider()
    MapGroup:AddLabel("Auto Door")

    MapGroup:AddToggle("AutoDoor", {
        Text = "Auto Open Door",
        Tooltip = "Automatically open doors when available (check every 5s)",
        Default = Config.autoDoorEnabled,
        Callback = function(Value)
            Config.autoDoorEnabled = Value
            Map.toggleAutoDoor(Value)
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
    EventGroup:AddLabel("Bob ESP")

    EventGroup:AddToggle("ESPBob", {
        Text = "ESP Bob",
        Tooltip = "Display ESP for Bob (refresh every 5s)",
        Default = Config.espBobEnabled,
        Callback = function(Value)
            Config.espBobEnabled = Value
            if Value then
                ESP.startBobESP()
            else
                ESP.stopBobESP()
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
                if Config.UI and Config.UI.Library then
                    Config.UI.Library:Notify({
                        Title = "Bob ESP",
                        Description = "Teleported to Bob!",
                        Time = 2
                    })
                end
            else
                if Config.UI and Config.UI.Library then
                    Config.UI.Library:Notify({
                        Title = "Bob ESP",
                        Description = "Bob not found!",
                        Time = 2
                    })
                end
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
        Callback = function(Value) Config.autoBulletBoxEnabled = Value end
    })

    FarmGroup:AddToggle("Teleport", {
        Text = "Auto Chest (T Key)",
        Default = Config.teleportEnabled,
        Callback = function(Value) Config.teleportEnabled = Value end
    })

    FarmGroup:AddDivider()
    FarmGroup:AddLabel("Potions - Common")

    FarmGroup:AddButton({
        Text = "Common Attack (Buy + Drink)",
        Func = function()
            if Farm and Farm.buyAndDrinkPotion then
                Farm.buyAndDrinkPotion("CommonAttack")
            end
        end
    })

    FarmGroup:AddButton({
        Text = "Common Health (Buy + Drink)",
        Func = function()
            if Farm and Farm.buyAndDrinkPotion then
                Farm.buyAndDrinkPotion("CommonHealth")
            end
        end
    })

    FarmGroup:AddButton({
        Text = "Common Luck (Buy + Drink)",
        Func = function()
            if Farm and Farm.buyAndDrinkPotion then
                Farm.buyAndDrinkPotion("CommonLuck")
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
            end
        end
    })

    FarmGroup:AddButton({
        Text = "Rare Health (Buy + Drink)",
        Func = function()
            if Farm and Farm.buyAndDrinkPotion then
                Farm.buyAndDrinkPotion("RareHealth")
            end
        end
    })

    FarmGroup:AddButton({
        Text = "Rare Luck (Buy + Drink)",
        Func = function()
            if Farm and Farm.buyAndDrinkPotion then
                Farm.buyAndDrinkPotion("RareLuck")
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
    CharacterGroup:AddLabel("Character Selection")

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
        end
    })

    CharacterGroup:AddButton({
        Text = "Equip Selected Character",
        Tooltip = "Equip the selected character (and use for Auto Skill)",
        Func = function()
            local id = Config.selectedCharacterId
            if not id then
                if Config.UI and Config.UI.Library then
                    Config.UI.Library:Notify({
                        Title = "Character",
                        Description = "No character selected in dropdown!",
                        Time = 3
                    })
                end
                return
            end

            local success, err = Character.equipCharacter(id)

            if Config.UI and Config.UI.Library then
                if success then
                    Config.UI.Library:Notify({
                        Title = "Character",
                        Description = "Sent request to equip character " .. tostring(Config.selectedCharacterDisplay or id),
                        Time = 3
                    })
                else
                    Config.UI.Library:Notify({
                        Title = "Character",
                        Description = "Equip failed: " .. tostring(err),
                        Time = 3
                    })
                end
            end
        end
    })

    CharacterGroup:AddDivider()
    CharacterGroup:AddLabel("Auto Skill")

    -- Lấy character ID hiện tại để quyết định hiển thị skill nào
    local currentCharacterId = Character.getCurrentCharacterId()
    
    -- Create Auto Skill toggle with dynamic tooltip
    local autoSkillTooltip = "Automatically use the appropriate skill for the current character"
    if currentCharacterId == 1006 then
        autoSkillTooltip = "Automatically use Armsmaster Ultimate + Healing"
    elseif currentCharacterId == 1003 then
        autoSkillTooltip = "Automatically use Wraith Ultimate + Healing"
    elseif currentCharacterId == 1001 then
        autoSkillTooltip = "Automatically use Assault Ultimate + Healing"
    elseif currentCharacterId == 1004 then
        autoSkillTooltip = "Automatically use Flag Bearer Ultimate + Healing"
    elseif currentCharacterId then
        autoSkillTooltip = "Automatically use Healing (this character doesn't have a unique ultimate)"
    end

    CharacterGroup:AddToggle("AutoSkill", {
        Text = "Auto Skill",
        Tooltip = autoSkillTooltip,
        Default = Config.autoSkillEnabled,
        Callback = function(Value)
            Config.autoSkillEnabled = Value
        end
    })

    -- Healing Skill (luôn hiển thị - character nào cũng có)
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
            Min = 0.3, Max = 60, Rounding = 1,
            Callback = function(Value) Config.wraithUltimateInterval = Value end
        })
    end

    -- Assault Ultimate (chỉ hiển thị khi character = 1001)
    if currentCharacterId == 1001 then
        CharacterGroup:AddSlider("AssaultUltimateInterval", {
            Text = "Assault Ultimate Interval (s)",
            Default = Config.assaultUltimateInterval,
            Min = 0.3, Max = 60, Rounding = 1,
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

    return CharacterTab
end


----------------------------------------------------------
-- 🔹 Settings Tab
function UI.createSettingsTab(cleanupCallback)
    local SettingsTab = UI.Window:AddTab("Settings", "settings")
    local SettingsGroup = SettingsTab:AddLeftGroupbox("Settings")

    SettingsGroup:AddDivider()
    SettingsGroup:AddLabel("Reset Script")

    SettingsGroup:AddButton({
        Text = "Unload Script",
        Tooltip = "Unload all scripts and delete GUI",
        Func = function()
            if cleanupCallback then cleanupCallback() end
        end
    })

    -- Config Save / Load
    UI.SaveManager:SetLibrary(UI.Library)
    UI.ThemeManager:SetLibrary(UI.Library)
    UI.SaveManager:IgnoreThemeSettings()
    UI.SaveManager:SetIgnoreIndexes({})
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
    local HUDTab = UI.Window:AddTab("HUD Customize", "layout")
    local HUDGroup = HUDTab:AddLeftGroupbox("HUD Customize")

    HUDGroup:AddToggle("CustomHUD", {
        Text = "Enable Custom HUD",
        Tooltip = "Bật/tắt custom HUD",
        Default = false,
        Callback = function(Value)
            HUD.toggleCustomHUD(Value)
        end
    })

    HUDGroup:AddToggle("ApplyToOtherPlayers", {
        Text = "Apply to Other Players",
        Tooltip = "Áp dụng custom HUD cho tất cả players khác",
        Default = true,
        Callback = function(Value)
            HUD.toggleApplyToOtherPlayers(Value)
        end
    })

    HUDGroup:AddDivider()
    HUDGroup:AddLabel("Visibility Settings")

    HUDGroup:AddToggle("TitleVisible", {
        Text = "Show Title",
        Default = true,
        Callback = function(Value)
            HUD.titleVisible = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDGroup:AddToggle("PlayerNameVisible", {
        Text = "Show Player Name",
        Default = true,
        Callback = function(Value)
            HUD.playerNameVisible = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDGroup:AddToggle("ClassVisible", {
        Text = "Show Class",
        Default = true,
        Callback = function(Value)
            HUD.classVisible = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDGroup:AddToggle("LevelVisible", {
        Text = "Show Level",
        Default = true,
        Callback = function(Value)
            HUD.levelVisible = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDGroup:AddDivider()
    HUDGroup:AddLabel("Lobby UI")

    HUDGroup:AddToggle("LobbyPlayerInfoVisible", {
        Text = "Show Lobby PlayerInfo",
        Tooltip = "Show/hide PlayerInfo in Lobby",
        Default = true,
        Callback = function(Value)
            HUD.toggleLobbyPlayerInfo(Value)
        end
    })

    HUDGroup:AddDivider()
    HUDGroup:AddLabel("EXP Display")

    HUDGroup:AddToggle("ExpDisplay", {
        Text = "Show EXP Display",
        Tooltip = "Display EXP at the bottom right of the screen",
        Default = true,
        Callback = function(Value)
            HUD.toggleExpDisplay(Value)
        end
    })

    HUDGroup:AddDivider()
    HUDGroup:AddLabel("Text Customization")

    HUDGroup:AddInput("CustomTitle", {
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

    HUDGroup:AddInput("CustomPlayerName", {
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

    HUDGroup:AddInput("CustomClass", {
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

    HUDGroup:AddInput("CustomLevel", {
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

    HUDGroup:AddDivider()
    HUDGroup:AddLabel("Title Gradient Colors")

    HUDGroup:AddLabel("Title Color 1"):AddColorPicker("TitleGradient1", {
        Default = Color3.fromRGB(255, 0, 0), -- Red
        Title = "Title Color 1",
        Callback = function(Value)
            HUD.titleGradientColor1 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDGroup:AddLabel("Title Color 2"):AddColorPicker("TitleGradient2", {
        Default = Color3.fromRGB(255, 255, 255), -- White
        Title = "Title Color 2",
        Callback = function(Value)
            HUD.titleGradientColor2 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDGroup:AddDivider()
    HUDGroup:AddLabel("Player Name Gradient Colors")

    HUDGroup:AddLabel("Name Color 1"):AddColorPicker("PlayerNameGradient1", {
        Default = HUD.playerNameGradientColor1 or Color3.fromRGB(255, 255, 255),
        Title = "Name Color 1",
        Callback = function(Value)
            HUD.playerNameGradientColor1 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDGroup:AddLabel("Name Color 2"):AddColorPicker("PlayerNameGradient2", {
        Default = HUD.playerNameGradientColor2 or Color3.fromRGB(255, 255, 255),
        Title = "Name Color 2",
        Callback = function(Value)
            HUD.playerNameGradientColor2 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDGroup:AddDivider()
    HUDGroup:AddLabel("Class Gradient Colors")

    HUDGroup:AddLabel("Class Color 1"):AddColorPicker("ClassGradient1", {
        Default = HUD.classGradientColor1 or Color3.fromRGB(255, 255, 255),
        Title = "Class Color 1",
        Callback = function(Value)
            HUD.classGradientColor1 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDGroup:AddLabel("Class Color 2"):AddColorPicker("ClassGradient2", {
        Default = HUD.classGradientColor2 or Color3.fromRGB(255, 255, 255),
        Title = "Class Color 2",
        Callback = function(Value)
            HUD.classGradientColor2 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDGroup:AddDivider()
    HUDGroup:AddLabel("Level Gradient Colors")

    HUDGroup:AddLabel("Level Color 1"):AddColorPicker("LevelGradient1", {
        Default = HUD.levelGradientColor1 or Color3.fromRGB(255, 255, 255),
        Title = "Level Color 1",
        Callback = function(Value)
            HUD.levelGradientColor1 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDGroup:AddLabel("Level Color 2"):AddColorPicker("LevelGradient2", {
        Default = HUD.levelGradientColor2 or Color3.fromRGB(255, 255, 255),
        Title = "Level Color 2",
        Callback = function(Value)
            HUD.levelGradientColor2 = Value
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDGroup:AddDivider()
    HUDGroup:AddLabel("Actions")

    HUDGroup:AddButton({
        Text = "Apply Changes",
        Tooltip = "Apply all changes",
        Func = function()
            if HUD.customHUDEnabled then
                HUD.applyCustomHUD()
            end
        end
    })

    HUDGroup:AddButton({
        Text = "Reset to Original",
        Tooltip = "Restore HUD to original",
        Func = function()
            HUD.restoreOriginalHUD()
        end
    })

    return HUDTab
end



----------------------------------------------------------
-- 🔹 Visuals Tab
function UI.createVisualsTab()
    local VisualsTab = UI.Window:AddTab("Visuals", "eye")
    local VisualsGroup = VisualsTab:AddLeftGroupbox("Visuals")

    VisualsGroup:AddDivider()
    VisualsGroup:AddLabel("Fog")

    VisualsGroup:AddToggle("RemoveFog", {
        Text = "Remove Fog",
        Tooltip = "Remove fog to see further",
        Default = Config.removeFogEnabled,
        Callback = function(Value)
            Config.removeFogEnabled = Value
            Visuals.toggleRemoveFog(Value)
        end
    })

    VisualsGroup:AddDivider()
    VisualsGroup:AddLabel("Lighting")

    VisualsGroup:AddToggle("Fullbright", {
        Text = "Fullbright",
        Tooltip = "Make the entire map brighter",
        Default = Config.fullbrightEnabled,
        Callback = function(Value)
            Config.fullbrightEnabled = Value
            Visuals.toggleFullbright(Value)
        end
    })

    VisualsGroup:AddDivider()
    VisualsGroup:AddLabel("Time Control")

    VisualsGroup:AddToggle("CustomTime", {
        Text = "Custom Time",
        Tooltip = "Customize time in game",
        Default = Config.customTimeEnabled,
        Callback = function(Value)
            Config.customTimeEnabled = Value
            Visuals.toggleCustomTime(Value)
        end
    })

    VisualsGroup:AddSlider("TimeValue", {
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

    VisualsGroup:AddDivider()
    VisualsGroup:AddLabel("Effects")

    VisualsGroup:AddToggle("RemoveEffects", {
        Text = "Auto Remove Effects",
        Tooltip = "Automatically remove effects when duping for the first time",
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
    UI.createEventTab()
    UI.createFarmTab()
    UI.createCharacterTab()
    UI.createVisualsTab()
    UI.createHUDTab()
    UI.createSettingsTab(cleanupCallback)
    UI.createInfoTab()
    -- Obsidian UI tabs are auto-selected, no need for SelectTab
end

----------------------------------------------------------
-- 🔹 Cleanup
function UI.cleanup()
    if UI.Window and UI.Window.Destroy then
        pcall(function() UI.Window:Destroy() end)
    end
end

return UI
