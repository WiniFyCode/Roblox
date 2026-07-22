-- ============================================
-- ZyronX UI + Auto Farm (Click Attack + Multi-Skill)
-- ============================================
local Library = loadstring(game:HttpGetAsync(
    "https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/UI/zyronx.luau"))()

local Window = Library:CreateWindow({
    Title = "WiniFy x Zyronx UI",
    Subtitle = "Click Attack Only",
    SubtitleColor = Color3.fromRGB(190, 140, 255),
    Logo = "rbxassetid://82367817676382",
    LogoSize = 28
})

local MainTab = Window:CreateTab("Combat", true, false)
local FarmPage = MainTab:CreatePage("Auto Farm")
local CombatSection = FarmPage:CreateSection("Modules")

-- ===== GLOBAL VARIABLES & APIS =====
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local API = game:GetService("ReplicatedStorage"):FindFirstChild("API")
local NetworkAPI = API and API:FindFirstChild("Utils") and API.Utils:FindFirstChild("network")

local function HookAttack()
    for _, v in pairs(getgc(true)) do
        if typeof(v) == "function" and getfenv(v).script and getfenv(v).script.Name == "combat_manager" then
            local name = debug.getinfo(v).name
            if name == "Attack" then
                return v
            end
        end
    end
    return nil
end
local AttackFunc = HookAttack()

local function RedeemAllCodes()
    if NetworkAPI then
        local network = require(NetworkAPI)
        local codesToClaim = {"release", "update", "morecoming", "leveling"}
        for _, code in ipairs(codesToClaim) do
            network.SendServer("codes", code)
            task.wait(0.5)
        end
        Library:Notify({
            Title = "Redeem",
            Description = "Done!",
            Duration = 2
        })
    end
end

_G.InstantKill = false
_G.AutoFarm = false
_G.AutoAttack = false
_G.AutoCollect = false
_G.SelectedEnemies = {}
_G.FarmAll = false
_G.CurrentTarget = nil
_G.ESP = false
_G.PlayerESP = false

local enemiesModule = require(game:GetService("ReplicatedStorage").API.enemies)
local enemyList = {}
local enemyData = {}
for name, data in pairs(enemiesModule.Enemies) do
    local key = name .. " | Lvl: " .. data.Level
    table.insert(enemyList, key)
    enemyData[key] = {
        name = name,
        level = data.Level
    }
end
table.sort(enemyList, function(a, b)
    return enemyData[a].level < enemyData[b].level
end)

-- ===== AUTO COLLECT DROPS =====
local function AutoCollectDrops()
    if not _G.AutoCollect then
        return
    end
    local drops = workspace:FindFirstChild("Drops")
    if not drops then
        return
    end

    for _, drop in pairs(drops:GetChildren()) do
        local prompt = drop:FindFirstChildWhichIsA("ProximityPrompt")
        if prompt then
            fireproximityprompt(prompt)
        end

        if NetworkAPI then
            local network = require(NetworkAPI)
            network.SendServer("drop_pickup", drop.Name)
        end
        task.wait(0.1)
    end
end
local function DoInstantKill()
    for _, enemy in pairs(workspace.Enemies:GetChildren()) do
        local hum = enemy:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 and hum.Health < hum.MaxHealth then
            hum.Health = 0
        end
    end
end

local lastAttackTime = 0
local ATTACK_COOLDOWN = 0.25

local function ExecuteAttack()
    if AttackFunc then
        local now = tick()
        if now - lastAttackTime < ATTACK_COOLDOWN then
            return
        end
        lastAttackTime = now
        AttackFunc()
    end
end

-- ===== AUTO ATTACK LOOP (no teleport) =====
local function AutoAttackLoop()
    if not _G.AutoAttack then return end
    local character = Player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local nearestDist = math.huge
    local target = nil
    for _, enemy in pairs(workspace.Enemies:GetChildren()) do
        local eHum = enemy:FindFirstChildOfClass("Humanoid")
        local eHRP = enemy:FindFirstChild("HumanoidRootPart")
        if eHum and eHum.Health > 0 and eHRP then
            local dist = (hrp.Position - eHRP.Position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                target = enemy
            end
        end
    end

    if target and target:FindFirstChild("HumanoidRootPart") then
        -- Face towards enemy
        local targetPos = target.HumanoidRootPart.Position
        local lookAt = Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z)
        hrp.CFrame = CFrame.new(hrp.Position, lookAt)
        ExecuteAttack()
    end
end

-- ===== AUTO FARM LOOP =====
local function AutoFarmLoop()
    if not _G.AutoFarm then
        return
    end
    local character = Player.Character
    if not character then
        return
    end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then
        return
    end

    local target = nil

    if #_G.SelectedEnemies > 0 then
        for _, selectedKey in ipairs(_G.SelectedEnemies) do
            local selectedData = enemyData[selectedKey]
            if selectedData then
                local nearestDist = math.huge
                for _, enemy in pairs(workspace.Enemies:GetChildren()) do
                    if enemy:GetAttribute("enemy") == selectedData.name and enemy:GetAttribute("level") ==
                        selectedData.level then
                        local eHum = enemy:FindFirstChild("Humanoid")
                        local eHRP = enemy:FindFirstChild("HumanoidRootPart")
                        if eHum and eHum.Health > 0 and eHRP then
                            local dist = (hrp.Position - eHRP.Position).Magnitude
                            if dist < nearestDist then
                                nearestDist = dist
                                target = enemy
                            end
                        end
                    end
                end
            end
            if target then
                break
            end
        end
    end

    if not target and _G.FarmAll then
        local nearestDist = math.huge
        for _, enemy in pairs(workspace.Enemies:GetChildren()) do
            local eHum = enemy:FindFirstChild("Humanoid")
            local eHRP = enemy:FindFirstChild("HumanoidRootPart")
            if eHum and eHum.Health > 0 and eHRP then
                local dist = (hrp.Position - eHRP.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    target = enemy
                end
            end
        end
    end

    if target and target:FindFirstChild("HumanoidRootPart") then
        local targetHRP = target.HumanoidRootPart
        local behindPos = targetHRP.CFrame * CFrame.new(0, 0, 10)
        hrp.CFrame = behindPos
        local lookAt = Vector3.new(targetHRP.Position.X, hrp.Position.Y, targetHRP.Position.Z)
        hrp.CFrame = CFrame.new(hrp.Position, lookAt)
        ExecuteAttack()
    end
end

-- ===== ESP MOB =====
local function UpdateESP()
    for _, enemy in pairs(workspace.Enemies:GetChildren()) do
        local hl = enemy:FindFirstChild("ZX_MobESP")
        if _G.ESP then
            if not hl then
                hl = Instance.new("Highlight", enemy)
                hl.Name = "ZX_MobESP"
                hl.FillColor = Color3.fromRGB(255, 0, 0)
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            end
            hl.Enabled = true
        else
            if hl then
                hl:Destroy()
            end
        end
    end
end

-- ===== ESP PLAYER =====
local playerESPObjects = {}
local function SetupPlayerESP(plr)
    if plr == Player then
        return
    end
    local function applyToCharacter(character)
        task.wait(0.5)
        local head = character:FindFirstChild("Head")
        local hum = character:FindFirstChildOfClass("Humanoid")
        if not head or not hum then
            return
        end

        local hl = character:FindFirstChild("ZX_PlayerESP") or Instance.new("Highlight", character)
        hl.Name = "ZX_PlayerESP";
        hl.FillTransparency = 0.8;
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.Enabled = _G.PlayerESP

        local bb = head:FindFirstChild("ZX_PlayerInfo") or Instance.new("BillboardGui", head)
        bb.Name = "ZX_PlayerInfo";
        bb.Size = UDim2.new(0, 110, 0, 38);
        bb.StudsOffset = Vector3.new(0, 3, 0);
        bb.AlwaysOnTop = true

        local label = bb:FindFirstChild("Info") or Instance.new("TextLabel", bb)
        label.Name = "Info";
        label.Size = UDim2.new(1, 0, 1, 0);
        label.BackgroundTransparency = 1
        label.TextSize = 13;
        label.TextScaled = false;
        label.Font = Enum.Font.GothamBold
        label.TextColor3 = Color3.fromRGB(255, 255, 255);
        label.TextStrokeTransparency = 0.3
        label.TextXAlignment = Enum.TextXAlignment.Center;
        label.TextYAlignment = Enum.TextYAlignment.Center

        playerESPObjects[plr] = {
            character = character,
            highlight = hl,
            billboard = bb,
            label = label
        }
    end

    if plr.Character then
        applyToCharacter(plr.Character)
    end
    plr.CharacterAdded:Connect(applyToCharacter)
end

local function UpdatePlayerESPInfo()
    if not _G.PlayerESP then
        return
    end
    for plr, data in pairs(playerESPObjects) do
        if data.character and data.label then
            local level = plr:GetAttribute("level") or "?"
            local health = plr:GetAttribute("health") or 0
            local maxHealth = plr:GetAttribute("max_health") or 0
            local world = plr:GetAttribute("world") or "N/A"
            data.label.Text = string.format(
                "%s | %s | Lv.%s | %d/%d HP | %s",
                plr.DisplayName,
                job,
                level,
                math.floor(health),
                math.floor(maxHealth),
                world
            )
        end
    end
end

local function RemovePlayerESP(plr)
    local data = playerESPObjects[plr]
    if data then
        if data.highlight then
            data.highlight:Destroy()
        end
        if data.billboard then
            data.billboard:Destroy()
        end
        playerESPObjects[plr] = nil
    end
end

for _, plr in pairs(Players:GetPlayers()) do
    SetupPlayerESP(plr)
end
Players.PlayerAdded:Connect(SetupPlayerESP)
Players.PlayerRemoving:Connect(RemovePlayerESP)

-- Main Loop
RunService.Heartbeat:Connect(function()
    if _G.InstantKill then
        DoInstantKill()
    end
    if _G.AutoAttack then
        AutoAttackLoop()
    end
    if _G.AutoFarm then
        AutoFarmLoop()
    end
    if _G.AutoCollect then
        AutoCollectDrops()
    end
    UpdateESP()
    UpdatePlayerESPInfo()
end)

-- ===== UI COMPONENTS (Combat Tab) =====
-- Enemy Dropdown
CombatSection:AddDropdown("Select Enemy", enemyList, true, function(selected)
    _G.SelectedEnemies = selected or {}
end, {
    Title = "Select Enemy",
    Description = "Choose enemies (name + level) to auto farm."
})

-- Auto Farm Toggle
CombatSection:AddToggle("Auto Farm", false, function(state)
    _G.AutoFarm = state
end, {
    Title = "Auto Farm",
    Description = "Auto teleport behind enemy, click attack + skill."
})

-- Auto Attack Toggle (no teleport)
CombatSection:AddToggle("Auto Attack", false, function(state)
    _G.AutoAttack = state
end, {
    Title = "Auto Attack",
    Description = "Attack nearest enemy without teleporting."
})

-- Farm All Toggle
CombatSection:AddToggle("Farm All", false, function(state)
    _G.FarmAll = state
    if state then
        Library:Notify({
            Title = "Farm All",
            Description = "Priority: selected mobs first, then nearest.",
            Duration = 2
        })
    end
end, {
    Title = "Farm All (Nearest)",
    Description = "Prioritize selected mobs. If none found -> farm nearest.",
    Example = "Combine with dropdown for targeted farming."
})

-- Instant Kill Toggle
CombatSection:AddToggle("Instant Kill", false, function(state)
    _G.InstantKill = state
end, {
    Title = "Instant Kill",
    Description = "Kill enemies instantly on hit."
})

-- Auto Collect Toggle
CombatSection:AddToggle("Auto Collect", false, function(state)
    _G.AutoCollect = state
end, {
    Title = "Auto Collect",
    Description = "Auto teleport to and collect nearby drops."
})

-- ESP Mob Toggle
CombatSection:AddToggle("ESP Highlight", false, function(state)
    _G.ESP = state
    if not state then
        for _, enemy in pairs(workspace.Enemies:GetChildren()) do
            local hl = enemy:FindFirstChild("ZX_MobESP")
            if hl then
                hl:Destroy()
            end
        end
    end
end, {
    Title = "ESP Mob",
    Description = "Red outline around mobs, visible through walls."
})

-- ESP Player Toggle
CombatSection:AddToggle("Player ESP", false, function(state)
    _G.PlayerESP = state
    for plr, data in pairs(playerESPObjects) do
        if data.highlight then
            data.highlight.Enabled = state
        end
        if data.billboard then
            data.billboard.Enabled = state
        end
    end
end, {
    Title = "ESP Player",
    Description = "Blue outline + name/level/job/HP above players."
})

-- ===== UTILITY TAB =====
local UtilityTab = Window:CreateTab("Utility", false, false)
local UtilPage = UtilityTab:CreatePage("Main")
local UtilSection = UtilPage:CreateSection("Codes & Misc")

UtilSection:AddButton("Redeem All Codes", function()
    RedeemAllCodes()
end, {
    Title = "Redeem All Codes",
    Description = "Auto redeem available game codes."
})

-- ===== AUTO DUNGEON: TOWER & RAID =====
local DungeonTab = Window:CreateTab("Dungeon", false, false)
local DungeonPage = DungeonTab:CreatePage("Main")
local DungeonSection = DungeonPage:CreateSection("Auto Settings")

_G.AutoTower = false
_G.AutoRaid = false

-- Auto Tower
DungeonSection:AddToggle("Auto Tower", false, function(state)
    _G.AutoTower = state
    if state then
        Library:Notify({
            Title = "Auto Tower",
            Description = "Auto farming tower floors.",
            Duration = 2
        })
        task.spawn(function()
            while _G.AutoTower do
                local network = require(NetworkAPI)
                network.SendServer("tower_enter")
                task.wait(10)
            end
        end)
    end
end, {
    Title = "Auto Tower",
    Description = "Auto farming tower floors."
})

-- Auto Raid
_G.SelectedRaid = "Throne Room"
local raidList = {"Throne Room", "Infinity Realm"}

DungeonSection:AddDropdown("Select Raid", raidList, false, function(selected)
    _G.SelectedRaid = selected
end, {
    Title = "Select Raid",
    Description = "Choose the raid level you want to farm."
})

DungeonSection:AddToggle("Auto Raid", false, function(state)
    _G.AutoRaid = state
    if state then
        Library:Notify({
            Title = "Auto Raid",
            Description = "Auto entering: " .. _G.SelectedRaid,
            Duration = 2
        })
        task.spawn(function()
            while _G.AutoRaid do
                local network = require(NetworkAPI)
                network.SendServer("raid_enter", _G.SelectedRaid)
                task.wait(20)
            end
        end)
    end
end, {
    Title = "Auto Raid",
    Description = "Auto entering selected raid."
})

-- ===== SUMMON TAB =====
local SummonTab = Window:CreateTab("Summon", false, false)
local SummonPage = SummonTab:CreatePage("Main")
local SummonSection = SummonPage:CreateSection("Auto Summon")
local SellSection = SummonPage:CreateSection("Auto Sell")

_G.AutoSummon = false
_G.SelectedSummonWorld = "Cave"
local summonWorlds = {"Cave", "Subway", "Frozen Ruins", "Crimson Hold", "Marine Ford", "Shadow Realm", "Molten Verse"}

-- Auto Summon: dropdown + toggle
SummonSection:AddDropdown("Summon World", summonWorlds, false, function(selected)
    _G.SelectedSummonWorld = selected
end, {
    Title = "Select World",
    Description = "Choose summon world to auto open."
})

SummonSection:AddToggle("Auto Summon", false, function(state)
    _G.AutoSummon = state
    if state then
        Library:Notify({
            Title = "Auto Summon",
            Description = "Auto summoning from: " .. _G.SelectedSummonWorld,
            Duration = 2
        })
        task.spawn(function()
            local network = require(NetworkAPI)
            network.SendServer("summon_auto", _G.SelectedSummonWorld)
            while _G.AutoSummon do
                task.wait(1)
            end
            -- Stop auto summon when toggle off
            network.SendServer("summon_auto", nil)
        end)
    else
        local network = require(NetworkAPI)
        network.SendServer("summon_auto", nil)
    end
end, {
    Title = "Auto Summon",
    Description = "Auto open 10x summon continuously."
})

-- Auto Sell: toggle theo rarity
local autoSellStates = {
    Basic = false,
    Rare = false,
    Epic = false,
    Legendary = false,
    Mythic = false
}

local function ToggleAutoSell(rarity)
    return function(state)
        autoSellStates[rarity] = state
        local network = require(NetworkAPI)
        network.SendServer("summon_settings", "AutoSell" .. rarity)
    end
end

SellSection:AddToggle("Sell Basic", false, ToggleAutoSell("Basic"), {
    Title = "Auto Sell Basic",
    Description = "Auto sell Basic rarity items after summon."
})

SellSection:AddToggle("Sell Rare", false, ToggleAutoSell("Rare"), {
    Title = "Auto Sell Rare",
    Description = "Auto sell Rare rarity items after summon."
})

SellSection:AddToggle("Sell Epic", false, ToggleAutoSell("Epic"), {
    Title = "Auto Sell Epic",
    Description = "Auto sell Epic rarity items after summon."
})

SellSection:AddToggle("Sell Legendary", false, ToggleAutoSell("Legendary"), {
    Title = "Auto Sell Legendary",
    Description = "Auto sell Legendary rarity items after summon."
})

SellSection:AddToggle("Sell Mythic", false, ToggleAutoSell("Mythic"), {
    Title = "Auto Sell Mythic",
    Description = "Auto sell Mythic rarity items after summon."
})

