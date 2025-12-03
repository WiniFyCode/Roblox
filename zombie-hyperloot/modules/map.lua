--[[
    Map Module - Zombie Hyperloot
    Map Teleport, Start, Replay
]]

local Map = {}
local Config = nil

function Map.init(config)
    Config = config
end

----------------------------------------------------------
-- 🔹 Map Teleport & Start
function Map.getWaitAreaTouchPart()
    local ok, result = pcall(function()
        local eItem = Config.Workspace:FindFirstChild("EItem")
        if not eItem then return nil end
        local waitArea = eItem:FindFirstChild("WaitArea")
        if not waitArea then return nil end
        local inner = waitArea:FindFirstChild("WaitArea")
        if not inner then return nil end
        return inner:FindFirstChild("TouchPart")
    end)

    if ok then return result end
    return nil
end

function Map.teleportToWaitAreaAndStart()
    if Config.scriptUnloaded then return end

    local char = Config.localPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hrp then
        warn("[MapTeleport] Không tìm thấy nhân vật hoặc HumanoidRootPart")
        return
    end

    local touchPart = Map.getWaitAreaTouchPart()
    if not touchPart or not touchPart:IsA("BasePart") then
        warn("[MapTeleport] Không tìm thấy WaitArea TouchPart")
        return
    end

    hrp.CFrame = touchPart.CFrame + Vector3.new(0, 4, 0)
    task.wait(0.5)

    local replicatedStorage = game:GetService("ReplicatedStorage")
    local remoteFolder = replicatedStorage:FindFirstChild("Remote")
    if not remoteFolder then
        warn("[MapTeleport] Không tìm thấy ReplicatedStorage.Remote")
        return
    end

    local remoteEvent = remoteFolder:FindFirstChild("RemoteEvent")
    if not remoteEvent then
        warn("[MapTeleport] Không tìm thấy RemoteEvent")
        return
    end

    local difficultyToSend = Config.selectedDifficulty
    if Config.selectedWorldId == 102 or Config.selectedWorldId == 201 then
        difficultyToSend = 1
    end

    local args = {
        1604900034,
        {
            difficulty = difficultyToSend,
            worldId = Config.selectedWorldId,
            maxCount = Config.selectedMaxCount,
            friendOnly = Config.selectedFriendOnly
        }
    }

    pcall(function()
        remoteEvent:FireServer(unpack(args))
    end)
end

function Map.replayCurrentMatch()
    if Config.scriptUnloaded then return end

    local replicatedStorage = game:GetService("ReplicatedStorage")
    local remoteFolder = replicatedStorage:FindFirstChild("Remote")
    if not remoteFolder then
        warn("[ReplayMatch] Không tìm thấy ReplicatedStorage.Remote")
        return
    end

    local remoteEvent = remoteFolder:FindFirstChild("RemoteEvent")
    if not remoteEvent then
        warn("[ReplayMatch] Không tìm thấy RemoteEvent")
        return
    end

    pcall(function()
        remoteEvent:FireServer(3463932402)
    end)
end

-- Auto Replay Loop
function Map.startAutoReplayLoop()
    task.spawn(function()
        while task.wait(3) do
            if Config.scriptUnloaded then break end
            if Config.autoReplayEnabled then
                Map.replayCurrentMatch()
            end
        end
    end)
end

----------------------------------------------------------
-- 🔹 Quick Teleport Helpers
function Map.findTaskPosition()
    local map = Config.Workspace:FindFirstChild("Map")
    if not map then return nil end
    
    for _, mapChild in ipairs(map:GetChildren()) do
        local eItem = mapChild:FindFirstChild("EItem")
        if eItem then
            local task = eItem:FindFirstChild("Task")
            if task then
                local default = task:FindFirstChild("default")
                if default then
                    local part = default:FindFirstChildWhichIsA("BasePart")
                    if part then
                        return part.Position + Vector3.new(0, 3, 0)
                    end
                end
            end
        end
    end
    return nil
end

function Map.findAllExitDoors()
    local doors = {}
    local map = Config.Workspace:FindFirstChild("Map")
    if not map then return doors end
    
    for _, mapChild in ipairs(map:GetChildren()) do
        local eItem = mapChild:FindFirstChild("EItem")
        if eItem then
            for _, child in ipairs(eItem:GetChildren()) do
                if string.find(child.Name, "ExitDoor") then
                    local body = child:FindFirstChild("Body")
                    local targetPart = nil
                    
                    if body then
                        if body:IsA("BasePart") then
                            targetPart = body
                        else
                            targetPart = body:FindFirstChildWhichIsA("BasePart")
                        end
                    end
                    
                    if not targetPart then
                        targetPart = child:FindFirstChildWhichIsA("BasePart")
                    end
                    
                    if not targetPart and child:IsA("Model") then
                        targetPart = child.PrimaryPart
                    end
                    
                    if not targetPart and child:IsA("Model") then
                        targetPart = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChild("Head")
                    end
                    
                    if targetPart and targetPart:IsA("BasePart") then
                        table.insert(doors, targetPart.Position + Vector3.new(0, 3, 0))
                    end
                end
            end
        end
    end
    return doors
end

function Map.findAllSupplyPiles()
    local supplies = {}
    local map = Config.Workspace:FindFirstChild("Map")
    if not map then return supplies end
    
    for _, mapChild in ipairs(map:GetChildren()) do
        local eItem = mapChild:FindFirstChild("EItem")
        if eItem then
            for _, child in ipairs(eItem:GetChildren()) do
                if tonumber(child.Name) then
                    local model = child:FindFirstChild("Model")
                    if model then
                        local part = model:FindFirstChildWhichIsA("BasePart")
                        if part then
                            table.insert(supplies, part.Position + Vector3.new(0, 3, 0))
                        end
                    else
                        local part = child:FindFirstChildWhichIsA("BasePart")
                        if part then
                            table.insert(supplies, part.Position + Vector3.new(0, 3, 0))
                        end
                    end
                end
            end
        end
    end
    
    -- Remove duplicates
    local uniqueSupplies = {}
    for i, pos1 in ipairs(supplies) do
        local isDuplicate = false
        for j, pos2 in ipairs(uniqueSupplies) do
            if (pos1 - pos2).Magnitude < 5 then
                isDuplicate = true
                break
            end
        end
        if not isDuplicate then
            table.insert(uniqueSupplies, pos1)
        end
    end
    
    return uniqueSupplies
end

return Map
