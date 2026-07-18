local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local AttackRemote = ReplicatedStorage.Remotes.PlayerAttack
local BreakRemote = ReplicatedStorage.Remotes.BreakDestructible
local PetDamage = ReplicatedStorage.Remotes.PetDamage
local ToggleFavoriteEvent = ReplicatedStorage.Remotes.ToggleFavorite
local OpenChestEvent = ReplicatedStorage.Remotes.OpenPetChest
local UpgradePetEvent = ReplicatedStorage.Remotes.UpgradePet
local SellItemEvent = ReplicatedStorage.Remotes.SellItem
local EquipFoodEvent = ReplicatedStorage.Remotes.EquipFood
local UsePotionEvent = ReplicatedStorage.Remotes.UsePotion
local EquipPotionEvent = ReplicatedStorage.Remotes.EquipPotion
local EquipWeaponEvent = ReplicatedStorage.Remotes.Equip      -- EquipWeapon: FireServer(slot, item)
local EquipArmorEvent = ReplicatedStorage.Remotes.EquipArmor   -- EquipArmor: FireServer(item)
local EquipNecklaceEvent = ReplicatedStorage.Remotes.EquipNecklace -- EquipNecklace: FireServer(item)
local PickupEvent = ReplicatedStorage.Remotes.Pickup              -- Pickup: FireServer(dropItem)
local DropsFolder = ReplicatedStorage:FindFirstChild("Drops")     -- Folder chứa tất cả drop items
local Mobs = workspace:FindFirstChild("Mobs")
local Destructibles = workspace:FindFirstChild("Destructibles")
-- Cấu hình mặc định cho auto attack.
local Enabled = false
local MinDelay = 0.1
local MaxDelay = 0.25
-- Cấu hình mặc định cho auto break destructible.
local BreakEnabled = false
local BreakDelay = 0.1
-- Cấu hình mặc định cho auto pet attack.
local PetAttackEnabled = false
local PetAttackDelay = 0.05 -- Delay giữa mỗi lần gửi attack (giây)
local PetAttackLoop = 5 -- Số lần fire attack per tick
-- Cấu hình mặc định cho auto pet management.
local AutoFavoriteEnabled = false
local AutoOpenChestEnabled = false
local AutoMergeEnabled = false
-- Cấu hình mặc định cho Auto Eat Food & Auto Use Potion
local AutoEatFoodEnabled = false
local EatFoodThreshold = 30 -- Ăn food khi TimeLeft < ngưỡng này (giây)
local AutoUsePotionEnabled = false
local PotionUseInterval = 25 -- Khoảng cách giữa 2 lần dùng potion (giây)
-- Cấu hình mặc định cho Auto Equip Item
local AutoEquipWeaponEnabled = false
local AutoEquipArmorEnabled = false
local AutoEquipNecklaceEnabled = false
-- Cấu hình mặc định cho Auto Pickup
local AutoPickupEnabled = false
-- Cấu hình mặc định cho di chuyển & Noclip.
local SpeedEnabled = false
local WalkSpeed = 60
local InfiniteJumpEnabled = false
local NoclipEnabled = false
-- Cấu hình cho Tween To Mob
local TweenToMobEnabled = false
local TweenHeight = 20
local TweenSpeed = 100
local FlyConnection = nil
-- Cấu hình mặc định cho ESP mobs.
local MobEspEnabled = false
local MobNameEspEnabled = false
local MobDistanceEspEnabled = false
local MobHealthEspEnabled = false
local MobEspColor = Color3.fromRGB(255, 80, 80)
local MobHighlights = {}
local MobNameTags = {}
-- Tải ZyronX UI Library
local Library = loadstring(game:HttpGetAsync("https://pastefy.app/YoX4PJmf/raw"))()
-- Tạo cửa sổ chính với theme tối
local Window = Library:CreateWindow({
    Title = "Dungeon Heros",
    Subtitle = "Dev Combat",
    SubtitleColor = Color3.fromRGB(190, 140, 255),
    SphereText = true,
    SphereWords = "DH"
})
-- Hàm tạo môi trường vô trọng lực (chống rơi)
local function applyAntiGravity(root)
    if not root:FindFirstChild("TweenAntiGravity") then
        local bv = Instance.new("BodyVelocity")
        bv.Name = "TweenAntiGravity"
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.zero
        bv.Parent = root
    end
end
-- Hàm xoá môi trường vô trọng lực
local function removeAntiGravity()
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root and root:FindFirstChild("TweenAntiGravity") then
        root.TweenAntiGravity:Destroy()
    end
end
-- Các hàm Utilities (Tiện ích)
local function getHumanoid()
    local character = LocalPlayer.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end
local function getPet()
    if not Mobs then return nil end
    for _, mob in ipairs(Mobs:GetChildren()) do
        if mob:GetAttribute("Owner") == LocalPlayer.Name then return mob end
    end
    return nil
end
-- Cache attacks đã discover cho từng pet (key = pet.Name)
local PetAttacksCache = {}
-- Require Mobs module 1 lần (dùng chung cho probe)
local MobsModule = nil
pcall(function()
    MobsModule = require(ReplicatedStorage.Systems.Mobs)
end)
-- Probe tìm attack name của pet qua Mobs module
-- Trả về { attackName, attackShape } hoặc nil
local function probePetAttacks(petName)
    if PetAttacksCache[petName] then return PetAttacksCache[petName] end
    if not MobsModule or not MobsModule.GetMobAttacksFolder then return nil end
    for _, diff in ipairs({"Normal", "Hard", "Easy", "Legendary", "Elite"}) do
        local ok, attacksFolder = pcall(MobsModule.GetMobAttacksFolder, MobsModule, petName, diff)
        if ok and attacksFolder then
            local firstAttack = attacksFolder:GetChildren()[1]
            if firstAttack then
                local result = { attackName = firstAttack.Name, attackShape = "Circle" }
                PetAttacksCache[petName] = result
                return result
            end
        end
    end
    return nil
end
-- Lấy attack info cho pet: ưu tiên attribute > cache > probe > default
local function getPetAttackInfo(pet)
    local atkType = pet:GetAttribute("AttackType")
    local atkShape = pet:GetAttribute("AttackShape")
    if atkType and atkShape then
        return atkType, atkShape
    end
    local cached = PetAttacksCache[pet.Name]
    if cached then
        return cached.attackName, cached.attackShape
    end
    local probed = probePetAttacks(pet.Name)
    if probed then
        return probed.attackName, probed.attackShape
    end
    return "Bite", "Circle"
end
local function getRandomDelay() return math.random(math.floor(MinDelay * 100), math.floor(MaxDelay * 100)) / 100 end
local function isValidMob(mob)
    return mob:IsA("Model") and mob.PrimaryPart and mob:GetAttribute("HP") and mob:GetAttribute("HP") > 0 and not mob:GetAttribute("Owner")
end
local function getTargets(root)
    local targets = {}
    if not Mobs then return targets end
    for _, mob in ipairs(Mobs:GetChildren()) do
        if isValidMob(mob) then table.insert(targets, mob) end
    end
    return targets
end
local function getNearestMob(root)
    local nearest = nil
    local minDistance = math.huge
    if Mobs then
        for _, mob in ipairs(Mobs:GetChildren()) do
            if isValidMob(mob) then
                local distance = (root.Position - mob.PrimaryPart.Position).Magnitude
                if distance < minDistance then
                    minDistance = distance
                    nearest = mob
                end
            end
        end
    end
    return nearest
end
-- Logic bay mượt bằng Heartbeat
local function startSmoothFly()
    if FlyConnection then return end
    FlyConnection = RunService.Heartbeat:Connect(function(deltaTime)
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local targetMob = getNearestMob(root)
        if targetMob and targetMob.PrimaryPart then
            applyAntiGravity(root)
            local targetPos = targetMob.PrimaryPart.Position + Vector3.new(0, TweenHeight, 0)
            local _, ry, _ = root.CFrame:ToOrientation()
            local distance = (root.Position - targetPos).Magnitude
            if distance > 1 then
                local direction = (targetPos - root.Position).Unit
                local step = math.min(TweenSpeed * deltaTime, distance)
                local newPos = root.Position + direction * step
                root.CFrame = CFrame.new(newPos) * CFrame.fromOrientation(0, ry, 0)
            else
                root.CFrame = CFrame.new(targetPos) * CFrame.fromOrientation(0, ry, 0)
            end
        else
            removeAntiGravity()
        end
    end)
end
local function stopSmoothFly()
    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end
    removeAntiGravity()
end
-- ==========================================
-- TAB AUTO FARM (Gộp Combat, Pet, Destructibles)
-- ==========================================
-- ZyronX: Tạo Tab > Page > Section > Components
local FarmTab = Window:CreateTab("Auto Farm", true, false)
local FarmPage = FarmTab:CreatePage("Farm")
-- Phần Player Combat
local CombatSection = FarmPage:CreateSection("Player Combat")
CombatSection:AddToggle("Auto Attack", Enabled, function(state)
    Enabled = state
end)
CombatSection:AddToggle("Tween To Mob", TweenToMobEnabled, function(state)
    TweenToMobEnabled = state
    if state then
        startSmoothFly()
    else
        stopSmoothFly()
    end
end)
CombatSection:AddSlider("Tween Height (Y)", 5, 50, TweenHeight, function(val)
    TweenHeight = val
end)
CombatSection:AddSlider("Tween Speed", 20, 150, TweenSpeed, function(val)
    TweenSpeed = val
end)
-- Phần Pet Attack
local PetSection = FarmPage:CreateSection("Pet")
PetSection:AddToggle("Auto Pet Attack", PetAttackEnabled, function(state)
    PetAttackEnabled = state
end)
-- Phần Break Destructibles
local DestructSection = FarmPage:CreateSection("Destructibles")
DestructSection:AddToggle("Auto Break", BreakEnabled, function(state)
    BreakEnabled = state
end)
-- Phần Pet Management
local PetMgmtSection = FarmPage:CreateSection("Pet Management")
PetMgmtSection:AddToggle("Auto Favorite Pet", AutoFavoriteEnabled, function(state)
    AutoFavoriteEnabled = state
end)
PetMgmtSection:AddToggle("Auto Open Pet Chest", AutoOpenChestEnabled, function(state)
    AutoOpenChestEnabled = state
end)
PetMgmtSection:AddToggle("Auto Merge Pet", AutoMergeEnabled, function(state)
    AutoMergeEnabled = state
end)
-- Section Auto Pickup (trong cùng Farm tab)
local PickupPage = FarmTab:CreatePage("Auto Pickup")
local PickupSection = PickupPage:CreateSection("Auto Pickup Settings")
-- Toggle auto pickup: tự động nhặt tất cả drop thuộc về player
PickupSection:AddToggle("Auto Pickup", AutoPickupEnabled, function(state)
    AutoPickupEnabled = state
end)
-- ==========================================
-- TAB MOVEMENT
-- ==========================================
local MovementTab = Window:CreateTab("Movement", false, false)
local MovementPage = MovementTab:CreatePage("Movement")
local MoveSection = MovementPage:CreateSection("Player Movement")
MoveSection:AddToggle("Set Speed", SpeedEnabled, function(state)
    SpeedEnabled = state
end)
MoveSection:AddSlider("WalkSpeed", 16, 80, WalkSpeed, function(val)
    WalkSpeed = val
end)
MoveSection:AddToggle("Infinite Jump", InfiniteJumpEnabled, function(state)
    InfiniteJumpEnabled = state
end)
MoveSection:AddToggle("Noclip", NoclipEnabled, function(state)
    NoclipEnabled = state
end)
-- ==========================================
-- TAB ESP
-- ==========================================
local EspTab = Window:CreateTab("ESP", false, false)
local EspPage = EspTab:CreatePage("ESP")
local ESPSection = EspPage:CreateSection("ESP Settings")
ESPSection:AddToggle("Mob Highlight", MobEspEnabled, function(state)
    MobEspEnabled = state
end)
ESPSection:AddToggle("Mob Name", MobNameEspEnabled, function(state)
    MobNameEspEnabled = state
end)
ESPSection:AddToggle("Mob Distance", MobDistanceEspEnabled, function(state)
    MobDistanceEspEnabled = state
end)
ESPSection:AddToggle("Mob Health", MobHealthEspEnabled, function(state)
    MobHealthEspEnabled = state
end)
-- Dropdown chọn màu mob (ZyronX: single select trả về string trực tiếp)
ESPSection:AddDropdown("Mob Color", {"Red", "Green", "Blue", "Yellow", "Purple", "White"}, false, function(selected)
    local colors = {
        Red = Color3.fromRGB(255, 80, 80),
        Green = Color3.fromRGB(80, 255, 120),
        Blue = Color3.fromRGB(80, 160, 255),
        Yellow = Color3.fromRGB(255, 230, 80),
        Purple = Color3.fromRGB(180, 80, 255),
        White = Color3.fromRGB(255, 255, 255)
    }
    MobEspColor = colors[selected] or MobEspColor
end)
local function updateMobHighlight(mob)
    if not isValidMob(mob) then
        if MobHighlights[mob] then MobHighlights[mob]:Destroy(); MobHighlights[mob] = nil end
        return
    end
    local highlight = MobHighlights[mob]
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "MobESPHighlight"
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillTransparency = 0.6
        highlight.OutlineTransparency = 0
        highlight.Adornee = mob
        highlight.Parent = mob
        MobHighlights[mob] = highlight
    end
    highlight.Enabled = MobEspEnabled
    highlight.FillColor = MobEspColor
    highlight.OutlineColor = MobEspColor
end
local function updateMobNameTag(mob)
    if not isValidMob(mob) then
        if MobNameTags[mob] then MobNameTags[mob]:Destroy(); MobNameTags[mob] = nil end
        return
    end
    local tag = MobNameTags[mob]
    if not tag then
        tag = Instance.new("BillboardGui")
        tag.Name = "MobESPName"
        tag.Adornee = mob.PrimaryPart
        tag.AlwaysOnTop = true
        tag.Size = UDim2.new(0, 180, 0, 48)
        tag.StudsOffset = Vector3.new(0, 3, 0)
        tag.Parent = mob
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.BackgroundTransparency = 1
        nameLabel.Size = UDim2.new(0.65, 0, 0, 18)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 13
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextStrokeTransparency = 0.2
        nameLabel.Parent = tag
        local distanceLabel = Instance.new("TextLabel")
        distanceLabel.Name = "DistanceLabel"
        distanceLabel.BackgroundTransparency = 1
        distanceLabel.Position = UDim2.new(0.65, 0, 0, 0)
        distanceLabel.Size = UDim2.new(0.35, 0, 0, 18)
        distanceLabel.Font = Enum.Font.GothamBold
        distanceLabel.TextSize = 13
        distanceLabel.TextXAlignment = Enum.TextXAlignment.Right
        distanceLabel.TextStrokeTransparency = 0.2
        distanceLabel.Parent = tag
        local barBackground = Instance.new("Frame")
        barBackground.Name = "HealthBarBackground"
        barBackground.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        barBackground.BorderSizePixel = 0
        barBackground.Position = UDim2.new(0.08, 0, 0, 24)
        barBackground.Size = UDim2.new(0.84, 0, 0, 17)
        barBackground.Parent = tag
        local barCorner = Instance.new("UICorner", barBackground)
        barCorner.CornerRadius = UDim.new(0, 8)
        local barFill = Instance.new("Frame")
        barFill.Name = "HealthBarFill"
        barFill.BackgroundColor3 = Color3.fromRGB(80, 255, 120)
        barFill.BorderSizePixel = 0
        barFill.Size = UDim2.fromScale(1, 1)
        barFill.Parent = barBackground
        local fillCorner = Instance.new("UICorner", barFill)
        fillCorner.CornerRadius = UDim.new(0, 8)
        local healthLabel = Instance.new("TextLabel")
        healthLabel.Name = "HealthLabel"
        healthLabel.BackgroundTransparency = 1
        healthLabel.Size = UDim2.fromScale(1, 1)
        healthLabel.Font = Enum.Font.GothamBold
        healthLabel.TextSize = 12
        healthLabel.TextStrokeTransparency = 0.25
        healthLabel.ZIndex = 2
        healthLabel.Parent = barBackground
        MobNameTags[mob] = tag
    end
    local hp = mob:GetAttribute("HP") or 0
    local maxHp = mob:GetAttribute("MaxHP") or mob:GetAttribute("MaxHealth") or hp
    local healthPercent = maxHp > 0 and math.clamp(hp / maxHp, 0, 1) or 0
    tag.NameLabel.Visible = MobNameEspEnabled
    tag.NameLabel.Text = mob.Name
    tag.NameLabel.TextColor3 = MobEspColor
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local distance = root and math.floor((root.Position - mob.PrimaryPart.Position).Magnitude) or 0
    tag.DistanceLabel.Visible = MobDistanceEspEnabled
    tag.DistanceLabel.Text = tostring(distance) .. "m"
    tag.DistanceLabel.TextColor3 = MobEspColor
    tag.HealthBarBackground.HealthLabel.Visible = MobHealthEspEnabled
    tag.HealthBarBackground.HealthLabel.Text = string.format("%s/%s HP", tostring(hp), tostring(maxHp))
    tag.HealthBarBackground.HealthLabel.TextColor3 = Color3.fromRGB(230, 255, 230)
    tag.HealthBarBackground.Visible = MobHealthEspEnabled
    tag.HealthBarBackground.HealthBarFill.Size = UDim2.fromScale(healthPercent, 1)
    tag.HealthBarBackground.HealthBarFill.BackgroundColor3 = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 80)
    tag.Enabled = MobNameEspEnabled or MobDistanceEspEnabled or MobHealthEspEnabled
    tag.Adornee = mob.PrimaryPart
end
local function clearMobHighlights()
    for mob, highlight in pairs(MobHighlights) do if highlight then highlight:Destroy() end; MobHighlights[mob] = nil end
end
local function clearMobNameTags()
    for mob, tag in pairs(MobNameTags) do if tag then tag:Destroy() end; MobNameTags[mob] = nil end
end
local function getNearestDestructible(root)
    local nearest, nearestDist = nil, math.huge
    for _, obj in ipairs(Destructibles:GetDescendants()) do
        if obj:IsA("BasePart") then
            local dist = (root.Position - obj.Position).Magnitude
            if dist < nearestDist then nearest, nearestDist = obj, dist end
        end
    end
    return nearest
end
-- Sự kiện cho noclip (Xoá va chạm)
RunService.Stepped:Connect(function()
    if NoclipEnabled then
        local character = LocalPlayer.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)
UserInputService.JumpRequest:Connect(function()
    if InfiniteJumpEnabled then
        local humanoid = getHumanoid()
        if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)
task.spawn(function()
    while task.wait(0.1) do
        local humanoid = getHumanoid()
        if humanoid then humanoid.WalkSpeed = SpeedEnabled and WalkSpeed or 16 end
    end
end)
task.spawn(function()
    while task.wait(0.25) do
        if not Mobs then clearMobHighlights(); clearMobNameTags(); continue end
        for _, mob in ipairs(Mobs:GetChildren()) do updateMobHighlight(mob); updateMobNameTag(mob) end
        if not MobEspEnabled then for _, hl in pairs(MobHighlights) do hl.Enabled = false end end
        if not MobNameEspEnabled and not MobDistanceEspEnabled and not MobHealthEspEnabled then
            for _, tag in pairs(MobNameTags) do tag.Enabled = false end
        end
    end
end)
-- ==========================================
-- TAB EQUIPMENT (AutoSell Config)
-- ==========================================
-- Các hằng số cấu hình AutoSell (lấy từ AutoSell.txt)
local RARITY_NAMES = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Primordial", "Unique"}
local RARITY_KEYS = {"1", "2", "3", "4", "5", "6", "7", "8"}
local DEFAULT_MISC_TYPES = {"Necklace", "DuplicateTitles", "DuplicateWeaponAura", "DuplicateWeaponCosmetic", "DuplicateShirtPantsCosmetic"}
local LEVEL_SOFT_CAP = 195

-- Require Items module sớm để discover types tự động
local ItemsModule = require(ReplicatedStorage.Systems.Items)

-- Tự động discover tất cả weapon/armor types từ game data
-- Duyệt toàn bộ item list, phân loại theo Category → Type
local DISCOVERED_WEAPON_TYPES = {}
local DISCOVERED_ARMOR_TYPES = {}
local function discoverItemTypes()
    local weaponSet = {}
    local armorSet = {}
    local ok, itemList = pcall(function()
        return ItemsModule:GetItemList()
    end)
    if ok and typeof(itemList) == "table" then
        for _, itemData in pairs(itemList) do
            if typeof(itemData) == "table" and typeof(itemData.Type) == "string" then
                if itemData.Category == "Weapon" and not weaponSet[itemData.Type] then
                    weaponSet[itemData.Type] = true
                    table.insert(DISCOVERED_WEAPON_TYPES, itemData.Type)
                elseif itemData.Category == "Armor" and not armorSet[itemData.Type] then
                    armorSet[itemData.Type] = true
                    table.insert(DISCOVERED_ARMOR_TYPES, itemData.Type)
                end
            end
        end
        table.sort(DISCOVERED_WEAPON_TYPES)
        table.sort(DISCOVERED_ARMOR_TYPES)
    end
end
discoverItemTypes()
-- Hàm khởi tạo AutoSellConfig trong Profile nếu chưa tồn tại
-- Tạo cấu trúc folder BoolValue giống hệt server-side AutoSell module
local function initAutoSellConfig()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local profile = playerGui and playerGui:FindFirstChild("Profile")
    if not profile then return nil end
    local config = profile:FindFirstChild("AutoSellConfig")
    -- Nếu chưa có config, tạo mới với giá trị mặc định
    if not config then
        config = Instance.new("Folder")
        config.Name = "AutoSellConfig"
        config.Parent = profile
    end
    -- Khởi tạo BoolValue cho Enabled (mặc định tắt)
    if not config:FindFirstChild("Enabled") then
        local v = Instance.new("BoolValue")
        v.Name = "Enabled"
        v.Value = false
        v.Parent = config
    end
    -- Khởi tạo BoolValue cho SellWorseThanEquipped (mặc định bật)
    if not config:FindFirstChild("SellWorseThanEquipped") then
        local v = Instance.new("BoolValue")
        v.Name = "SellWorseThanEquipped"
        v.Value = true
        v.Parent = config
    end
    -- Khởi tạo BoolValue cho DisableAtDustCap (mặc định bật)
    if not config:FindFirstChild("DisableAtDustCap") then
        local v = Instance.new("BoolValue")
        v.Name = "DisableAtDustCap"
        v.Value = true
        v.Parent = config
    end
    -- Tạo folder Rarities nếu chưa có
    if not config:FindFirstChild("Rarities") then
        local f = Instance.new("Folder")
        f.Name = "Rarities"
        f.Parent = config
    end
    -- Tạo folder LevelBrackets nếu chưa có
    if not config:FindFirstChild("LevelBrackets") then
        local f = Instance.new("Folder")
        f.Name = "LevelBrackets"
        f.Parent = config
    end
    -- Tạo folder WeaponTypes nếu chưa có
    if not config:FindFirstChild("WeaponTypes") then
        local f = Instance.new("Folder")
        f.Name = "WeaponTypes"
        f.Parent = config
    end
    -- Tạo folder ArmorTypes nếu chưa có
    if not config:FindFirstChild("ArmorTypes") then
        local f = Instance.new("Folder")
        f.Name = "ArmorTypes"
        f.Parent = config
    end
    -- Tạo folder MiscTypes nếu chưa có
    if not config:FindFirstChild("MiscTypes") then
        local f = Instance.new("Folder")
        f.Name = "MiscTypes"
        f.Parent = config
    end
    return config
end
-- Xây dựng danh sách level bracket dựa trên LEVEL_SOFT_CAP
-- Tạo mốc từ 15 đến LEVEL_SOFT_CAP, bước nhảy 15
local function buildLevelBrackets()
    local brackets = {}
    for i = 15, LEVEL_SOFT_CAP, 15 do
        table.insert(brackets, tostring(i))
    end
    local capStr = tostring(LEVEL_SOFT_CAP)
    if not table.find(brackets, capStr) then
        table.insert(brackets, capStr)
    end
    return brackets
end
local LEVEL_BRACKETS = buildLevelBrackets()
-- Hàm đọc BoolValue từ folder config (trả về giá trị hoặc default)
local function readConfigBool(config, name, default)
    if not config then return default end
    local v = config:FindFirstChild(name)
    return v and v.Value or default
end
-- Hàm ghi BoolValue vào folder config
local function writeConfigBool(config, name, value)
    if not config then return end
    local v = config:FindFirstChild(name)
    if not v then
        v = Instance.new("BoolValue")
        v.Name = name
        v.Parent = config
    end
    v.Value = value
end
-- Hàm đọc enabled keys từ folder (BoolValue nào có Value=true thì ghi nhận)
local function readEnabledFolder(folder)
    local result = {}
    if not folder then return result end
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("BoolValue") and child.Value then
            result[child.Name] = true
        end
    end
    return result
end
-- Hàm ghi enabled keys vào folder (set true cho keys có trong list, false cho key cũ không có)
local function writeEnabledFolder(folder, enabledKeys)
    if not folder then return end
    -- Xóa toàn bộ children cũ
    folder:ClearAllChildren()
    -- Tạo BoolValue mới cho mỗi key được bật
    for key, enabled in pairs(enabledKeys) do
        if enabled and typeof(key) == "string" then
            local v = Instance.new("BoolValue")
            v.Name = key
            v.Value = true
            v.Parent = folder
        end
    end
end
-- Map tên rarity → key số (server dùng "1","2",... thay vì "Common","Uncommon",...)
local RARITY_NAME_TO_KEY = {}
for i, name in ipairs(RARITY_NAMES) do
    RARITY_NAME_TO_KEY[name] = tostring(i)
end
-- Hàm trợ giúp: chuyển dropdown selection thành table enabled keys
local function selectionToKeys(selection, allKeys)
    local result = {}
    if typeof(selection) == "table" then
        for _, key in ipairs(selection) do
            result[key] = true
        end
    elseif typeof(selection) == "string" and selection ~= "" then
        result[selection] = true
    end
    return result
end
-- Hàm chuyển rarity name selection thành key số cho server
local function raritySelectionToKeys(selection)
    local result = {}
    local items = typeof(selection) == "table" and selection or {selection}
    for _, name in ipairs(items) do
        local key = RARITY_NAME_TO_KEY[name]
        if key then
            result[key] = true
        end
    end
    return result
end
-- Khởi tạo UI tab Equipment
local EquipTab = Window:CreateTab("Equipment", false, false)
local SettingsTab = Window:CreateTab("Settings", false, false)
local EquipPage = EquipTab:CreatePage("AutoSell")
-- Section cài đặt chung AutoSell
local AutoSellSection = EquipPage:CreateSection("AutoSell Settings")
-- Khởi tạo config trong Profile
local autoSellConfig = initAutoSellConfig()
-- Toggle bật/tắt AutoSell
AutoSellSection:AddToggle("Auto Sell Enabled", readConfigBool(autoSellConfig, "Enabled", false), function(state)
    writeConfigBool(autoSellConfig, "Enabled", state)
end)
-- Toggle chỉ bán item yếu hơn đồ đang equip
AutoSellSection:AddToggle("Sell Worse Than Equipped", readConfigBool(autoSellConfig, "SellWorseThanEquipped", true), function(state)
    writeConfigBool(autoSellConfig, "SellWorseThanEquipped", state)
end)
-- Toggle ngừng bán khi đạt Magic Dust上限
AutoSellSection:AddToggle("Pause At Dust Cap", readConfigBool(autoSellConfig, "DisableAtDustCap", true), function(state)
    writeConfigBool(autoSellConfig, "DisableAtDustCap", state)
end)
-- Section lọc theo Rarity
local RaritySection = EquipPage:CreateSection("Rarity Filter")
-- Dropdown chọn rarity (multi-select)
-- Hiển thị tên rarity đã chọn trong callback
RaritySection:AddDropdown("Sell Rarities", RARITY_NAMES, true, function(selected)
    if not autoSellConfig then return end
    local folder = autoSellConfig:FindFirstChild("Rarities")
    if not folder then return end
    -- Map tên rarity sang key số: "Common"→"1", "Uncommon"→"2", ...
    local keys = raritySelectionToKeys(selected)
    writeEnabledFolder(folder, keys)
end)
-- Section lọc theo Level
local LevelSection = EquipPage:CreateSection("Level Filter")
-- Dropdown chọn level bracket (multi-select)
LevelSection:AddDropdown("Sell Below Level", LEVEL_BRACKETS, true, function(selected)
    if not autoSellConfig then return end
    local folder = autoSellConfig:FindFirstChild("LevelBrackets")
    if not folder then return end
    local keys = selectionToKeys(selected, LEVEL_BRACKETS)
    writeEnabledFolder(folder, keys)
end)
-- Section lọc theo loại vũ khí
local WeaponSection = EquipPage:CreateSection("Weapon Type Filter")
WeaponSection:AddDropdown("Weapon Types", DISCOVERED_WEAPON_TYPES, true, function(selected)
    if not autoSellConfig then return end
    local folder = autoSellConfig:FindFirstChild("WeaponTypes")
    if not folder then return end
    local keys = selectionToKeys(selected, DEFAULT_WEAPON_TYPES)
    writeEnabledFolder(folder, keys)
end)
-- Section lọc theo loại giáp
local ArmorSection = EquipPage:CreateSection("Armor Type Filter")
ArmorSection:AddDropdown("Armor Types", DISCOVERED_ARMOR_TYPES, true, function(selected)
    if not autoSellConfig then return end
    local folder = autoSellConfig:FindFirstChild("ArmorTypes")
    if not folder then return end
    local keys = selectionToKeys(selected, DEFAULT_ARMOR_TYPES)
    writeEnabledFolder(folder, keys)
end)
-- Section lọc theo loại misc (Necklace, Duplicate cosmetics)
local MiscSection = EquipPage:CreateSection("Misc Type Filter")
MiscSection:AddDropdown("Misc Types", DEFAULT_MISC_TYPES, true, function(selected)
    if not autoSellConfig then return end
    local folder = autoSellConfig:FindFirstChild("MiscTypes")
    if not folder then return end
    local keys = selectionToKeys(selected, DEFAULT_MISC_TYPES)
    writeEnabledFolder(folder, keys)
end)
-- Section Auto Eat Food & Auto Use Potion (trong cùng Equipment tab)
local FoodPotionPage = EquipTab:CreatePage("Food & Potion")
-- Auto Eat Food
local FoodSection = FoodPotionPage:CreateSection("Auto Eat Food")
FoodSection:AddToggle("Auto Eat Food", AutoEatFoodEnabled, function(state)
    AutoEatFoodEnabled = state
end)
-- Slider: Ăn food khi thời gian buff còn lại < ngưỡng (giây)
FoodSection:AddSlider("Eat When Time Left < (s)", 5, 120, EatFoodThreshold, function(val)
    EatFoodThreshold = val
end)
-- Auto Use Potion
local PotionSection = FoodPotionPage:CreateSection("Auto Use Potion")
PotionSection:AddToggle("Auto Use Potion", AutoUsePotionEnabled, function(state)
    AutoUsePotionEnabled = state
end)
-- Slider: Khoảng cách giữa 2 lần dùng potion (giây), mặc định 25s (game lockout 20-30s)
PotionSection:AddSlider("Potion Interval (s)", 15, 60, PotionUseInterval, function(val)
    PotionUseInterval = val
end)
-- Section Auto Equip Item (trong cùng Equipment tab)
local AutoEquipPage = EquipTab:CreatePage("Auto Equip")
local AutoEquipSection = AutoEquipPage:CreateSection("Auto Equip Best Item")
-- Toggle auto equip weapon: tự động equip weapon mạnh hơn vào slot Right
AutoEquipSection:AddToggle("Auto Equip Weapon", AutoEquipWeaponEnabled, function(state)
    AutoEquipWeaponEnabled = state
end)
-- Toggle auto equip armor (Shirt/Pants): tự động equip giáp HP cao hơn
AutoEquipSection:AddToggle("Auto Equip Armor", AutoEquipArmorEnabled, function(state)
    AutoEquipArmorEnabled = state
end)
-- Toggle auto equip necklace: tự động equip necklace tốt hơn
AutoEquipSection:AddToggle("Auto Equip Necklace", AutoEquipNecklaceEnabled, function(state)
    AutoEquipNecklaceEnabled = state
end)
-- Vòng lặp giữ AutoSellConfig đồng bộ khi profile thay đổi
-- (phòng trường hợp server reset config hoặc player respawn)
task.spawn(function()
    while task.wait(2) do
        autoSellConfig = initAutoSellConfig()
    end
end)
-- ==========================================
-- AUTO SELL LOOP (Client-side)
-- ==========================================
-- Require Equipment + Currency module (ItemsModule đã require ở trên)
local EquipmentModule = require(ReplicatedStorage.Systems.Equipment)
local CurrencyModule = require(ReplicatedStorage.Systems.Currency)

-- Map cosmetic type → misc key (giống u82 trong AutoSell.txt)
local COSMETIC_TO_MISC = {
    Title = "DuplicateTitles",
    WeaponAura = "DuplicateWeaponAura",
    WeaponCosmetic = "DuplicateWeaponCosmetic",
    ShirtCosmetic = "DuplicateShirtPantsCosmetic",
    PantsCosmetic = "DuplicateShirtPantsCosmetic",
}

-- Lấy max level từ level bracket filter
local function getMaxLevel(levelBrackets)
    local maxLv = 0
    for key, enabled in pairs(levelBrackets) do
        if enabled then
            local num = tonumber(key)
            if num and num > maxLv then
                maxLv = num
            end
        end
    end
    return maxLv
end

-- Kiểm tra Magic Dust đã đạt上限 chưa (giống isAtMagicDustCap)
local function isAtMagicDustCap()
    local profile = LocalPlayer:FindFirstChild("PlayerGui")
        and LocalPlayer.PlayerGui:FindFirstChild("Profile")
    if not profile then return false end
    local currencies = profile:FindFirstChild("Currencies")
    local dust = currencies and currencies:FindFirstChild("MagicDust")
    if not dust then return false end
    local ok, cap = pcall(function()
        return CurrencyModule:GetMagicDustCap()
    end)
    if not ok or not cap then return false end
    return dust.Value >= cap
end

-- So sánh item mới có MẠNH hơn đồ đang equip không (giống isBetterThanEquipped)
-- Trả về true nếu item mới mạnh hơn → KHÔNG nên bán
local function isBetterThanEquipped(item, itemData)
    local category = itemData.Category
    local iType = itemData.Type
    -- Armor: so sánh ArmorHP
    if category == "Armor" then
        if iType ~= "Shirt" and iType ~= "Pants" then return false end
        local ok, equipped = pcall(function()
            return EquipmentModule:GetEquip(LocalPlayer, iType)
        end)
        if not ok or not equipped then
            -- Không có đồ equip → item mới tốt hơn → giữ
            return true
        end
        local okA, newHP = pcall(function()
            return EquipmentModule:GetArmorHP(item)
        end)
        local okB, equippedHP = pcall(function()
            return EquipmentModule:GetArmorHP(equipped)
        end)
        if not okA or not okB then return false end
        -- Item mới HP cao hơn → mạnh hơn → giữ
        return newHP > equippedHP
    end
    -- Weapon: so sánh WeaponAttack + WeaponMagic
    if category == "Weapon" then
        local ok, equipped = pcall(function()
            return EquipmentModule:GetEquip(LocalPlayer, "Right")
        end)
        if not ok or not equipped then
            return true
        end
        local okD2, equippedData = pcall(function()
            return ItemsModule:GetItemData(equipped.Name)
        end)
        if not okD2 or not equippedData then return false end
        -- Kiểm tra cùng attack profile (cùng loại weapon)
        local okM, profileMatch = pcall(function()
            return EquipmentModule:WeaponAttackProfilesMatch(iType, equippedData.Type)
        end)
        if okM and not profileMatch then return false end
        -- Tính tổng damage: Attack + Magic
        local okA, newAtk = pcall(function()
            return EquipmentModule:GetWeaponAttack(item)
        end)
        local okB, newMag = pcall(function()
            return EquipmentModule:GetWeaponMagic(item)
        end)
        local okC, eqAtk = pcall(function()
            return EquipmentModule:GetWeaponAttack(equipped)
        end)
        local okD, eqMag = pcall(function()
            return EquipmentModule:GetWeaponMagic(equipped)
        end)
        if not (okA and okB and okC and okD) then return false end
        local newTotal = newAtk + newMag
        local eqTotal = eqAtk + eqMag
        return newTotal > eqTotal
    end
    return false
end

-- Quét inventory mỗi 2s, bán item nào match filter qua SellItem:FireServer()
-- Logic giống ShouldAutoSell trong AutoSell.txt (đầy đủ 100%)
task.spawn(function()
    while task.wait(2) do
        if not autoSellConfig then continue end
        if not readConfigBool(autoSellConfig, "Enabled", false) then continue end
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local profile = playerGui and playerGui:FindFirstChild("Profile")
        if not profile then continue end
        -- Kiểm tra DisableAtDustCap: nếu bật và đã đạt cap → ngừng bán
        local disableAtCap = readConfigBool(autoSellConfig, "DisableAtDustCap", true)
        if disableAtCap and isAtMagicDustCap() then continue end
        -- Đọc SellWorseThanEquipped
        local sellWorse = readConfigBool(autoSellConfig, "SellWorseThanEquipped", true)
        -- Đọc filter từ config
        local rarities = readEnabledFolder(autoSellConfig:FindFirstChild("Rarities"))
        local levelBrackets = readEnabledFolder(autoSellConfig:FindFirstChild("LevelBrackets"))
        local weaponTypes = readEnabledFolder(autoSellConfig:FindFirstChild("WeaponTypes"))
        local armorTypes = readEnabledFolder(autoSellConfig:FindFirstChild("ArmorTypes"))
        local miscTypes = readEnabledFolder(autoSellConfig:FindFirstChild("MiscTypes"))
        -- Gộp WeaponTypes + ArmorTypes thành GearTypes (giống mergeGearTypesMap)
        local gearTypes = {}
        for k, v in pairs(weaponTypes) do gearTypes[k] = v end
        for k, v in pairs(armorTypes) do gearTypes[k] = v end
        -- Kiểm tra có filter nào bật không
        local hasGearFilter = next(gearTypes) ~= nil
        local hasMiscFilter = next(miscTypes) ~= nil
        if not hasGearFilter and not hasMiscFilter then continue end
        -- Tính max level từ bracket
        local maxLevel = getMaxLevel(levelBrackets)
        local hasLevelFilter = maxLevel > 0
        -- Thu thập item từ Inventory + ItemBank
        local sellList = {}
        local function scanFolder(folder)
            if not folder then return end
            for _, item in ipairs(folder:GetChildren()) do
                if typeof(item) ~= "Instance" then continue end
                -- Lấy ItemData từ Items module
                local ok, itemData = pcall(function()
                    return ItemsModule:GetItemData(item.Name)
                end)
                if not ok or not itemData then continue end
                -- Bỏ qua Mastery Reward (giống ShouldAutoSell)
                local okM, isMastery = pcall(function()
                    return ItemsModule:ItemIsMasteryReward(itemData)
                end)
                if okM and isMastery then continue end
                local category = itemData.Category
                local iType = itemData.Type
                -- Xác định item thuộc gear hay misc
                local isGear = (category == "Weapon") or (category == "Armor")
                local miscKey = nil
                if category == "Necklace" then
                    miscKey = "Necklace"
                elseif category == "Cosmetic" then
                    miscKey = COSMETIC_TO_MISC[iType]
                end
                local isMisc = miscKey ~= nil
                -- Bỏ qua item không thuộc filter nào
                if isGear and not hasGearFilter then isGear = false end
                if isMisc and not hasMiscFilter then isMisc = false end
                if not isGear and not isMisc then continue end
                -- Kiểm tra type match trong filter
                if isGear and not gearTypes[iType] then continue end
                if isMisc and not miscTypes[miscKey] then continue end
                -- Bỏ qua item đã favorite hoặc sealed
                local okFav, isFav = pcall(function()
                    return ItemsModule:ItemIsFavorited(item)
                end)
                if okFav and isFav then continue end
                if item:FindFirstChild("Sealed") then continue end
                -- Đọc rarity
                local okR, rarity = pcall(function()
                    return ItemsModule:GetRarity(item)
                end)
                if not okR then rarity = 0 end
                -- Bỏ qua rarity > 6 (Mythic+)
                if rarity > 6 then continue end
                -- Kiểm tra rarity có trong filter không
                if not rarities[tostring(rarity)] then continue end
                -- Kiểm tra level bracket
                if hasLevelFilter then
                    local level = 1
                    local lvChild = item:FindFirstChild("Level")
                    if lvChild then
                        level = lvChild.Value
                    else
                        level = itemData.Level or 1
                    end
                    if level > maxLevel then continue end
                end
                -- SellWorseThanEquipped: chỉ bán item yếu hơn đồ đang mặc
                if sellWorse and isGear then
                    if isBetterThanEquipped(item, itemData) then
                        continue -- Item mạnh hơn → giữ, không bán
                    end
                end
                -- Duplicate cosmetic: chỉ bán nếu có > 1 cái cùng tên
                if isMisc and miscKey ~= "Necklace" then
                    local owned = 0
                    for _, other in ipairs(folder:GetChildren()) do
                        if other.Name == item.Name then
                            owned = owned + 1
                        end
                    end
                    if owned <= 1 then continue end
                end
                table.insert(sellList, item)
            end
        end
        scanFolder(profile:FindFirstChild("Inventory"))
        scanFolder(profile:FindFirstChild("ItemBank"))
        if #sellList > 0 then
            pcall(function()
                SellItemEvent:FireServer(sellList, {})
            end)
        end
    end
end)
-- ==========================================
-- AUTO EAT FOOD LOOP (Client-side)
-- ==========================================
-- Tự động ăn food khi thời gian buff sắp hết (< ngưỡng)
-- Ưu tiên ăn cùng loại food (stack timer) thay vì khác loại (reset timer)
task.spawn(function()
    while task.wait(2) do
        if not AutoEatFoodEnabled then continue end
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local profile = playerGui and playerGui:FindFirstChild("Profile")
        if not profile then continue end
        -- Kiểm tra EquippedFood.TimeLeft — nếu còn đủ thời gian thì bỏ qua
        local equippedFood = profile:FindFirstChild("EquippedFood")
        local timeLeftVal = equippedFood and equippedFood:FindFirstChild("TimeLeft")
        if timeLeftVal and timeLeftVal.Value > EatFoodThreshold then continue end
        -- Lấy loại food đang equip (Type) để ưu tiên ăn cùng loại → stack timer
        local itemNameVal = equippedFood and equippedFood:FindFirstChild("ItemName")
        local currentFoodType = nil
        if itemNameVal and itemNameVal.Value ~= "" then
            local ok, data = pcall(function()
                return ItemsModule:GetItemData(itemNameVal.Value)
            end)
            if ok and data then currentFoodType = data.Type end
        end
        -- Quét inventory tìm food item phù hợp
        local inventory = profile:FindFirstChild("Inventory")
        if not inventory then continue end
        local sameTypeFood = nil  -- Ưu tiên: cùng loại (stack timer)
        local bestFood = nil      -- Fallback: food có Duration dài nhất
        local bestDuration = 0
        for _, item in ipairs(inventory:GetChildren()) do
            local ok, data = pcall(function()
                return ItemsModule:GetItemData(item.Name)
            end)
            if ok and data and data.Category == "Food" then
                -- Nếu cùng loại food đang equip → ưu tiên ăn ngay
                if currentFoodType and data.Type == currentFoodType then
                    sameTypeFood = item
                    break -- Tìm thấy cùng loại, không cần tìm tiếp
                end
                -- Nếu khác loại, chọn food có Duration dài nhất
                local dur = data.Duration or 0
                if dur > bestDuration then
                    bestFood = item
                    bestDuration = dur
                end
            end
        end
        -- Ưu tiên ăn cùng loại, nếu k có thì ăn loại tốt nhất
        local foodToEat = sameTypeFood or bestFood
        if foodToEat then
            pcall(function()
                EquipFoodEvent:FireServer(foodToEat)
            end)
        end
    end
end)
-- ==========================================
-- AUTO USE POTION LOOP (Client-side)
-- ==========================================
-- Tự động dùng potion đã equip theo interval
-- Server tự xử lý cooldown (20s hoặc 30s), client chỉ cần bắn đúng interval
local lastPotionUseTick = 0
task.spawn(function()
    while task.wait(1) do
        if not AutoUsePotionEnabled then continue end
        -- Kiểm tra interval để tránh spam remote
        local now = tick()
        if now - lastPotionUseTick < PotionUseInterval then continue end
        -- Kiểm tra có potion đang equip không
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local profile = playerGui and playerGui:FindFirstChild("Profile")
        if not profile then continue end
        local equipped = profile:FindFirstChild("Equipped")
        local potionFolder = equipped and equipped:FindFirstChild("Potion")
        -- Potion equip slot: item được move vào Profile.Equipped.Potion
        local equippedPotion = potionFolder and potionFolder:GetChildren()[1]
        if not equippedPotion then continue end
        -- Fire remote để server xử lý dùng potion
        pcall(function()
            UsePotionEvent:FireServer()
        end)
        lastPotionUseTick = now
    end
end)
-- ==========================================
-- AUTO EQUIP LOOP (Client-side)
-- ==========================================
-- Tự động equip item mạnh hơn vào slot tương ứng (Weapon, Armor, Necklace)
-- Mỗi 3s quét inventory, so sánh với đồ đang equip, equip cái tốt nhất
task.spawn(function()
    while task.wait(3) do
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local profile = playerGui and playerGui:FindFirstChild("Profile")
        if not profile then continue end
        local inventory = profile:FindFirstChild("Inventory")
        if not inventory then continue end
        -- Tính max level player đang có (để check level requirement)
        local playerLevel = 1
        local levelVal = profile:FindFirstChild("Level")
        if levelVal then playerLevel = levelVal.Value end

        -- ===== AUTO EQUIP WEAPON =====
        -- Tìm weapon mạnh nhất trong inventory (cùng attack profile với equipped)
        -- rồi equip vào slot Right nếu tốt hơn
        if AutoEquipWeaponEnabled then
            -- Lấy equipped weapon để biết attack profile hiện tại
            local ok, equipped = pcall(function()
                return EquipmentModule:GetEquip(LocalPlayer, "Right")
            end)
            local equippedType = nil
            if ok and equipped then
                local okD, eData = pcall(function()
                    return ItemsModule:GetItemData(equipped.Name)
                end)
                if okD and eData then equippedType = eData.Type end
            end
            -- Quét inventory tìm weapon tốt nhất
            local bestWeapon = nil
            local bestWeaponTotal = 0
            for _, item in ipairs(inventory:GetChildren()) do
                local okI, iData = pcall(function()
                    return ItemsModule:GetItemData(item.Name)
                end)
                if okI and iData and iData.Category == "Weapon" then
                    -- Check level requirement
                    local itemLevel = iData.Level or 1
                    if itemLevel <= playerLevel then
                        -- Check cùng attack profile (cùng loại weapon)
                        -- Nếu chưa có weapon equipped → chấp nhận bất kỳ weapon nào
                        if equippedType then
                            local okM, match = pcall(function()
                                return EquipmentModule:WeaponAttackProfilesMatch(iData.Type, equippedType)
                            end)
                            if not (okM and match) then continue end
                        end
                        -- Tính tổng damage
                        local okA, atk = pcall(function()
                            return EquipmentModule:GetWeaponAttack(item)
                        end)
                        local okB, mag = pcall(function()
                            return EquipmentModule:GetWeaponMagic(item)
                        end)
                        if okA and okB then
                            local total = (atk or 0) + (mag or 0)
                            if total > bestWeaponTotal then
                                bestWeaponTotal = total
                                bestWeapon = item
                            end
                        end
                    end
                end
            end
            -- Nếu tìm được weapon tốt hơn → so sánh với equipped rồi equip
            if bestWeapon then
                local shouldEquip = false
                if not equipped then
                    -- Chưa có weapon → equip luôn
                    shouldEquip = true
                else
                    -- So sánh: weapon mới phải mạnh hơn equipped
                    local okA, newAtk = pcall(function()
                        return EquipmentModule:GetWeaponAttack(bestWeapon)
                    end)
                    local okB, newMag = pcall(function()
                        return EquipmentModule:GetWeaponMagic(bestWeapon)
                    end)
                    local okC, eqAtk = pcall(function()
                        return EquipmentModule:GetWeaponAttack(equipped)
                    end)
                    local okD, eqMag = pcall(function()
                        return EquipmentModule:GetWeaponMagic(equipped)
                    end)
                    if okA and okB and okC and okD then
                        local newTotal = (newAtk or 0) + (newMag or 0)
                        local eqTotal = (eqAtk or 0) + (eqMag or 0)
                        if newTotal > eqTotal then
                            shouldEquip = true
                        end
                    end
                end
                if shouldEquip then
                    pcall(function()
                        EquipWeaponEvent:FireServer("Right", bestWeapon)
                    end)
                end
            end
        end

        -- ===== AUTO EQUIP ARMOR =====
        -- Tìm giáp HP cao nhất cho mỗi slot (Shirt, Pants) rồi equip
        if AutoEquipArmorEnabled then
            for _, armorType in ipairs({"Shirt", "Pants"}) do
                -- Lấy equipped armor cho slot này
                local ok, equipped = pcall(function()
                    return EquipmentModule:GetEquip(LocalPlayer, armorType)
                end)
                local equippedHP = 0
                if ok and equipped then
                    local okH, hp = pcall(function()
                        return EquipmentModule:GetArmorHP(equipped)
                    end)
                    if okH then equippedHP = hp or 0 end
                end
                -- Quét inventory tìm armor tốt nhất cho slot này
                local bestArmor = nil
                local bestArmorHP = equippedHP -- Chỉ equip nếu HP cao hơn
                for _, item in ipairs(inventory:GetChildren()) do
                    local okI, iData = pcall(function()
                        return ItemsModule:GetItemData(item.Name)
                    end)
                    if okI and iData and iData.Category == "Armor" and iData.Type == armorType then
                        local itemLevel = iData.Level or 1
                        if itemLevel <= playerLevel then
                            local okH, hp = pcall(function()
                                return EquipmentModule:GetArmorHP(item)
                            end)
                            if okH and (hp or 0) > bestArmorHP then
                                bestArmorHP = hp or 0
                                bestArmor = item
                            end
                        end
                    end
                end
                -- Equip armor tốt hơn nếu tìm thấy
                if bestArmor then
                    pcall(function()
                        EquipArmorEvent:FireServer(bestArmor)
                    end)
                    task.wait(0.2) -- Delay nhỏ giữa 2 lần equip armor
                end
            end
        end

        -- ===== AUTO EQUIP NECKLACE =====
        -- Tìm necklace tốt nhất (ưu tiên Rarity cao hơn, nếu cùng rarity thì equip cái đầu tiên)
        if AutoEquipNecklaceEnabled then
            local ok, equipped = pcall(function()
                return EquipmentModule:GetEquip(LocalPlayer, "Necklace")
            end)
            -- Nếu đã có necklace → giữ nguyên (necklace không có stat rõ ràng để so sánh)
            -- Chỉ equip nếu chưa có necklace
            if not (ok and equipped) then
                for _, item in ipairs(inventory:GetChildren()) do
                    local okI, iData = pcall(function()
                        return ItemsModule:GetItemData(item.Name)
                    end)
                    if okI and iData and iData.Category == "Necklace" then
                        pcall(function()
                            EquipNecklaceEvent:FireServer(item)
                        end)
                        break -- Chỉ equip 1 necklace
                    end
                end
            end
        end
    end
end)
-- ==========================================
-- AUTO PICKUP LOOP (Client-side)
-- ==========================================
-- Tự động nhặt drop thuộc về player, lọc theo rarity tối thiểu
-- Quét ReplicatedStorage.Drops mỗi 0.5s, fire Pickup remote cho drop phù hợp
task.spawn(function()
    while task.wait(0.5) do
        if not AutoPickupEnabled then continue end
        if not DropsFolder then continue end
        local playerName = LocalPlayer.Name
        for _, drop in ipairs(DropsFolder:GetChildren()) do
            -- Chỉ nhặt drop thuộc về mình (attribute Owner == tên player)
            local owner = drop:GetAttribute("Owner")
            if owner ~= playerName then continue end
            -- Bỏ qua drop shop (có attribute Price)
            if drop:GetAttribute("Price") then continue end
            -- Fire remote nhặt item
            pcall(function()
                PickupEvent:FireServer(drop)
            end)
        end
    end
end)
-- Vòng lặp chính Auto Attack
task.spawn(function()
    while task.wait(getRandomDelay()) do
        if not Enabled or not Mobs then continue end
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        local targets = getTargets(root)
        if #targets > 0 then
            AttackRemote:FireServer(targets, nil)
        end
    end
end)
-- Vòng lặp Auto Pet Attack
-- Cache attack info theo pet instance để tránh lookup mỗi tick
local CachedPetAttack = {}
task.spawn(function()
    while task.wait(PetAttackDelay) do
        if not PetAttackEnabled or not Mobs then continue end
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        local pet = getPet()
        if not pet then continue end
        -- Cache attack info: chỉ lookup 1 lần cho mỗi pet instance
        if not CachedPetAttack[pet] then
            CachedPetAttack[pet] = { getPetAttackInfo(pet) }
        end
        local attackType, attackShape = CachedPetAttack[pet][1], CachedPetAttack[pet][2]
        -- Tìm target gần nhất để dồn dame
        local closest, closestDist = nil, math.huge
        for _, mob in ipairs(Mobs:GetChildren()) do
            if isValidMob(mob) then
                local dist = (mob.PrimaryPart.Position - root.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = mob
                end
            end
        end
        if closest then
            for i = 1, PetAttackLoop do
                pcall(function()
                    PetDamage:FireServer(pet, attackType, attackShape, {closest}, closest.PrimaryPart.Position)
                end)
            end
        end
    end
end)
-- Vòng lặp Auto Break Destructibles
task.spawn(function()
    while task.wait(BreakDelay) do
        if not BreakEnabled or not Destructibles then continue end
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        local target = getNearestDestructible(root)
        if target then
            BreakRemote:FireServer(target)
        end
    end
end)
-- Vòng lặp Auto Favorite Pet
task.spawn(function()
    while true do
        -- Bỏ qua nếu tắt, đỡ tốn cycle
        if not AutoFavoriteEnabled then task.wait(1); continue end
        local profile = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("Profile")
        if not profile then task.wait(1); continue end
        -- Duyệt pet trong kho (Inventory)
        local petsFolder = profile:FindFirstChild("Pets")
        if petsFolder then
            for _, pet in ipairs(petsFolder:GetChildren()) do
                -- Kiểm tra lại giữa chừng phòng user tắt giữa chừng
                if not AutoFavoriteEnabled then break end
                if not pet:FindFirstChild("Favorite") then
                    pcall(function()
                        ToggleFavoriteEvent:InvokeServer(pet)
                    end)
                    task.wait(0.1)
                end
            end
        end
        -- Duyệt pet đang equip
        local equippedFolder = profile:FindFirstChild("Equipped") and profile.Equipped:FindFirstChild("Pet")
        if equippedFolder then
            for _, pet in ipairs(equippedFolder:GetChildren()) do
                if not AutoFavoriteEnabled then break end
                if not pet:FindFirstChild("Favorite") then
                    pcall(function()
                        ToggleFavoriteEvent:InvokeServer(pet)
                    end)
                    task.wait(0.1)
                end
            end
        end
        task.wait(1)
    end
end)
-- ==========================================
-- SETTINGS TAB — Config Manager
-- ==========================================
-- ZyronX AddConfigManager tự động lưu/tải tất cả toggle, slider, dropdown
-- File config lưu tại: workspace/DungeonHeros_Config.json
local SettingsPage = SettingsTab:CreatePage("Configuration")
local ConfigSection = SettingsPage:CreateSection("Config Manager")
ConfigSection:AddConfigManager("DungeonHeros")
-- Vòng lặp Auto Open Pet Chest
task.spawn(function()
    while true do
        if AutoOpenChestEnabled then
            local profile = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("Profile")
            local inventoryFolder = profile and profile:FindFirstChild("Inventory")
            if inventoryFolder then
                local hasChest = false
                for _, item in ipairs(inventoryFolder:GetChildren()) do
                    if not AutoOpenChestEnabled then break end
                    if string.find(item.Name, "PetChest") then
                        hasChest = true
                        pcall(function()
                            OpenChestEvent:FireServer(item, 1)
                        end)
                        task.wait(0.5)
                    end
                end
                -- Hết chest thì tắt tự động
                if not hasChest then
                    AutoOpenChestEnabled = false
                end
            end
        end
        task.wait(1)
    end
end)
-- Vòng lặp Auto Merge Pet
task.spawn(function()
    while true do
        if AutoMergeEnabled then
            local profile = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("Profile")
            local petsFolder = profile and profile:FindFirstChild("Pets")
            if petsFolder then
                for _, pet in ipairs(petsFolder:GetChildren()) do
                    if not AutoMergeEnabled then break end
                    pcall(function()
                        UpgradePetEvent:FireServer(pet)
                    end)
                    task.wait(0.05)
                end
            end
        end
        task.wait(1)
    end
end)