--[[
    Character Module - Zombie Hyperloot
    Đọc danh sách nhân vật (characterDic) và equip nhân vật
]]

local Character = {}
local Config = nil

-- Remote IDs (từ config)
local CHARACTER_DIC_REMOTE_FUNCTION_ID = nil
local EQUIP_CHARACTER_REMOTE_EVENT_ID = nil
local GET_USER_DATA_REMOTE_FUNCTION_ID = nil

-- Map ID -> Tên hiển thị (từ config)
Character.CharacterNames = {}

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
    
    -- Load data from Config
    if Config.Data then
        Character.CharacterNames = Config.Data.Characters or {}
        local remotes = Config.Data.Remotes or {}
        CHARACTER_DIC_REMOTE_FUNCTION_ID = remotes.CharacterDicFunction
        EQUIP_CHARACTER_REMOTE_EVENT_ID = remotes.EquipCharacterEvent
        GET_USER_DATA_REMOTE_FUNCTION_ID = remotes.GetUserDataFunction
    end
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
        return {"Failed to read character data (join a game first)"}, {}
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
    if not Config or not Config.localPlayer then
        return nil
    end

    local localChar = Config.localPlayer.Character
    local playerHRP = localChar and localChar:FindFirstChild("HumanoidRootPart")
    if not playerHRP then
        return nil
    end

    local closestPart = nil
    local closestDistance = math.huge

    -- Ưu tiên zombie trong Map.FiringRange (chỉ khi bật chức năng)
    local map = workspace:FindFirstChild("Map")
    local firingRange = map and map:FindFirstChild("FiringRange")
    if Config and Config.firingRangePriorityEnabled and firingRange then
        for _, zombie in ipairs(firingRange:GetChildren()) do
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
    end

    -- Nếu không có zombie (hoặc FiringRange bị tắt), fallback về entityFolder
    if not closestPart and Config.entityFolder then
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
    end

    return closestPart
end

function Character.triggerSkill(skillId, usePosition, customCFrame)
    local char = Config.localPlayer and Config.localPlayer.Character
    if not char then return end

    -- Bỏ qua kiểm tra Tool để luôn cho phép cast skill
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

-- Wraith Q Skill (1007) - chém tới vị trí zombie gần nhất
function Character.activateWraithQSkill()
    local targetPart = getClosestZombiePart()
    if not targetPart then return false end

    -- Chém tới vị trí zombie
    local targetCFrame = CFrame.new(targetPart.Position)
    Character.triggerSkill(1007, true, targetCFrame)
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

-- Assault Q Skill (1003) - ném lựu đạn tới vị trí zombie
function Character.activateAssaultQSkill()
    local targetPart = getClosestZombiePart()
    if not targetPart then return false end

    -- Ném tới vị trí zombie
    local targetCFrame = CFrame.new(targetPart.Position)
    Character.triggerSkill(1003, true, targetCFrame)
    return true
end



-- Witch Ultimate (1012)
function Character.activateWitchUltimate()
    Character.triggerSkill(1012, false)
end

-- Witch Skill (G) (1013) - dùng vị trí zombie gần nhất
function Character.activateWitchGSkill()
    local targetPart = getClosestZombiePart()

    -- Nếu không có zombie thì dừng, không activate skill
    if not targetPart or not targetPart:IsA("BasePart") then
        return false
    end

    local targetCFrame = CFrame.new(targetPart.Position)
    Character.triggerSkill(1013, true, targetCFrame)
    return true
end

-- Witch Skill (F) (1014)
function Character.activateWitchFSkill()
    Character.triggerSkill(1014, false)
end

-- Ninja Ultimate (1008)
-- Nguyên lý:
--  1) Gửi {1008, "Enter"} để kích hoạt trạng thái ultimate
--  2) Sau đó gửi nhiều lần {1008, "Enter", targetPart} để bắn vào mục tiêu (Head)
--  + Cho phép chọn Đơn / Đa mục tiêu qua Config.ninjaUltimateTargetMode
function Character.activateNinjaUltimate()
    local char = Config.localPlayer and Config.localPlayer.Character
    if not char then return false end

    local netMessage = char:FindFirstChild("NetMessage")
    if not netMessage then return false end

    local targetMode = Config.ninjaUltimateTargetMode or "Single" -- "Single" hoặc "Multi"

    -- Bước 1: chuẩn bị danh sách mục tiêu (nếu không có thì dừng, KHÔNG kích hoạt ultimate)
    local targets = {}

    if targetMode == "Single" then
        -- Đơn mục tiêu: chỉ lấy 1 zombie gần nhất
        local part = getClosestZombiePart()
        if part and part:IsA("BasePart") then
            local model = part.Parent
            if model and model:IsA("Model") then
                local head = model:FindFirstChild("Head")
                if head and head:IsA("BasePart") then
                    part = head
                end
            end
            table.insert(targets, part)
        end
    else
        -- Đa mục tiêu: lấy tối đa 5 zombie gần nhất (ưu tiên FiringRange nếu được bật)
        local collected = {}
        local playerHRP = char:FindFirstChild("HumanoidRootPart")
        if playerHRP then
            local function collectFromFolder(folder)
                if not folder then return end
                for _, zombie in ipairs(folder:GetChildren()) do
                    if zombie:IsA("Model") then
                        local humanoid = zombie:FindFirstChildWhichIsA("Humanoid")
                        if humanoid and humanoid.Health > 0 then
                            local head = zombie:FindFirstChild("Head")
                            local hrp = zombie:FindFirstChild("HumanoidRootPart")
                            local part = head or hrp
                            if part and part:IsA("BasePart") then
                                local distance = (playerHRP.Position - part.Position).Magnitude
                                table.insert(collected, {part = part, distance = distance})
                            end
                        end
                    end
                end
            end

            -- Ưu tiên Map.FiringRange trước (chỉ khi bật chức năng)
            local map = workspace:FindFirstChild("Map")
            local firingRange = map and map:FindFirstChild("FiringRange")
            if Config and Config.firingRangePriorityEnabled then
                collectFromFolder(firingRange)
            end

            -- Nếu vẫn chưa đủ mục tiêu, lấy thêm từ Entity

            if #collected < 5 and Config.entityFolder then
                collectFromFolder(Config.entityFolder)
            end

            -- Sort theo khoảng cách tăng dần
            table.sort(collected, function(a, b)
                return a.distance < b.distance
            end)

            for i = 1, math.min(5, #collected) do
                local entry = collected[i]
                local part = entry.part
                if part and part:IsA("BasePart") then
                    local model = part.Parent
                    if model and model:IsA("Model") then
                        local head = model:FindFirstChild("Head")
                        if head and head:IsA("BasePart") then
                            part = head
                        end
                    end
                    table.insert(targets, part)
                end
            end
        end
    end

    -- Nếu không có zombie nào thì dừng, không gửi bất kỳ TrigerSkill nào
    if #targets == 0 then
        return false
    end

    -- Bước 2: kích hoạt ultimate
    pcall(function()
        netMessage:WaitForChild("TrigerSkill"):FireServer(1008, "Enter")
    end)

    -- Bắn tối đa 5 phi tiêu, chia theo danh sách targets
    local maxShots = 5
    local shotIndex = 1
    for i = 1, maxShots do
        local targetPart = targets[shotIndex]
        if not targetPart or not targetPart:IsA("BasePart") then break end

        pcall(function()
            netMessage:WaitForChild("TrigerSkill"):FireServer(1008, "Enter", targetPart)
        end)

        shotIndex = shotIndex + 1
        if shotIndex > #targets then
            shotIndex = 1
        end
    end

    return true
end

-- Ninja Skill (Q) (1009) - luôn target vào Head của zombie gần nhất (Instance)
function Character.activateNinjaQSkill()
    local targetPart = getClosestZombiePart()
    if not targetPart or not targetPart:IsA("BasePart") then
        return false
    end

    -- Luôn ưu tiên Head của zombie
    local zombieModel = targetPart.Parent
    if zombieModel and zombieModel:IsA("Model") then
        local head = zombieModel:FindFirstChild("Head")
        if head and head:IsA("BasePart") then
            targetPart = head
        end
    end

    local char = Config.localPlayer and Config.localPlayer.Character
    if not char then return false end

    local netMessage = char:FindFirstChild("NetMessage")
    if not netMessage then return false end

    local args = {
        1009,
        "Enter",
        targetPart
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
        Character.startSkillLoop(function() return Config.armsmasterUltimateInterval end, Character.activateArmsmasterUltimate, nil)
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
            function() return Config.witchUltimateInterval or 15 end,
            Character.activateWitchUltimate,
            function() return Config.witchUltimateEnabled end
        )
        Character.startSkillLoop(
            function() return Config.witchGSkillInterval or 0.7 end,
            Character.activateWitchGSkill,
            function() return Config.witchGSkillEnabled and getClosestZombiePart() ~= nil end
        )
        Character.startSkillLoop(
            function() return Config.healingSkillInterval end, 
            Character.activateHealingSkill,
            function() return Config.healingSkillEnabled end
        )
        Character.startSkillLoop(function() return Config.flagBearerUltimateInterval or 15 end, Character.activateFlagBearerUltimate, nil)
        Character.startSkillLoop(
            function() return Config.ninjaUltimateInterval or 10 end,
            Character.activateNinjaUltimate,
            function() return Config.ninjaUltimateEnabled and getClosestZombiePart() ~= nil end
        )
        Character.startSkillLoop(
            function() return Config.ninjaQSkillInterval or 9 end,
            Character.activateNinjaQSkill,
            function() return Config.ninjaQSkillEnabled and getClosestZombiePart() ~= nil end
        )
        return
    end

    -- Cập nhật cache character hiện tại
    Character.currentCharacterId = characterId

    -- Character-specific skills (mỗi character có F skill riêng)
    if characterId == 1006 then
        -- Armsmaster - Ultimate + F Skill
        Character.startSkillLoop(
            function() return Config.armsmasterUltimateInterval end, 
            Character.activateArmsmasterUltimate, 
            function() return Config.armsmasterUltimateEnabled end
        )
        Character.startSkillLoop(
            function() return Config.armsmasterFSkillInterval or 20 end, 
            Character.activateHealingSkill,
            function() return Config.armsmasterFSkillEnabled end
        )
    elseif characterId == 1003 then
        -- Wraith - Ultimate (G) + Q Skill + F Skill
        Character.startSkillLoop(
            function() return Config.wraithUltimateInterval or 0.3 end, 
            Character.activateWraithUltimate,
            function() return Config.wraithUltimateEnabled and getClosestZombiePart() ~= nil end
        )
        Character.startSkillLoop(
            function() return Config.wraithQSkillInterval or 9 end, 
            Character.activateWraithQSkill,
            function() return Config.wraithQSkillEnabled and getClosestZombiePart() ~= nil end
        )
        Character.startSkillLoop(
            function() return Config.wraithFSkillInterval or 20 end, 
            Character.activateHealingSkill,
            function() return Config.wraithFSkillEnabled end
        )
    elseif characterId == 1001 then
        -- Assault - Ultimate (G) + Q Skill + F Skill
        Character.startSkillLoop(
            function() return Config.assaultUltimateInterval or 0.3 end, 
            Character.activateAssaultUltimate,
            function() return Config.assaultUltimateEnabled and getClosestZombiePart() ~= nil end
        )
        Character.startSkillLoop(
            function() return Config.assaultQSkillInterval or 9 end, 
            Character.activateAssaultQSkill,
            function() return Config.assaultQSkillEnabled and getClosestZombiePart() ~= nil end
        )
        Character.startSkillLoop(
            function() return Config.assaultFSkillInterval or 20 end, 
            Character.activateHealingSkill,
            function() return Config.assaultFSkillEnabled end
        )
    elseif characterId == 1007 then
        -- Witch - Ultimate + Skill G + Skill F (1014)
        Character.startSkillLoop(
            function() return Config.witchUltimateInterval or 15 end,
            Character.activateWitchUltimate,
            function() return Config.witchUltimateEnabled end
        )
        Character.startSkillLoop(
            function() return Config.witchGSkillInterval or 0.7 end,
            Character.activateWitchGSkill,
            function() return Config.witchGSkillEnabled and getClosestZombiePart() ~= nil end
        )
        Character.startSkillLoop(
            function() return Config.witchFSkillInterval or 0.7 end,
            Character.activateWitchFSkill,
            function() return Config.witchFSkillEnabled end
        )
    elseif characterId == 1005 then
        -- Ninja - Ultimate (1008) + Skill Q (1009) + Skill F (Healing 1002)
        Character.startSkillLoop(
            function() return Config.ninjaUltimateInterval or 1 end,
            Character.activateNinjaUltimate,
            function() return Config.ninjaUltimateEnabled and getClosestZombiePart() ~= nil end
        )
        Character.startSkillLoop(
            function() return Config.ninjaQSkillInterval or 9 end,
            Character.activateNinjaQSkill,
            function() return Config.ninjaQSkillEnabled and getClosestZombiePart() ~= nil end
        )
        Character.startSkillLoop(
            function() return Config.ninjaFSkillInterval or 20 end,
            Character.activateHealingSkill,
            function() return Config.ninjaFSkillEnabled end
        )
    elseif characterId == 1004 then
        -- Flag Bearer - Ultimate + F Skill
        Character.startSkillLoop(
            function() return Config.flagBearerUltimateInterval or 15 end, 
            Character.activateFlagBearerUltimate, 
            function() return Config.flagBearerUltimateEnabled end
        )
        Character.startSkillLoop(
            function() return Config.flagBearerFSkillInterval or 20 end, 
            Character.activateHealingSkill,
            function() return Config.flagBearerFSkillEnabled end
        )
    end
    -- 1005 (Ninja) đã có auto skill riêng ở trên
end

----------------------------------------------------------
-- 🔹 Cleanup
function Character.cleanup()
    -- Skill loops sẽ tự dừng khi Config.scriptUnloaded = true
    -- Không cần cleanup gì thêm vì sử dụng task.spawn và check Config.scriptUnloaded
end

return Character

