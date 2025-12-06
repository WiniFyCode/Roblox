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
        local waitArea4= waitArea:FindFirstChild("WaitArea4")
        if not waitArea4 then return nil end
        return waitArea4:FindFirstChild("TouchPart")
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

return Map
