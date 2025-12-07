--[[
    Combat Module - Zombie Hyperloot
    Aimbot, Hitbox, TrigerSkill Dupe, Auto Skill
]]

local Combat = {}
local Config = nil

function Combat.init(config)
    Config = config
end

-- Lưu zombie đã xử lý hitbox
Combat.processedZombies = {}

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
-- 🔹 Aimbot Functions
Combat.holdingMouse2 = false
Combat.FOVCircle = nil
Combat.hasFOVDrawing = false

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
    local closestChar, closestPart
    local closestDist = math.huge
    
    for _, char in ipairs(Combat.getAimbotTargets()) do
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        if hum and hum.Health > 0 then
            local part = char:FindFirstChild(Config.aimbotAimPart)
            if not part then
                part = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("Head")
            end
            if part then
                local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
                if onScreen and screenPos.Z > 0 then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if (not Config.aimbotFOVEnabled) or dist <= Config.aimbotFOVRadius then
                        if dist < closestDist then
                            closestDist = dist
                            closestChar = char
                            closestPart = part
                        end
                    end
                end
            end
        end
    end
    
    return closestChar, closestPart
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
-- 🔹 Remove Shot Effects
Combat.removeShotEffectsEnabled = false
Combat.originalShotHitEffect = nil
Combat.originalHitEffect = nil
Combat.dummyShotHitEffect = nil
Combat.dummyHitEffect = nil

function Combat.removeShotEffects()
    if Combat.removeShotEffectsEnabled then return end
    
    task.spawn(function()
        local ReplicatedFirst = game:GetService("ReplicatedFirst")
        
        -- Wait for Scripts folder
        local scripts = ReplicatedFirst:WaitForChild("Scripts", 10)
        if not scripts then
            warn("[Combat] Scripts folder not found")
            return
        end
        
        -- Wait for Object folder
        local object = scripts:WaitForChild("Object", 10)
        if not object then
            warn("[Combat] Object folder not found")
            return
        end
        
        -- Wait for Data folder
        local data = object:WaitForChild("Data", 10)
        if not data then
            warn("[Combat] Data folder not found")
            return
        end
        
        -- Wait for BaseEffect folder
        local baseEffect = data:WaitForChild("BaseEffect", 10)
        if not baseEffect then
            warn("[Combat] BaseEffect folder not found")
            return
        end
        
        -- Wait for effects to exist
        local shotHitEffect = baseEffect:WaitForChild("ShotHitEffect", 10)
        local hitEffect = baseEffect:WaitForChild("HitEffect", 10)
        
        -- Backup original effects
        if shotHitEffect then
            Combat.originalShotHitEffect = shotHitEffect:Clone()
        end
        
        if hitEffect then
            Combat.originalHitEffect = hitEffect:Clone()
        end
        
        -- Create dummy modules that return empty functions
        if shotHitEffect and shotHitEffect:IsA("ModuleScript") then
            Combat.dummyShotHitEffect = Instance.new("ModuleScript")
            Combat.dummyShotHitEffect.Name = "ShotHitEffect"
            Combat.dummyShotHitEffect.Source = [[
                local module = {}
                function module.new(...) return setmetatable({}, {__index = function() return function() end end}) end
                return module
            ]]
            shotHitEffect:Destroy()
            Combat.dummyShotHitEffect.Parent = baseEffect
            print("[Combat] Replaced ShotHitEffect with dummy")
        end
        
        if hitEffect and hitEffect:IsA("ModuleScript") then
            Combat.dummyHitEffect = Instance.new("ModuleScript")
            Combat.dummyHitEffect.Name = "HitEffect"
            Combat.dummyHitEffect.Source = [[
                local module = {}
                function module.new(...) return setmetatable({}, {__index = function() return function() end end}) end
                return module
            ]]
            hitEffect:Destroy()
            Combat.dummyHitEffect.Parent = baseEffect
            print("[Combat] Replaced HitEffect with dummy")
        end
        
        Combat.removeShotEffectsEnabled = true
    end)
end

function Combat.restoreShotEffects()
    if not Combat.removeShotEffectsEnabled then return end
    
    local ReplicatedFirst = game:GetService("ReplicatedFirst")
    local baseEffectPath = ReplicatedFirst:FindFirstChild("Scripts")
    
    if baseEffectPath then
        baseEffectPath = baseEffectPath:FindFirstChild("Object")
        if baseEffectPath then
            baseEffectPath = baseEffectPath:FindFirstChild("Data")
            if baseEffectPath then
                baseEffectPath = baseEffectPath:FindFirstChild("BaseEffect")
                
                if baseEffectPath then
                    -- Remove dummy modules
                    if Combat.dummyShotHitEffect then
                        Combat.dummyShotHitEffect:Destroy()
                        Combat.dummyShotHitEffect = nil
                    end
                    
                    if Combat.dummyHitEffect then
                        Combat.dummyHitEffect:Destroy()
                        Combat.dummyHitEffect = nil
                    end
                    
                    -- Restore original effects
                    if Combat.originalShotHitEffect then
                        local restored = Combat.originalShotHitEffect:Clone()
                        restored.Parent = baseEffectPath
                        print("[Combat] Restored ShotHitEffect")
                    end
                    
                    if Combat.originalHitEffect then
                        local restored = Combat.originalHitEffect:Clone()
                        restored.Parent = baseEffectPath
                        print("[Combat] Restored HitEffect")
                    end
                    
                    Combat.removeShotEffectsEnabled = false
                end
            end
        end
    end
end

function Combat.toggleRemoveShotEffects(enabled)
    if enabled then
        Combat.removeShotEffects()
    else
        Combat.restoreShotEffects()
    end
end

function Combat.cleanup()
    Combat.restoreShotEffects()
    
    if Combat.FOVCircle then
        pcall(function() Combat.FOVCircle:Remove() end)
        Combat.FOVCircle = nil
    end
    Combat.processedZombies = {}
end

return Combat
