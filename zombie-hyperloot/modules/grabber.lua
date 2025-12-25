--[[
    Grabber Module - Zombie Hyperloot
    Kéo tất cả zombie về 1 điểm (player position hoặc custom position)
    by WiniFy
]]

local Grabber = {}
local Config = nil

-- Connections
Grabber.grabberConnection = nil
Grabber.isGrabbing = false

-- Settings
Grabber.grabRadius = 500 -- Bán kính kéo zombie (studs)
Grabber.grabSpeed = 50 -- Tốc độ kéo (studs/s)
Grabber.grabHeight = 3 -- Độ cao so với player
Grabber.grabMode = "Player" -- "Player" hoặc "Custom"
Grabber.customPosition = nil -- Vector3 cho custom mode
Grabber.freezeZombies = true -- Đóng băng zombie sau khi kéo
Grabber.grabInterval = 0.05 -- Interval giữa mỗi lần update (giây)

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
-- 🔹 Get All Alive Zombies
function Grabber.getAliveZombies()
    local zombies = {}
    
    for _, zombie in ipairs(Config.entityFolder:GetChildren()) do
        if zombie:IsA("Model") then
            local humanoid = zombie:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local hrp = zombie:FindFirstChild("HumanoidRootPart")
                local head = zombie:FindFirstChild("Head")
                local torso = zombie:FindFirstChild("UpperTorso") or zombie:FindFirstChild("Torso")
                local targetPart = hrp or torso or head
                
                if targetPart and targetPart:IsA("BasePart") then
                    table.insert(zombies, {
                        model = zombie,
                        humanoid = humanoid,
                        rootPart = targetPart
                    })
                end
            end
        end
    end
    
    return zombies
end

----------------------------------------------------------
-- 🔹 Teleport Zombie to Position (Instant)
-- Lưu BodyPosition đã tạo
Grabber.bodyPositions = {}

function Grabber.teleportZombie(zombieData, targetPos)
    local rootPart = zombieData.rootPart
    if not rootPart or not rootPart.Parent then return end
    
    pcall(function()
        -- KHÔNG dùng Anchored vì sẽ không nhận damage
        rootPart.CanCollide = false
        
        -- Teleport
        rootPart.CFrame = CFrame.new(targetPos)
        rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        
        -- Dùng BodyPosition để giữ zombie tại chỗ (vẫn nhận damage)
        if Grabber.freezeZombies then
            -- Xóa BodyPosition cũ nếu có
            local oldBP = rootPart:FindFirstChild("GrabberBodyPosition")
            if oldBP then oldBP:Destroy() end
            
            local bp = Instance.new("BodyPosition")
            bp.Name = "GrabberBodyPosition"
            bp.Position = targetPos
            bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bp.P = 100000
            bp.D = 1000
            bp.Parent = rootPart
            
            Grabber.bodyPositions[rootPart] = bp
        end
    end)
end

----------------------------------------------------------
-- 🔹 Pull Zombie Smoothly (với velocity)
function Grabber.pullZombie(zombieData, targetPos)
    local rootPart = zombieData.rootPart
    if not rootPart or not rootPart.Parent then return end
    
    local currentPos = rootPart.Position
    local distance = (targetPos - currentPos).Magnitude
    
    -- Nếu đã gần target, dùng BodyPosition để giữ
    if distance < 5 then
        pcall(function()
            if Grabber.freezeZombies then
                -- Xóa BodyPosition cũ nếu có
                local oldBP = rootPart:FindFirstChild("GrabberBodyPosition")
                if oldBP then oldBP:Destroy() end
                
                local bp = Instance.new("BodyPosition")
                bp.Name = "GrabberBodyPosition"
                bp.Position = targetPos
                bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bp.P = 100000
                bp.D = 1000
                bp.Parent = rootPart
                
                Grabber.bodyPositions[rootPart] = bp
            end
            rootPart.CFrame = CFrame.new(targetPos)
        end)
        return
    end
    
    -- Tính direction và velocity
    local direction = (targetPos - currentPos).Unit
    local velocity = direction * Grabber.grabSpeed
    
    pcall(function()
        rootPart.CanCollide = false
        rootPart.AssemblyLinearVelocity = velocity
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
    
    local zombies = Grabber.getAliveZombies()
    local count = 0
    
    for _, zombieData in ipairs(zombies) do
        Grabber.teleportZombie(zombieData, targetPos)
        count = count + 1
    end
    
    return count
end

----------------------------------------------------------
-- 🔹 Start Continuous Grabbing
function Grabber.startGrabbing()
    if Grabber.grabberConnection then return end
    Grabber.isGrabbing = true
    
    Grabber.grabberConnection = task.spawn(function()
        while Grabber.isGrabbing and not Config.scriptUnloaded do
            local targetPos = Grabber.getTargetPosition()
            
            if targetPos then
                local zombies = Grabber.getAliveZombies()
                
                for _, zombieData in ipairs(zombies) do
                    if not Grabber.isGrabbing then break end
                    Grabber.pullZombie(zombieData, targetPos)
                end
            end
            
            task.wait(Grabber.grabInterval)
        end
    end)
end

----------------------------------------------------------
-- 🔹 Stop Grabbing
function Grabber.stopGrabbing()
    Grabber.isGrabbing = false
    
    if Grabber.grabberConnection then
        task.cancel(Grabber.grabberConnection)
        Grabber.grabberConnection = nil
    end
    
    -- Unfreeze all zombies
    if not Grabber.freezeZombies then
        Grabber.unfreezeAllZombies()
    end
end

----------------------------------------------------------
-- 🔹 Unfreeze All Zombies
function Grabber.unfreezeAllZombies()
    -- Xóa tất cả BodyPosition
    for rootPart, bp in pairs(Grabber.bodyPositions) do
        pcall(function()
            if bp and bp.Parent then
                bp:Destroy()
            end
        end)
    end
    Grabber.bodyPositions = {}
    
    -- Xóa BodyPosition còn sót trong entity folder
    for _, zombie in ipairs(Config.entityFolder:GetChildren()) do
        if zombie:IsA("Model") then
            local hrp = zombie:FindFirstChild("HumanoidRootPart")
            if hrp then
                local bp = hrp:FindFirstChild("GrabberBodyPosition")
                if bp then
                    pcall(function() bp:Destroy() end)
                end
            end
        end
    end
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
    Grabber.unfreezeAllZombies()
    Grabber.bodyPositions = {}
end

return Grabber
