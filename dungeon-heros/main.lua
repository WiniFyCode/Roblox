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
local Mobs = workspace:FindFirstChild("Mobs")
local Destructibles = workspace:FindFirstChild("Destructibles")

-- Cấu hình mặc định cho auto attack.
local Enabled = true
local MinDelay = 0.1
local MaxDelay = 0.25

-- Cấu hình mặc định cho auto break destructible.
local BreakEnabled = true
local BreakDelay = 0.1

-- Cấu hình mặc định cho auto pet attack.
local PetAttackEnabled = true
local PetAttackDelay = 0.05 -- Delay giữa mỗi lần gửi attack (giây)
local PetAttackLoop = 5 -- Số lần fire attack per tick

-- Cấu hình mặc định cho auto pet management.
local AutoFavoriteEnabled = false
local AutoOpenChestEnabled = false
local AutoMergeEnabled = false

-- Cấu hình mặc định cho di chuyển & Noclip.
local SpeedEnabled = true
local WalkSpeed = 60
local InfiniteJumpEnabled = true
local NoclipEnabled = true

-- Cấu hình cho Tween To Mob
local TweenToMobEnabled = false
local TweenHeight = 20
local TweenSpeed = 100
local FlyConnection = nil

-- Cấu hình mặc định cho ESP mobs.
local MobEspEnabled = true
local MobNameEspEnabled = true
local MobDistanceEspEnabled = true
local MobHealthEspEnabled = true
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
        if not Mobs then clearMobHighlights(); clearMobNameTags(); coDntinue end
        for _, mob in ipairs(Mobs:GetChildren()) do updateMobHighlight(mob); updateMobNameTag(mob) end
        if not MobEspEnabled then for _, hl in pairs(MobHighlights) do hl.Enabled = false end end
        if not MobNameEspEnabled and not MobDistanceEspEnabled and not MobHealthEspEnabled then
            for _, tag in pairs(MobNameTags) do tag.Enabled = false end
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
        if AutoFavoriteEnabled then
            local profile = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("Profile")
            if profile then
                -- Duyệt pet trong kho (Inventory)
                local petsFolder = profile:FindFirstChild("Pets")
                if petsFolder then
                    for _, pet in ipairs(petsFolder:GetChildren()) do
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
            end
        end
        task.wait(1)
    end
end)

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