--[[
    Movement Module - Zombie Hyperloot
    Speed, NoClip, Camera Teleport, Noclip Cam
]]


local Movement = {}
local Config = nil

-- Connections
Movement.noClipConnection = nil
Movement.speedConnection = nil
Movement.originalCollidableParts = {}
Movement.originalWalkSpeed = nil


function Movement.init(config)
    Config = config
end




----------------------------------------------------------
-- 🔹 NoClip
function Movement.enableNoClip()
    if Movement.noClipConnection then return end
    
    Movement.noClipConnection = Config.RunService.Stepped:Connect(function()
        local char = Config.localPlayer.Character
        if char and Config.noClipEnabled then
            for _, descendant in ipairs(char:GetDescendants()) do
                if descendant:IsA("BasePart") then
                    descendant.CanCollide = false
                end
            end
        end
    end)
end

function Movement.disableNoClip()
    if Movement.noClipConnection then
        Movement.noClipConnection:Disconnect()
        Movement.noClipConnection = nil
    end

    local char = Config.localPlayer.Character
    if char then
        local hasOriginal = next(Movement.originalCollidableParts) ~= nil
        for _, descendant in ipairs(char:GetDescendants()) do
            if descendant:IsA("BasePart") then
                if hasOriginal then
                    -- Nếu part ban đầu collidable thì trả về true, còn lại giữ false
                    if Movement.originalCollidableParts[descendant] then
                        descendant.CanCollide = true
                    else
                        descendant.CanCollide = false
                    end
                else
                    -- Trường hợp NoClip bình thường (không Anti-Zombie): trả hết về true như cũ
                    descendant.CanCollide = true
                end
            end
        end
    end

    -- Xoá cache sau khi đã restore xong
    for part in pairs(Movement.originalCollidableParts) do
        Movement.originalCollidableParts[part] = nil
    end
end


function Movement.applyNoClip()
    if Config.noClipEnabled then
        Movement.enableNoClip()
    else
        Movement.disableNoClip()
    end
end


----------------------------------------------------------
-- 🔹 Speed
function Movement.startSpeedBoost()
    if Movement.speedConnection then return end
    Movement.speedConnection = Config.RunService.Heartbeat:Connect(function()
        if not Config.speedEnabled then return end
        
        local char = Config.localPlayer.Character
        local humanoid = char and char:FindFirstChild("Humanoid")
        if not humanoid then return end
        
        if not Movement.originalWalkSpeed then
            Movement.originalWalkSpeed = humanoid.WalkSpeed
        end
        
        local baseSpeed = Movement.originalWalkSpeed or 16
        local targetSpeed = baseSpeed + Config.speedValue
        
        if math.abs(humanoid.WalkSpeed - targetSpeed) > 0.01 then
            humanoid.WalkSpeed = targetSpeed
        end
    end)
end

function Movement.stopSpeedBoost()
    if Movement.speedConnection then
        Movement.speedConnection:Disconnect()
        Movement.speedConnection = nil
    end
    
    local char = Config.localPlayer.Character
    local humanoid = char and char:FindFirstChild("Humanoid")
    if humanoid and Movement.originalWalkSpeed then
        humanoid.WalkSpeed = Movement.originalWalkSpeed
    end
    Movement.originalWalkSpeed = nil
end

function Movement.applySpeed()
    if Config.speedEnabled then
        Movement.startSpeedBoost()
    else
        Movement.stopSpeedBoost()
    end
end

----------------------------------------------------------
-- 🔹 Noclip Cam
function Movement.setNoclipCam(enabled)
    local sc = (debug and debug.setconstant) or setconstant
    local gc = (debug and debug.getconstants) or getconstants
    if not sc or not getgc or not gc then
        warn("Exploit không hỗ trợ Noclip Cam (thiếu setconstant hoặc getconstants)")
        return false
    end
    
    local success = false
    local pop = Config.localPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"):WaitForChild("CameraModule"):WaitForChild("ZoomController"):WaitForChild("Popper")
    
    -- enabled = true → set 0 (noclip cam bật)
    -- enabled = false → set 0.25 (noclip cam tắt, camera bình thường)
    local targetValue = enabled and 0 or 0.25
    
    for _, v in pairs(getgc()) do
        if type(v) == 'function' and getfenv(v).script == pop then
            for i, v1 in pairs(gc(v)) do
                local numVal = tonumber(v1)
                if numVal == 0 or numVal == 0.25 then
                    sc(v, i, targetValue)
                    success = true
                end
            end
        end
    end
    
    return success
end

function Movement.applyNoclipCam()
    local success = Movement.setNoclipCam(Config.noclipCamEnabled)
    if not success and Config.noclipCamEnabled then
        warn("Noclip Cam: FAILED - Exploit không tương thích")
        Config.noclipCamEnabled = false
    end
end

----------------------------------------------------------
-- 🔹 Camera Teleport Functions
function Movement.findLowestHealthZombie()
    local char = Config.localPlayer.Character
    local playerHRP = char and char:FindFirstChild("HumanoidRootPart")
    if not playerHRP then return nil end

    local playerPosition = playerHRP.Position
    local lowestZombie = nil
    local lowestHealth = math.huge
    local nearestDistance = math.huge

    for _, zombie in ipairs(Config.entityFolder:GetChildren()) do
        if zombie:IsA("Model") then
            local humanoid = zombie:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local head = zombie:FindFirstChild("Head")
                local hrp = zombie:FindFirstChild("HumanoidRootPart")
                local targetPart = head or hrp
                if targetPart and targetPart:IsA("BasePart") then
                    local currentHealth = humanoid.Health
                    local distance = (playerPosition - targetPart.Position).Magnitude
                    if currentHealth < lowestHealth or (currentHealth == lowestHealth and distance < nearestDistance) then
                        lowestHealth = currentHealth
                        nearestDistance = distance
                        lowestZombie = {part = targetPart, zombie = zombie}
                    end
                end
            end
        end
    end
    return lowestZombie
end

function Movement.findNearestAliveZombie()
    local char = Config.localPlayer.Character
    local playerHRP = char and char:FindFirstChild("HumanoidRootPart")
    if not playerHRP then return nil end

    local playerPosition = playerHRP.Position
    local nearestZombie = nil
    local nearestDistance = math.huge

    for _, zombie in ipairs(Config.entityFolder:GetChildren()) do
        if zombie:IsA("Model") then
            local humanoid = zombie:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local head = zombie:FindFirstChild("Head")
                local hrp = zombie:FindFirstChild("HumanoidRootPart")
                local targetPart = head or hrp
                if targetPart and targetPart:IsA("BasePart") then
                    local distance = (playerPosition - targetPart.Position).Magnitude
                    if distance < nearestDistance then
                        nearestDistance = distance
                        nearestZombie = {part = targetPart, zombie = zombie}
                    end
                end
            end
        end
    end
    return nearestZombie
end

function Movement.findLowestMaxHealthZombie(currentZombie)
    local char = Config.localPlayer.Character
    local playerHRP = char and char:FindFirstChild("HumanoidRootPart")
    if not playerHRP then return nil end
    local playerPosition = playerHRP.Position
    local lowestMaxHealth = math.huge
    local nearestDistance = math.huge
    local result = nil
    
    for _, zombie in ipairs(Config.entityFolder:GetChildren()) do
        if zombie:IsA("Model") then
            local humanoid = zombie:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local head = zombie:FindFirstChild("Head")
                local hrp = zombie:FindFirstChild("HumanoidRootPart")
                local targetPart = head or hrp
                if targetPart and targetPart:IsA("BasePart") then
                    local maxHealth = humanoid.MaxHealth
                    local distance = (playerPosition - targetPart.Position).Magnitude
                    if maxHealth < lowestMaxHealth or (maxHealth == lowestMaxHealth and distance < nearestDistance) then
                        lowestMaxHealth = maxHealth
                        nearestDistance = distance
                        result = {part = targetPart, zombie = zombie, maxHealth = maxHealth}
                    end
                end
            end
        end
    end
    if currentZombie == nil or (result and result.zombie ~= currentZombie) then
        return result
    end
    return nil
end

function Movement.selectInitialTarget()
    if Config.cameraTargetMode == "Nearest" then
        return Movement.findNearestAliveZombie()
    end
    return Movement.findLowestHealthZombie()
end

function Movement.selectNextTarget(currentZombie)
    if Config.cameraTargetMode == "Nearest" then
        return Movement.findNearestAliveZombie()
    end

    if currentZombie then
        local lowerMaxZombie = Movement.findLowestMaxHealthZombie(currentZombie.zombie)
        if lowerMaxZombie then
            return lowerMaxZombie
        end
    end

    return Movement.findLowestHealthZombie()
end

----------------------------------------------------------
-- 🔹 Anti AFK
function Movement.startAntiAFK()
    if Config.antiAFKConnection then return end
    
    local VirtualUser = Config.VirtualUser
    if not VirtualUser then return end
    
    -- Prevent AFK kick by simulating user activity
    Config.antiAFKConnection = Config.localPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

function Movement.stopAntiAFK()
    if Config.antiAFKConnection then
        Config.antiAFKConnection:Disconnect()
        Config.antiAFKConnection = nil
    end
end

function Movement.applyAntiAFK()
    if Config.antiAFKEnabled then
        Movement.startAntiAFK()
    else
        Movement.stopAntiAFK()
    end
end

----------------------------------------------------------
-- 🔹 Character Respawn Handler
function Movement.onCharacterAdded(character)
    Movement.originalWalkSpeed = nil
    task.wait(0.5)

    if Config.speedEnabled then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            Movement.originalWalkSpeed = humanoid.WalkSpeed
        end
        Movement.startSpeedBoost()
    end
    -- Restart anti AFK after respawn
    if Config.antiAFKEnabled then
        Movement.startAntiAFK()
    end
end


----------------------------------------------------------
-- 🔹 Cleanup
----------------------------------------------------------
-- 🔹 Hip Height (Fly on Air)
Movement.hipHeightConnection = nil

function Movement.enableHipHeight(height)
    if Movement.hipHeightConnection then return end
    
    height = height or 10
    
    Movement.hipHeightConnection = Config.RunService.Heartbeat:Connect(function()
        local char = Config.localPlayer.Character
        if char and Config.hipHeightEnabled then
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.HipHeight = height
            end
        end
    end)
end

function Movement.disableHipHeight()
    if Movement.hipHeightConnection then
        Movement.hipHeightConnection:Disconnect()
        Movement.hipHeightConnection = nil
    end
    
    local char = Config.localPlayer.Character
    if char then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.HipHeight = 0
        end
    end
end

function Movement.setHipHeight(height)
    Config.hipHeight = height
    if Config.hipHeightEnabled then
        Movement.disableHipHeight()
        Movement.enableHipHeight(height)
    end
end

----------------------------------------------------------
-- 🔹 Cleanup
function Movement.cleanup()
    Movement.disableNoClip()
    Movement.stopSpeedBoost()
    Movement.stopAntiAFK()
    Movement.disableHipHeight()

    if Config.noclipCamEnabled then
        Config.noclipCamEnabled = false
        Movement.setNoclipCam(false)
    end
end

return Movement
