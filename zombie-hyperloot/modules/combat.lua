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

            if Config.trigerSkillDupeEnabled
                and callMethod == "FireServer"
                and not checkcaller()
                and typeof(remoteInstance) == "Instance"
                and remoteInstance.Name == "TrigerSkill" then

                local firstArgument = remoteArguments[1]
                local secondArgument = remoteArguments[2]

                if firstArgument == "GunFire" and secondArgument == "Atk" then
                    -- Kích hoạt remove effects lần đầu tiên
                    if not Combat.firstDupeTriggered and Config.removeEffectsEnabled then
                        Combat.firstDupeTriggered = true
                        if Visuals and Visuals.removeAllEffects then
                            task.spawn(function()
                                Visuals.removeAllEffects()
                            end)
                        end
                    end
                    
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
-- 🔹 Auto Skill Loop
function Combat.triggerSkill(skillId)
    local char = Config.localPlayer.Character
    if not char then return end
    
    local tool = char:FindFirstChild("Tool")
    if not tool then return end
    
    local netMessage = char:FindFirstChild("NetMessage")
    if not netMessage then return end
    
    pcall(function()
        netMessage:WaitForChild("TrigerSkill"):FireServer(skillId, "Enter")
    end)
end

function Combat.activateSkill1010()
    Combat.triggerSkill(1010)
end

function Combat.activateSkill1002()
    Combat.triggerSkill(1002)
end

function Combat.startSkillLoop(getInterval, action)
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

function Combat.startAllSkillLoops()
    Combat.startSkillLoop(function() return Config.skill1010Interval end, Combat.activateSkill1010)
    Combat.startSkillLoop(function() return Config.skill1002Interval end, Combat.activateSkill1002)
end

----------------------------------------------------------
-- 🔹 Auto Aim Camera (360 độ)
Combat.autoAimCameraConnection = nil

function Combat.getAutoAimCameraTargets()
    local targets = {}
    local mode = Config.autoAimCameraTargetMode or "Zombies"
    
    if mode == "Players" or mode == "All" then
        for _, plr in ipairs(Config.Players:GetPlayers()) do
            if plr ~= Config.localPlayer and plr.Character then
                local hum = plr.Character:FindFirstChildWhichIsA("Humanoid")
                if hum and hum.Health > 0 then
                    table.insert(targets, plr.Character)
                end
            end
        end
    end
    
    if mode == "Zombies" or mode == "All" then
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

function Combat.getAutoAimCameraTarget()
    local localChar = Config.localPlayer.Character
    local localHRP = localChar and localChar:FindFirstChild("HumanoidRootPart")
    if not localHRP then return nil end
    
    local bestTarget = nil
    local bestScore = nil
    local priority = Config.autoAimCameraPriority or "Nearest"
    
    for _, char in ipairs(Combat.getAutoAimCameraTargets()) do
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        if hum and hum.Health > 0 then
            local targetPart = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
            if targetPart then
                -- Wall check
                if Config.autoAimCameraWallCheck and not Combat.isTargetVisible(targetPart) then
                    continue
                end
                
                local distance = (localHRP.Position - targetPart.Position).Magnitude
                local score
                
                if priority == "LowestHealth" then
                    score = hum.Health
                else -- Nearest
                    score = distance
                end
                
                if bestScore == nil or score < bestScore then
                    bestScore = score
                    bestTarget = targetPart
                end
            end
        end
    end
    
    return bestTarget
end

function Combat.updateAutoAimCamera()
    if not Config.autoAimCameraEnabled then return end
    if Config.scriptUnloaded then return end
    
    local camera = Config.Workspace.CurrentCamera
    if not camera then return end
    
    local targetPart = Combat.getAutoAimCameraTarget()
    if not targetPart then return end
    
    local smoothness = Config.autoAimCameraSmoothness or 0.15
    local targetCFrame = CFrame.new(camera.CFrame.Position, targetPart.Position)
    
    -- Lerp camera để xoay mượt
    camera.CFrame = camera.CFrame:Lerp(targetCFrame, 1 - smoothness)
end

function Combat.startAutoAimCamera()
    if Combat.autoAimCameraConnection then
        Combat.autoAimCameraConnection:Disconnect()
    end
    
    Combat.autoAimCameraConnection = Config.RunService.RenderStepped:Connect(function()
        Combat.updateAutoAimCamera()
    end)
end

function Combat.stopAutoAimCamera()
    if Combat.autoAimCameraConnection then
        Combat.autoAimCameraConnection:Disconnect()
        Combat.autoAimCameraConnection = nil
    end
end

----------------------------------------------------------
-- 🔹 Aimbot Functions
Combat.holdingMouse2 = false
Combat.autoFireHolding = false
Combat.FOVCircle = nil
Combat.hasFOVDrawing = false

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

function Combat.cleanup()
    Combat.setAutoFireActive(false)
    Combat.stopAutoAimCamera()

    if Combat.FOVCircle then
        pcall(function() Combat.FOVCircle:Remove() end)
        Combat.FOVCircle = nil
    end
    Combat.processedZombies = {}
end


return Combat
