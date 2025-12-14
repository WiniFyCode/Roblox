--[[
    Character Module - Zombie Hyperloot
    Đọc danh sách nhân vật (characterDic) và equip nhân vật
]]

local Character = {}
local Config = nil

-- Remote IDs (từ remote logger)
local CHARACTER_DIC_REMOTE_FUNCTION_ID = 857483751
local EQUIP_CHARACTER_REMOTE_EVENT_ID = 1981544152

-- Map ID -> Tên hiển thị (có thể chỉnh tuỳ ý)
Character.CharacterNames = {
    [1001] = "Assault",
    [1003] = "Wraith",
    [1004] = "Flag Bearer",
    [1005] = "Ninja",
    [1006] = "Armsmaster",
}

-- Lưu mapping display string -> id để UI dùng lại
Character.DisplayToId = {}

local function getRemoteFolder()
    local replicatedStorage = Config and Config.ReplicatedStorage or game:GetService("ReplicatedStorage")
    local remoteFolder = replicatedStorage:FindFirstChild("Remote")
    if not remoteFolder then
        warn("[ZombieHyperloot][Character] Không tìm thấy ReplicatedStorage.Remote")
        return nil
    end
    return remoteFolder
end

local function getRemoteFunction()
    local remoteFolder = getRemoteFolder()
    if not remoteFolder then return nil end

    local remoteFunction = remoteFolder:FindFirstChild("RemoteFunction")
    if not remoteFunction then
        warn("[ZombieHyperloot][Character] Không tìm thấy RemoteFunction")
        return nil
    end

    return remoteFunction
end

local function getRemoteEvent()
    local remoteFolder = getRemoteFolder()
    if not remoteFolder then return nil end

    local remoteEvent = remoteFolder:FindFirstChild("RemoteEvent")
    if not remoteEvent then
        warn("[ZombieHyperloot][Character] Không tìm thấy RemoteEvent")
        return nil
    end

    return remoteEvent
end

function Character.init(config)
    Config = config
end

-- Đọc characterDic từ server
function Character.fetchCharacterDic()
    if Config and Config.scriptUnloaded then return nil end

    local remoteFunction = getRemoteFunction()
    if not remoteFunction then return nil end

    local args = {
        CHARACTER_DIC_REMOTE_FUNCTION_ID,
        "characterDic",
    }

    local success, result = pcall(function()
        return remoteFunction:InvokeServer(unpack(args))
    end)

    if not success then
        warn("[ZombieHyperloot][Character] InvokeServer characterDic lỗi:", result)
        return nil
    end

    if type(result) ~= "table" then
        warn("[ZombieHyperloot][Character] Kết quả characterDic không phải table")
        return nil
    end

    local array = result._array or result
    if type(array) ~= "table" then
        warn("[ZombieHyperloot][Character] Không tìm thấy _array trong kết quả")
        return nil
    end

    local characters = {}
    for idKey, level in pairs(array) do
        local numericId = tonumber(idKey) or idKey
        characters[numericId] = level
    end

    return characters
end

-- Build danh sách display cho dropdown + mapping
function Character.getCharacterDisplayList()
    local characters = Character.fetchCharacterDic()
    Character.DisplayToId = {}

    if not characters then
        return {"Không đọc được dữ liệu (vào game trước đã)"}, {}
    end

    local list = {}

    for id, level in pairs(characters) do
        local name = Character.CharacterNames[id] or ("ID " .. tostring(id))
        local display = string.format("%s [Lv %s] (%s)", name, tostring(level), tostring(id))
        table.insert(list, display)
        Character.DisplayToId[display] = id
    end

    table.sort(list)
    return list, Character.DisplayToId
end

-- Equip nhân vật theo ID
function Character.equipCharacter(id)
    if Config and Config.scriptUnloaded then return false, "Script unloaded" end

    local remoteEvent = getRemoteEvent()
    if not remoteEvent then return false, "RemoteEvent not found" end

    local numericId = tonumber(id)
    if not numericId then
        return false, "Invalid character id"
    end

    local args = {
        EQUIP_CHARACTER_REMOTE_EVENT_ID,
        numericId,
    }

    local ok, err = pcall(function()
        remoteEvent:FireServer(unpack(args))
    end)

    if not ok then
        warn("[ZombieHyperloot][Character] Equip nhân vật lỗi:", err)
        return false, err
    end

    return true
end

-- 🔹 Auto Skill (moved from Combat)
function Character.triggerSkill(skillId, usePosition)
    local char = Config.localPlayer and Config.localPlayer.Character
    if not char then return end

    local tool = char:FindFirstChild("Tool")
    if not tool then return end

    local netMessage = char:FindFirstChild("NetMessage")
    if not netMessage then return end

    local args
    if usePosition then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local cf = hrp and hrp.CFrame or CFrame.new()
        args = {skillId, "Enter", cf}
    else
        args = {skillId, "Enter"}
    end

    pcall(function()
        netMessage:WaitForChild("TrigerSkill"):FireServer(unpack(args))
    end)
end

-- Armsmaster Ultimate (1010)
function Character.activateArmsmasterUltimate()
    Character.triggerSkill(1010, false)
end

-- F Skill (Healing) (1002)
function Character.activateHealingSkill()
    Character.triggerSkill(1002, false)
end

-- Flag Bearer Ultimate (1004) - cần CFrame vị trí
function Character.activateFlagBearerUltimate()
    Character.triggerSkill(1004, true)
end

function Character.startSkillLoop(getInterval, action)
    task.spawn(function()
        if Config.autoSkillEnabled and not Config.scriptUnloaded then
            task.wait(1)
            action()
        end

        while task.wait(getInterval()) do
            if Config.scriptUnloaded then break end
            if Config.autoSkillEnabled then
                action()
            end
        end
    end)
end

local function getSelectedCharacterSkillInterval()
    if not Config then
        return 15
    end

    local charId = Config.selectedCharacterId

    if charId == 1006 then
        return Config.armsmasterUltimateInterval or 15
    elseif charId == 1004 then
        return Config.flagBearerUltimateInterval or 15
    else
        return 15
    end
end

local function triggerSelectedCharacterSkill()
    if not Config then
        return
    end

    local charId = Config.selectedCharacterId

    if charId == 1006 then
        Character.activateArmsmasterUltimate()
    elseif charId == 1004 then
        Character.activateFlagBearerUltimate()
    end
end

function Character.startAllSkillLoops()
    Character.startSkillLoop(getSelectedCharacterSkillInterval, triggerSelectedCharacterSkill)
    Character.startSkillLoop(function() return Config.healingSkillInterval end, Character.activateHealingSkill)
end




return Character

