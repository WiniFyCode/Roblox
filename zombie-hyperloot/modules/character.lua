--[[
    Character Module - Zombie Hyperloot
    Đọc danh sách nhân vật (characterDic) và equip nhân vật
]]

local Character = {}
local Config = nil

-- Remote IDs (từ remote logger)
local CHARACTER_DIC_REMOTE_FUNCTION_ID = 857483751
local EQUIP_CHARACTER_REMOTE_EVENT_ID = 1981544152
local GET_USER_DATA_REMOTE_FUNCTION_ID = 2498358147

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

-- Lưu character ID hiện tại
Character.currentCharacterId = nil

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

-- 🔹 Get Current Character ID from Server
function Character.getCurrentCharacterId()
    if Config and Config.scriptUnloaded then return nil end

    local remoteFunction = getRemoteFunction()
    if not remoteFunction then return nil end

    local userId = Config.localPlayer and Config.localPlayer.UserId
    if not userId then return nil end

    local args = {
        GET_USER_DATA_REMOTE_FUNCTION_ID,
        userId,
    }

    local success, result = pcall(function()
        return remoteFunction:InvokeServer(unpack(args))
    end)

    if not success then
        warn("[ZombieHyperloot][Character] InvokeServer get user data lỗi:", result)
        return nil
    end

    if type(result) ~= "table" then
        return nil
    end

    local characterId = result.character
    if characterId then
        Character.currentCharacterId = tonumber(characterId)
        return Character.currentCharacterId
    end

    return nil
end

-- 🔹 Auto Skill (moved from Combat)
local function getClosestZombiePart()
    if not Config or not Config.entityFolder or not Config.localPlayer then
        return nil
    end

    local localChar = Config.localPlayer.Character
    local playerHRP = localChar and localChar:FindFirstChild("HumanoidRootPart")
    if not playerHRP then
        return nil
    end

    local closestPart = nil
    local closestDistance = math.huge

    for _, zombie in ipairs(Config.entityFolder:GetChildren()) do
        if zombie:IsA("Model") then
            local humanoid = zombie:FindFirstChildWhichIsA("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local head = zombie:FindFirstChild("Head")
                local hrp = zombie:FindFirstChild("HumanoidRootPart")
                local targetPart = head or hrp
                if targetPart and targetPart:IsA("BasePart") then
                    local distance = (playerHRP.Position - targetPart.Position).Magnitude
                    if distance < closestDistance then
                        closestDistance = distance
                        closestPart = targetPart
                    end
                end
            end
        end
    end

    return closestPart
end

function Character.triggerSkill(skillId, usePosition, customCFrame)
    local char = Config.localPlayer and Config.localPlayer.Character
    if not char then return end

    local tool = char:FindFirstChild("Tool")
    if not tool then return end

    local netMessage = char:FindFirstChild("NetMessage")
    if not netMessage then return end

    local args
    if usePosition then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local cf = customCFrame or (hrp and hrp.CFrame or CFrame.new())
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

-- Wraith Ultimate (1006) - dùng vị trí zombie gần nhất
function Character.activateWraithUltimate()
    local targetPart = getClosestZombiePart()
    
    -- Nếu không có zombie thì dừng, không activate skill
    if not targetPart or not targetPart:IsA("BasePart") then
        return false
    end

    local targetCFrame = CFrame.new(targetPart.Position)
    Character.triggerSkill(1006, true, targetCFrame)
    return true
end

-- Assault Ultimate (1001) - dùng 2 vector: cả 2 đều là vị trí zombie
function Character.activateAssaultUltimate()
    local targetPart = getClosestZombiePart()
    
    -- Nếu không có zombie thì dừng, không activate skill
    if not targetPart or not targetPart:IsA("BasePart") then
        return false
    end

    local char = Config.localPlayer and Config.localPlayer.Character
    if not char then return false end

    local netMessage = char:FindFirstChild("NetMessage")
    if not netMessage then return false end

    -- Vector 1: vị trí zombie
    local vector1 = targetPart.Position
    -- Vector 2: cũng là vị trí zombie (cùng vector)
    local vector2 = targetPart.Position

    local args = {
        1001,
        "Enter",
        vector1,
        vector2
    }

    pcall(function()
        netMessage:WaitForChild("TrigerSkill"):FireServer(unpack(args))
    end)

    return true
end



-- Flag Bearer Ultimate (1004) - cần CFrame vị trí người chơi
function Character.activateFlagBearerUltimate()
    Character.triggerSkill(1004, true)
end

function Character.startSkillLoop(getInterval, action, checkCondition)
    task.spawn(function()
        if Config.autoSkillEnabled and not Config.scriptUnloaded then
            task.wait(1)
            -- Nếu có checkCondition, chỉ chạy khi condition = true
            if not checkCondition or checkCondition() then
                action()
            end
        end

        while task.wait(getInterval()) do
            if Config.scriptUnloaded then break end
            if Config.autoSkillEnabled then
                -- Nếu có checkCondition, chỉ chạy khi condition = true
                if checkCondition then
                    if checkCondition() then
                        action()
                    end
                    -- Nếu không có zombie, tiếp tục loop nhưng không activate skill
                else
                    action()
                end
            end
        end
    end)
end

function Character.startAllSkillLoops()
    -- Lấy character ID hiện tại từ server
    local characterId = Character.getCurrentCharacterId()
    
    if not characterId then
        warn("[ZombieHyperloot][Character] Không lấy được character ID, sẽ chạy tất cả skills")
        -- Fallback: chạy tất cả skills nếu không lấy được character ID
        Character.startSkillLoop(function() return Config.armsmasterUltimateInterval end, Character.activateArmsmasterUltimate)
        Character.startSkillLoop(
            function() return Config.wraithUltimateInterval or 0.3 end, 
            Character.activateWraithUltimate,
            function() return getClosestZombiePart() ~= nil end
        )
        Character.startSkillLoop(
            function() return Config.assaultUltimateInterval or 0.3 end, 
            Character.activateAssaultUltimate,
            function() return getClosestZombiePart() ~= nil end
        )
        Character.startSkillLoop(
            function() return Config.healingSkillInterval end, 
            Character.activateHealingSkill,
            function() return Config.healingSkillEnabled end -- Check toggle
        )
        Character.startSkillLoop(function() return Config.flagBearerUltimateInterval or 15 end, Character.activateFlagBearerUltimate)
        return
    end

    -- Chỉ chạy skill tương ứng với character hiện tại
    -- Healing skill (1002) có thể dùng cho tất cả characters - có toggle riêng
    Character.startSkillLoop(
        function() return Config.healingSkillInterval end, 
        Character.activateHealingSkill,
        function() return Config.healingSkillEnabled end -- Check toggle
    )

    -- Character-specific skills
    if characterId == 1006 then
        -- Armsmaster
        Character.startSkillLoop(function() return Config.armsmasterUltimateInterval end, Character.activateArmsmasterUltimate)
    elseif characterId == 1003 then
        -- Wraith - chỉ activate khi có zombie
        Character.startSkillLoop(
            function() return Config.wraithUltimateInterval or 0.3 end, 
            Character.activateWraithUltimate,
            function() return getClosestZombiePart() ~= nil end -- Check condition: có zombie mới chạy
        )
    elseif characterId == 1001 then
        -- Assault Ultimate (G) - chỉ activate khi có zombie và toggle bật
        Character.startSkillLoop(
            function() return Config.assaultUltimateInterval or 0.3 end, 
            Character.activateAssaultUltimate,
            function() return Config.assaultUltimateEnabled and getClosestZombiePart() ~= nil end
        )

    elseif characterId == 1004 then
        -- Flag Bearer
        Character.startSkillLoop(function() return Config.flagBearerUltimateInterval or 15 end, Character.activateFlagBearerUltimate)
    end
    -- 1005 (Ninja) không có ultimate skill riêng
end

----------------------------------------------------------
-- 🔹 Cleanup
function Character.cleanup()
    -- Skill loops sẽ tự dừng khi Config.scriptUnloaded = true
    -- Không cần cleanup gì thêm vì sử dụng task.spawn và check Config.scriptUnloaded
end

return Character

