--[[
    Combat Module - Zombie Hyperloot
    Aimbot, Hitbox, TrigerSkill Dupe, Auto Skill
]]

local Combat = {}
local Config = nil
local Visuals = nil

function Combat.init(config, visuals)
    Config = config
    Visuals = visuals
end

-- Lưu zombie đã xử lý hitbox
Combat.processedZombies = {}

-- Biến để track lần đầu tiên dupe
Combat.firstDupeTriggered = false

----------------------------------------------------------
-- 🔹 TrigerSkill GunFire Dupe
local oldTrigerSkillNamecall = nil

function Combat.setupTrigerSkillDupe()
    if hookmetamethod and getnamecallmethod and checkcaller then
        oldTrigerSkillNamecall = hookmetamethod(game, "__namecall", function(remoteInstance, ...)
            local callMethod = getnamecallmethod()
            local remoteArguments = {...}

            -- Check remove effects cho mọi lần bắn (không cần đợi dupe)
            if callMethod == "FireServer"
                and not checkcaller()
                and typeof(remoteInstance) == "Instance"
                and remoteInstance.Name == "TrigerSkill" then

                local firstArgument = remoteArguments[1]
                local secondArgument = remoteArguments[2]

                if firstArgument == "GunFire" and secondArgument == "Atk" then
                    -- Logic Remove Effects đã được chuyển sang Visuals module để tự động quét
                end
            end

            -- Logic dupe riêng biệt
            if Config.trigerSkillDupeEnabled
                and callMethod == "FireServer"
                and not checkcaller()
                and typeof(remoteInstance) == "Instance"
                and remoteInstance.Name == "TrigerSkill" then

                local firstArgument = remoteArguments[1]
                local secondArgument = remoteArguments[2]

                if firstArgument == "GunFire" and secondArgument == "Atk" then
                    for i = 1, Config.trigerSkillDupeCount do
                        oldTrigerSkillNamecall(remoteInstance, table.unpack(remoteArguments))
                    end
                    return
                end
            end

            return oldTrigerSkillNamecall(remoteInstance, ...)
        end)
    else
        warn("[ZombieHyperloot] Executor không hỗ trợ hookmetamethod - TrigerSkill dupe tắt")
    end
end

----------------------------------------------------------
-- 🔹 Hitbox Expander
function Combat.expandHitbox(zombie)
    if Combat.processedZombies[zombie] then return end
    
    local head = zombie:WaitForChild("Head", 4)
    if not head then return end
    
    if head:IsA("BasePart") then
        if not head:GetAttribute("OriginalSize") then
            head:SetAttribute("OriginalSizeX", head.Size.X)
            head:SetAttribute("OriginalSizeY", head.Size.Y)
            head:SetAttribute("OriginalSizeZ", head.Size.Z)
        end
        
        if Config.hitboxEnabled then
            head.Size = Config.hitboxSize
            head.Transparency = 0.5
            head.Color = Color3.fromRGB(255, 0, 0)
            head.CanCollide = false
        end
        
        Combat.processedZombies[zombie] = true
    end
end

function Combat.restoreHitbox(zombie)
    local head = zombie:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        local origX = head:GetAttribute("OriginalSizeX")
        local origY = head:GetAttribute("OriginalSizeY")
        local origZ = head:GetAttribute("OriginalSizeZ")
        
        if origX and origY and origZ then
            head.Size = Vector3.new(origX, origY, origZ)
            head.Transparency = 1
            head.CanCollide = true
        end
    end
end

function Combat.updateAllHitboxes(enabled)
    for _, zombie in ipairs(Config.entityFolder:GetChildren()) do
        if zombie:IsA("Model") then
            local head = zombie:FindFirstChild("Head")
            if head and head:IsA("BasePart") then
                if enabled then
                    head.Size = Config.hitboxSize
                    head.Transparency = 0.5
                    head.Color = Color3.fromRGB(255, 0, 0)
                    head.CanCollide = false
                else
                    Combat.restoreHitbox(zombie)
                end
            end
        end
    end
end

----------------------------------------------------------
-- 🔹 Aimbot Functions
Combat.holdingMouse2 = false
Combat.autoFireHolding = false
Combat.FOVCircle = nil
Combat.hasFOVDrawing = false

-- Auto Camera Rotation 360°
Combat.autoRotateConnection = nil
Combat.autoRotateEnabled = false
Combat.rotationSmoothness = 0.05 -- 0 = instant, higher = smoother

local function sendMouseButton1State(isDown)
    if not Config or not Config.VirtualInputManager then
        return
    end

    local mousePos = Config.UserInputService:GetMouseLocation()
    pcall(function()
        Config.VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, isDown, game, 0)
    end)
end

function Combat.setAutoFireActive(shouldHold)
    if not Config then return end

    if Config.scriptUnloaded or not Config.aimbotAutoFireEnabled then
        shouldHold = false
    end

    if shouldHold and not Combat.autoFireHolding then
        Combat.autoFireHolding = true
        sendMouseButton1State(true)
    elseif not shouldHold and Combat.autoFireHolding then
        Combat.autoFireHolding = false
        sendMouseButton1State(false)
    end
end

function Combat.initFOVCircle()

    local ok, obj = pcall(function()
        return Drawing.new("Circle")
    end)
    if ok and obj then
        Combat.hasFOVDrawing = true
        obj:Remove()
        
        Combat.FOVCircle = Drawing.new("Circle")
        Combat.FOVCircle.NumSides = 64
        Combat.FOVCircle.Thickness = 1.5
        Combat.FOVCircle.Filled = false
        Combat.FOVCircle.Color = Color3.fromRGB(255, 255, 255)
        Combat.FOVCircle.Visible = false
        Combat.FOVCircle.Transparency = 0.8
    end
end

function Combat.isTargetVisible(targetPart)
    if not Config.aimbotWallCheckEnabled then
        return true
    end

    if not targetPart or not targetPart:IsA("BasePart") then
        return false
    end

    local camera = Config.Workspace.CurrentCamera
    if not camera then
        return true
    end

    local origin = camera.CFrame.Position
    local direction = targetPart.Position - origin
    if direction.Magnitude <= 0 then
        return true
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.IgnoreWater = true

    local blacklist = {}
    local localChar = Config.localPlayer and Config.localPlayer.Character
    if localChar then
        table.insert(blacklist, localChar)
    end

    params.FilterDescendantsInstances = blacklist

    local result = Config.Workspace:Raycast(origin, direction, params)
    if not result then
        return true
    end

    local hitInstance = result.Instance
    if not hitInstance then
        return true
    end

    local targetModel = targetPart:FindFirstAncestorOfClass("Model") or targetPart.Parent
    if targetModel and hitInstance:IsDescendantOf(targetModel) then
        return true
    end

    if hitInstance:IsA("BasePart") then
        if hitInstance.CanCollide == false and hitInstance.Transparency >= 0.95 then
            return true
        end
    end

    return false
end


function Combat.getAimbotTargets()
    local targets = {}
    
    if Config.aimbotTargetMode == "Players" or Config.aimbotTargetMode == "All" then
        for _, plr in ipairs(Config.Players:GetPlayers()) do
            if plr ~= Config.localPlayer and plr.Character then
                local hum = plr.Character:FindFirstChildWhichIsA("Humanoid")
                if hum and hum.Health > 0 then
                    if not Config.espPlayerTeamCheck or plr.Team ~= Config.localPlayer.Team then
                        table.insert(targets, plr.Character)
                    end
                end
            end
        end
    end
    
    if Config.aimbotTargetMode == "Zombies" or Config.aimbotTargetMode == "All" then
        for _, m in ipairs(Config.entityFolder:GetChildren()) do
            if m:IsA("Model") then
                local hum = m:FindFirstChildWhichIsA("Humanoid")
                if hum and hum.Health > 0 then
                    table.insert(targets, m)
                end
            end
        end
    end
    
    return targets
end

function Combat.getClosestAimbotTarget()
    local camera = Config.Workspace.CurrentCamera
    local mousePos = Config.UserInputService:GetMouseLocation()
    local localChar = Config.localPlayer.Character
    local localHRP = localChar and localChar:FindFirstChild("HumanoidRootPart")

    local bestChar, bestPart
    local bestScore = nil
    local priorityMode = Config.aimbotPriorityMode or "Nearest"

    local function isBetter(score, currentBest)
        if currentBest == nil then return true end
        if priorityMode == "Nearest" then
            return score < currentBest
        elseif priorityMode == "Farthest" then
            return score > currentBest
        elseif priorityMode == "LowestHealth" then
            return score < currentBest
        elseif priorityMode == "HighestHealth" then
            return score > currentBest
        end
        return score < currentBest
    end
    
    for _, char in ipairs(Combat.getAimbotTargets()) do
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        if hum and hum.Health > 0 then
            local part = nil
            
            -- Random mode: chọn ngẫu nhiên từ danh sách parts
            if Config.aimbotAimPart == "Random" then
                local randomParts = Config.aimbotRandomParts or {"Head", "UpperTorso", "HumanoidRootPart", "Torso"}
                local shuffled = {}
                for _, p in ipairs(randomParts) do table.insert(shuffled, p) end
                for i = #shuffled, 2, -1 do
                    local j = math.random(i)
                    shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
                end
                for _, partName in ipairs(shuffled) do
                    part = char:FindFirstChild(partName)
                    if part then break end
                end
            else
                part = char:FindFirstChild(Config.aimbotAimPart)
            end
            
            if not part then
                part = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("Head")
            end
            if part then
                -- Check wall trước
                if not Combat.isTargetVisible(part) then
                    continue
                end
                
                local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
                if onScreen and screenPos.Z > 0 then
                    local cursorDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if (not Config.aimbotFOVEnabled) or cursorDist <= Config.aimbotFOVRadius then
                        local score
                        if priorityMode == "LowestHealth" or priorityMode == "HighestHealth" then
                            score = hum.Health
                        else
                            if localHRP then
                                score = (localHRP.Position - part.Position).Magnitude
                            else
                                score = cursorDist
                            end
                        end

                        if isBetter(score, bestScore) then
                            bestScore = score
                            bestChar = char
                            bestPart = part
                        end
                    end
                end
            end
        end
    end
    
    return bestChar, bestPart
end




function Combat.setupMouseInput()
    Config.UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or Config.scriptUnloaded then return end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            Combat.holdingMouse2 = true
        end
    end)

    Config.UserInputService.InputEnded:Connect(function(input)
        if Config.scriptUnloaded then return end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            Combat.holdingMouse2 = false
        end
    end)
end

----------------------------------------------------------
-- 🔹 Auto Camera Rotation 360° to Zombies (with Wall Check)

function Combat.findClosestZombieForRotation()
    local char = Config.localPlayer.Character
    local playerHRP = char and char:FindFirstChild("HumanoidRootPart")
    if not playerHRP then return nil end

    local playerPosition = playerHRP.Position
    local closestZombie = nil
    local closestDistance = math.huge

    for _, zombie in ipairs(Config.entityFolder:GetChildren()) do
        if zombie:IsA("Model") then
            local humanoid = zombie:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local head = zombie:FindFirstChild("Head")
                local hrp = zombie:FindFirstChild("HumanoidRootPart")
                local targetPart = head or hrp
                if targetPart and targetPart:IsA("BasePart") then
                    -- Check wall trước (sử dụng chung setting với aimbot)
                    if not Combat.isTargetVisible(targetPart) then
                        continue
                    end
                    
                    local distance = (playerPosition - targetPart.Position).Magnitude
                    if distance < closestDistance then
                        closestDistance = distance
                        closestZombie = {part = targetPart, zombie = zombie, distance = distance}
                    end
                end
            end
        end
    end
    return closestZombie
end

function Combat.startAutoRotate()
    if Combat.autoRotateConnection then return end
    
    Combat.autoRotateConnection = Config.RunService.RenderStepped:Connect(function()
        if not Combat.autoRotateEnabled or Config.scriptUnloaded then return end
        
        -- Tìm zombie gần nhất (có wall check)
        local target = Combat.findClosestZombieForRotation()
        if not target then return end
        
        local camera = Config.Workspace.CurrentCamera
        if not camera then return end
        
        local targetPos = target.part.Position
        local currentCF = camera.CFrame
        local desiredCF = CFrame.new(currentCF.Position, targetPos)
        
        -- Áp dụng smoothness
        if Combat.rotationSmoothness > 0 then
            local alpha = 1 - Combat.rotationSmoothness
            alpha = math.clamp(alpha, 0.01, 1)
            camera.CFrame = currentCF:Lerp(desiredCF, alpha)
        else
            camera.CFrame = desiredCF
        end
    end)
end

function Combat.stopAutoRotate()
    if Combat.autoRotateConnection then
        Combat.autoRotateConnection:Disconnect()
        Combat.autoRotateConnection = nil
    end
end

function Combat.toggleAutoRotate(enabled)
    Combat.autoRotateEnabled = enabled
    
    if enabled then
        Combat.startAutoRotate()
    else
        Combat.stopAutoRotate()
    end
end

function Combat.setRotationSmoothness(value)
    Combat.rotationSmoothness = math.clamp(value or 0.05, 0, 0.9)
end



function Combat.cleanup()
    Combat.setAutoFireActive(false)
    Combat.stopAutoRotate() -- Tắt auto rotate

    if Combat.FOVCircle then
        pcall(function() Combat.FOVCircle:Remove() end)
        Combat.FOVCircle = nil
    end
    Combat.processedZombies = {}
end


return Combat
