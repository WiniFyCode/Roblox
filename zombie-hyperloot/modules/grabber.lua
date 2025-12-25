--[[
    Grabber Module - Zombie Hyperloot
    Kéo zombie trong phạm vi nhỏ về 1 điểm
    by WiniFy
]]

local Grabber = {}
local Config = nil

-- Connections
Grabber.grabberLoop = nil
Grabber.isGrabbing = false

-- Settings
Grabber.grabRadius = 50 -- Bán kính kéo zombie (studs) - giảm xuống
Grabber.grabHeight = 3 -- Độ cao so với player
Grabber.grabMode = "Player" -- "Player" hoặc "Custom"
Grabber.customPosition = nil -- Vector3 cho custom mode
Grabber.grabInterval = 0.1 -- Interval giữa mỗi lần update (giây)

function Grabber.init(config)
    Config = config
end

----------------------------------------------------------
-- 🔹 Get Target Position
function Grabber.getTargetPosition()
    if Grabber.grabMode == "Custom" and Grabber.customPosition then
        return Grabber.customPosition
    end
    
    -- Default: Player position
    local char = Config.localPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        return hrp.Position + Vector3.new(0, Grabber.grabHeight, 0)
    end
    
    return nil
end

----------------------------------------------------------
-- 🔹 Get Zombies In Range
function Grabber.getZombiesInRange()
    local zombies = {}
    local char = Config.localPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return zombies end
    
    local playerPos = hrp.Position
    
    for _, zombie in ipairs(Config.entityFolder:GetChildren()) do
        if zombie:IsA("Model") then
            local humanoid = zombie:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local zombieHRP = zombie:FindFirstChild("HumanoidRootPart")
                local head = zombie:FindFirstChild("Head")
                local torso = zombie:FindFirstChild("UpperTorso") or zombie:FindFirstChild("Torso")
                local targetPart = zombieHRP or torso or head
                
                if targetPart and targetPart:IsA("BasePart") then
                    local distance = (playerPos - targetPart.Position).Magnitude
                    -- Chỉ lấy zombie trong phạm vi
                    if distance <= Grabber.grabRadius then
                        table.insert(zombies, {
                            model = zombie,
                            humanoid = humanoid,
                            rootPart = targetPart,
                            distance = distance
                        })
                    end
                end
            end
        end
    end
    
    return zombies
end

----------------------------------------------------------
-- 🔹 Move Zombie (không freeze, chỉ set CFrame liên tục)
function Grabber.moveZombie(zombieData, targetPos)
    local rootPart = zombieData.rootPart
    if not rootPart or not rootPart.Parent then return end
    
    pcall(function()
        -- Chỉ set CFrame, không anchor hay dùng BodyPosition
        rootPart.CFrame = CFrame.new(targetPos)
        rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end)
end

----------------------------------------------------------
-- 🔹 Grab All Zombies (One-time)
function Grabber.grabAllZombiesOnce()
    local targetPos = Grabber.getTargetPosition()
    if not targetPos then
        warn("[Grabber] Không tìm thấy target position")
        return 0
    end
    
    local zombies = Grabber.getZombiesInRange()
    local count = 0
    
    for _, zombieData in ipairs(zombies) do
        Grabber.moveZombie(zombieData, targetPos)
        count = count + 1
    end
    
    return count
end

----------------------------------------------------------
-- 🔹 Start Continuous Grabbing (Fixed)
function Grabber.startGrabbing()
    if Grabber.isGrabbing then return end
    Grabber.isGrabbing = true
    
    -- Dùng coroutine thay vì task.spawn để tránh lỗi
    Grabber.grabberLoop = coroutine.create(function()
        while Grabber.isGrabbing do
            if Config.scriptUnloaded then 
                Grabber.isGrabbing = false
                break 
            end
            
            local targetPos = Grabber.getTargetPosition()
            
            if targetPos then
                local zombies = Grabber.getZombiesInRange()
                
                for _, zombieData in ipairs(zombies) do
                    if not Grabber.isGrabbing then break end
                    Grabber.moveZombie(zombieData, targetPos)
                end
            end
            
            -- Wait
            local startTime = tick()
            while tick() - startTime < Grabber.grabInterval do
                if not Grabber.isGrabbing then break end
                game:GetService("RunService").Heartbeat:Wait()
            end
        end
    end)
    
    coroutine.resume(Grabber.grabberLoop)
end

----------------------------------------------------------
-- 🔹 Stop Grabbing
function Grabber.stopGrabbing()
    Grabber.isGrabbing = false
    Grabber.grabberLoop = nil
end

----------------------------------------------------------
-- 🔹 Set Custom Position
function Grabber.setCustomPosition(position)
    if typeof(position) == "Vector3" then
        Grabber.customPosition = position
        Grabber.grabMode = "Custom"
    end
end

----------------------------------------------------------
-- 🔹 Set to Player Position
function Grabber.setPlayerMode()
    Grabber.grabMode = "Player"
    Grabber.customPosition = nil
end

----------------------------------------------------------
-- 🔹 Toggle Grabbing
function Grabber.toggle(enabled)
    if enabled then
        Grabber.startGrabbing()
    else
        Grabber.stopGrabbing()
    end
end

----------------------------------------------------------
-- 🔹 Cleanup
function Grabber.cleanup()
    Grabber.stopGrabbing()
end

return Grabber
