--[[
    Visuals Module - Zombie Hyperloot
    Remove Fog, Day/Night Time, Fullbright
]]

local Visuals = {}
local Config = nil

-- Settings
Visuals.removeFogEnabled = false
Visuals.fullbrightEnabled = false
Visuals.customTimeEnabled = false
Visuals.customTimeValue = 14 -- 14 = day, 0 = midnight

-- Backup
Visuals.originalLighting = {}

function Visuals.init(config)
    Config = config
end

----------------------------------------------------------
-- 🔹 Remove Fog
Visuals.removedAtmospheres = {}

function Visuals.removeFog()
    local lighting = game:GetService("Lighting")
    
    -- Backup original fog settings
    if not Visuals.originalLighting.fogBackup then
        Visuals.originalLighting.FogEnd = lighting.FogEnd
        Visuals.originalLighting.FogStart = lighting.FogStart
        Visuals.originalLighting.fogBackup = true
    end
    
    -- Remove fog
    lighting.FogEnd = 100000
    
    -- Remove all Atmosphere objects
    for _, v in pairs(lighting:GetDescendants()) do
        if v:IsA("Atmosphere") then
            -- Backup atmosphere
            table.insert(Visuals.removedAtmospheres, v:Clone())
            v:Destroy()
        end
    end
end

function Visuals.restoreFog()
    if not Visuals.originalLighting.fogBackup then return end
    
    local lighting = game:GetService("Lighting")
    lighting.FogEnd = Visuals.originalLighting.FogEnd
    
    -- Restore atmospheres
    for _, atmosphere in ipairs(Visuals.removedAtmospheres) do
        local restored = atmosphere:Clone()
        restored.Parent = lighting
    end
    Visuals.removedAtmospheres = {}
end

function Visuals.toggleRemoveFog(enabled)
    Visuals.removeFogEnabled = enabled
    
    if enabled then
        Visuals.removeFog()
    else
        Visuals.restoreFog()
    end
end

----------------------------------------------------------
-- 🔹 Fullbright
function Visuals.enableFullbright()
    local lighting = game:GetService("Lighting")
    
    -- Backup original settings
    if not Visuals.originalLighting.fullbrightBackup then
        Visuals.originalLighting.Brightness = lighting.Brightness
        Visuals.originalLighting.Ambient = lighting.Ambient
        Visuals.originalLighting.OutdoorAmbient = lighting.OutdoorAmbient
        Visuals.originalLighting.GlobalShadows = lighting.GlobalShadows
        Visuals.originalLighting.fullbrightBackup = true
    end
    
    -- Enable fullbright
    lighting.Brightness = 2
    lighting.Ambient = Color3.fromRGB(255, 255, 255)
    lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    lighting.GlobalShadows = false
end

function Visuals.disableFullbright()
    if not Visuals.originalLighting.fullbrightBackup then return end
    
    local lighting = game:GetService("Lighting")
    lighting.Brightness = Visuals.originalLighting.Brightness
    lighting.Ambient = Visuals.originalLighting.Ambient
    lighting.OutdoorAmbient = Visuals.originalLighting.OutdoorAmbient
    lighting.GlobalShadows = Visuals.originalLighting.GlobalShadows
end

function Visuals.toggleFullbright(enabled)
    Visuals.fullbrightEnabled = enabled
    
    if enabled then
        Visuals.enableFullbright()
    else
        Visuals.disableFullbright()
    end
end

----------------------------------------------------------
-- 🔹 Custom Time (Day/Night)
function Visuals.setCustomTime(timeValue)
    local lighting = game:GetService("Lighting")
    
    -- Backup original time
    if not Visuals.originalLighting.timeBackup then
        Visuals.originalLighting.ClockTime = lighting.ClockTime
        Visuals.originalLighting.timeBackup = true
    end
    
    lighting.ClockTime = timeValue
    Visuals.customTimeValue = timeValue
end

function Visuals.restoreTime()
    if not Visuals.originalLighting.timeBackup then return end
    
    local lighting = game:GetService("Lighting")
    lighting.ClockTime = Visuals.originalLighting.ClockTime
end

function Visuals.toggleCustomTime(enabled)
    Visuals.customTimeEnabled = enabled
    
    if enabled then
        Visuals.setCustomTime(Visuals.customTimeValue)
    else
        Visuals.restoreTime()
    end
end

----------------------------------------------------------
-- 🔹 Apply All
function Visuals.applyAll()
    Visuals.toggleRemoveFog(true)
    Visuals.toggleFullbright(true)
    Visuals.toggleCustomTime(true)
end

function Visuals.disableAll()
    Visuals.toggleRemoveFog(false)
    Visuals.toggleFullbright(false)
    Visuals.toggleCustomTime(false)
end

----------------------------------------------------------
-- 🔹 Remove Effects
Visuals.removedEffects = {}
Visuals.effectsRemoved = false

function Visuals.removeAllEffects()
    local success, err = pcall(function()
        local replicatedFirst = game:GetService("ReplicatedFirst")
        local baseEffectPath = replicatedFirst:WaitForChild("Scripts"):WaitForChild("Object"):WaitForChild("Data"):WaitForChild("BaseEffect")
        
        -- Danh sách các effect cần xóa
        local effectNames = {
            "ShotEntityEffect",
            "ShotHitEffect",
            "HitEffect"
        }
        
        -- Xóa từng effect
        for _, effectName in ipairs(effectNames) do
            local effect = baseEffectPath:FindFirstChild(effectName)
            if effect then
                -- Backup effect trước khi xóa
                table.insert(Visuals.removedEffects, {
                    name = effectName,
                    parent = effect.Parent,
                    clone = effect:Clone()
                })
                
                -- Xóa effect
                effect:Destroy()
            end
        end
        
        Visuals.effectsRemoved = true
    end)
    
    if not success then
        warn("[Visuals] Lỗi khi xóa effects: " .. tostring(err))
    end
end

function Visuals.restoreAllEffects()
    if #Visuals.removedEffects == 0 then
        return
    end
    
    local success, err = pcall(function()
        -- Khôi phục từng effect
        for _, effectData in ipairs(Visuals.removedEffects) do
            local restored = effectData.clone:Clone()
            restored.Parent = effectData.parent
        end
        
        Visuals.removedEffects = {}
        Visuals.effectsRemoved = false
    end)
    
    if not success then
        warn("[Visuals] Lỗi khi khôi phục effects: " .. tostring(err))
    end
end

function Visuals.toggleRemoveEffects(enabled)
    if enabled then
        Visuals.removeAllEffects()
    else
        Visuals.restoreAllEffects()
    end
end

----------------------------------------------------------
-- 🔹 ProximityPrompt Range Circle
Visuals.rangeCircles = {}

function Visuals.createRangeCircle(promptObject, radius, color)
    if not promptObject or not promptObject.Parent then
        warn("[Visuals] Invalid ProximityPrompt object")
        return nil
    end
    
    -- Tìm part chứa prompt
    local parentPart = promptObject.Parent
    if not parentPart:IsA("BasePart") and not parentPart:IsA("Attachment") then
        warn("[Visuals] ProximityPrompt parent is not a BasePart or Attachment")
        return nil
    end
    
    -- Nếu parent là Attachment, lấy part chứa attachment
    local targetPart = parentPart
    if parentPart:IsA("Attachment") then
        targetPart = parentPart.Parent
    end
    
    if not targetPart or not targetPart:IsA("BasePart") then
        warn("[Visuals] Cannot find BasePart for range circle")
        return nil
    end
    
    -- Tạo Part hình trụ làm vòng tròn
    local circle = Instance.new("Part")
    circle.Name = "RangeCircle"
    circle.Shape = Enum.PartType.Cylinder
    circle.Size = Vector3.new(0.2, radius * 2, radius * 2) -- Cylinder: X = height, Y/Z = diameter
    circle.Anchored = true
    circle.CanCollide = false
    circle.Transparency = 0.7
    circle.Material = Enum.Material.Neon
    circle.Color = color or Color3.fromRGB(255, 255, 0) -- Vàng mặc định
    circle.TopSurface = Enum.SurfaceType.Smooth
    circle.BottomSurface = Enum.SurfaceType.Smooth
    
    -- Đặt vị trí và xoay để nằm ngang (vòng tròn trên mặt đất)
    circle.CFrame = targetPart.CFrame * CFrame.Angles(0, 0, math.rad(90))
    
    -- Tạo WeldConstraint để circle theo part
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = targetPart
    weld.Part1 = circle
    weld.Parent = circle
    
    circle.Parent = workspace
    
    -- Lưu vào table để cleanup sau
    table.insert(Visuals.rangeCircles, circle)
    
    return circle
end

function Visuals.drawProximityRange(promptPath, radius, color)
    local success, prompt = pcall(function()
        -- Parse path string thành object
        local parts = string.split(promptPath, ".")
        local current = game
        
        for _, part in ipairs(parts) do
            -- Xử lý GetChildren()[index]
            if string.match(part, "GetChildren%(%)[[](%d+)[]]") then
                local index = tonumber(string.match(part, "GetChildren%(%)[[](%d+)[]]"))
                current = current:GetChildren()[index]
            -- Xử lý ["name"]
            elseif string.match(part, '%["(.+)"%]') then
                local name = string.match(part, '%["(.+)"%]')
                current = current:FindFirstChild(name)
            -- Xử lý name thông thường
            else
                current = current:FindFirstChild(part)
            end
            
            if not current then
                warn("[Visuals] Path not found: " .. promptPath)
                return nil
            end
        end
        
        return current
    end)
    
    if not success or not prompt then
        warn("[Visuals] Failed to find ProximityPrompt at path: " .. promptPath)
        return nil
    end
    
    return Visuals.createRangeCircle(prompt, radius, color)
end

-- Vẽ vòng tròn cho tất cả Supply, Task, Car
function Visuals.drawAllProximityRanges()
    if not Config then
        warn("[Visuals] Config not initialized")
        return
    end
    
    local map = Config.Workspace:FindFirstChild("Map")
    if not map then
        warn("[Visuals] Map not found")
        return
    end
    
    local count = {supply = 0, task = 0, car = 0}
    
    for _, mapChild in ipairs(map:GetChildren()) do
        if mapChild:IsA("Model") then
            local eItem = mapChild:FindFirstChild("EItem")
            if eItem then
                -- Supply (màu vàng)
                for _, eItemChild in ipairs(eItem:GetChildren()) do
                    for _, descendant in ipairs(eItemChild:GetDescendants()) do
                        if descendant:IsA("BasePart") and string.match(descendant.Name, "SM_Prop_SupplyPile") then
                            for _, child in ipairs(descendant:GetDescendants()) do
                                if child:IsA("ProximityPrompt") then
                                    Visuals.createRangeCircle(child, 10, Color3.fromRGB(255, 255, 0)) -- Vàng
                                    count.supply = count.supply + 1
                                    break
                                end
                            end
                            break
                        end
                    end
                end
                
                -- Task (màu xanh dương)
                local taskObj = eItem:FindFirstChild("Task")
                if taskObj then
                    for _, desc in ipairs(taskObj:GetDescendants()) do
                        if desc:IsA("ProximityPrompt") then
                            Visuals.createRangeCircle(desc, 10, Color3.fromRGB(0, 150, 255)) -- Xanh dương
                            count.task = count.task + 1
                            break
                        end
                    end
                end
                
                -- Car (màu xanh lá)
                local carObj = eItem:FindFirstChild("Car")
                if carObj then
                    for _, desc in ipairs(carObj:GetDescendants()) do
                        if desc:IsA("ProximityPrompt") then
                            Visuals.createRangeCircle(desc, 10, Color3.fromRGB(0, 255, 0)) -- Xanh lá
                            count.car = count.car + 1
                            break
                        end
                    end
                end
            end
        end
    end
    
    print(string.format("[Visuals] Drew range circles: %d Supply, %d Task, %d Car", count.supply, count.task, count.car))
    
    if Config.UI and Config.UI.Library then
        Config.UI.Library:Notify({
            Title = "Range Circles",
            Description = string.format("Drew: %d Supply, %d Task, %d Car", count.supply, count.task, count.car),
            Time = 3
        })
    end
end

function Visuals.clearRangeCircles()
    for _, circle in ipairs(Visuals.rangeCircles) do
        if circle and circle.Parent then
            circle:Destroy()
        end
    end
    Visuals.rangeCircles = {}
end

----------------------------------------------------------
-- 🔹 Reload Gun Full Ammo
function Visuals.reloadGunFullAmmo()
    local success, err = pcall(function()
        local player = game:GetService("Players").LocalPlayer
        local char = player.Character
        if not char then
            warn("[ReloadGun] Character not found")
            return false
        end
        
        local netMessage = char:WaitForChild("NetMessage", 2)
        if not netMessage then
            warn("[ReloadGun] NetMessage not found")
            return false
        end
        
        local trigerSkill = netMessage:WaitForChild("TrigerSkill", 2)
        if not trigerSkill then
            warn("[ReloadGun] TrigerSkill not found")
            return false
        end
        
        -- Fire server với args GunReload
        local args = {"GunReload", "Enter", 999}
        trigerSkill:FireServer(unpack(args))
        
        if Config and Config.UI and Config.UI.Library then
            Config.UI.Library:Notify({
                Title = "Reload Gun",
                Description = "Full ammo reloaded!",
                Time = 2
            })
        end
        
        return true
    end)
    
    if not success then
        warn("[ReloadGun] Error: " .. tostring(err))
        return false
    end
    
    return true
end

----------------------------------------------------------
-- 🔹 Cleanup
function Visuals.cleanup()
    Visuals.restoreFog()
    Visuals.disableFullbright()
    Visuals.restoreTime()
    
    -- Khôi phục effects khi unload script
    if Visuals.effectsRemoved then
        Visuals.restoreAllEffects()
    end
    
    -- Xóa range circles
    Visuals.clearRangeCircles()
end

return Visuals
