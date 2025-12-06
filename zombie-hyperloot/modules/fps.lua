--[[
    FPS Booster Module - Zombie Hyperloot
    Xóa effects/particles, giảm texture quality, tắt shadows/lighting
]]

local FPS = {}
local Config = nil

-- FPS Settings
FPS.removeEffectsEnabled = false
FPS.reduceLightingEnabled = false
FPS.reduceTextureEnabled = false
FPS.removeWeaponEffectsEnabled = false
FPS.removeProjectilesEnabled = false
FPS.reduceSoundsEnabled = false
FPS.removeDebrisEnabled = false
FPS.reduceAnimationsEnabled = false

-- Backup
FPS.originalLighting = {}
FPS.removedEffects = {}
FPS.weaponEffectsConnection = nil
FPS.projectileConnection = nil
FPS.debrisConnection = nil
FPS.originalSoundVolume = {}
FPS.currentFPS = 0

function FPS.init(config)
    Config = config
end

----------------------------------------------------------
-- 🔹 Remove Effects & Particles
function FPS.removeEffects()
    if not FPS.removeEffectsEnabled then return end
    
    local count = 0
    
    -- Xóa tất cả effects trong Workspace
    for _, obj in ipairs(Config.Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or 
           obj:IsA("Trail") or 
           obj:IsA("Beam") or 
           obj:IsA("Fire") or 
           obj:IsA("Smoke") or 
           obj:IsA("Sparkles") or 
           obj:IsA("PointLight") or 
           obj:IsA("SpotLight") or 
           obj:IsA("SurfaceLight") then
            
            -- Backup để restore sau
            table.insert(FPS.removedEffects, {
                instance = obj,
                enabled = obj:IsA("ParticleEmitter") and obj.Enabled or true
            })
            
            -- Disable hoặc xóa
            if obj:IsA("ParticleEmitter") then
                obj.Enabled = false
            else
                pcall(function() obj:Destroy() end)
            end
            
            count = count + 1
        end
    end
    
    print(string.format("[FPS Booster] Removed %d effects/particles", count))
end

function FPS.restoreEffects()
    for _, data in ipairs(FPS.removedEffects) do
        if data.instance and data.instance.Parent then
            if data.instance:IsA("ParticleEmitter") then
                data.instance.Enabled = data.enabled
            end
        end
    end
    
    FPS.removedEffects = {}
    print("[FPS Booster] Restored effects")
end

----------------------------------------------------------
-- 🔹 Reduce Lighting Quality
function FPS.reduceLighting()
    if not FPS.reduceLightingEnabled then return end
    
    local lighting = game:GetService("Lighting")
    
    -- Backup original settings
    if not FPS.originalLighting.backed then
        FPS.originalLighting = {
            GlobalShadows = lighting.GlobalShadows,
            Brightness = lighting.Brightness,
            OutdoorAmbient = lighting.OutdoorAmbient,
            Ambient = lighting.Ambient,
            FogEnd = lighting.FogEnd,
            FogStart = lighting.FogStart,
            backed = true
        }
    end
    
    -- Tắt shadows và giảm lighting
    lighting.GlobalShadows = false
    lighting.Brightness = 2
    lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    lighting.Ambient = Color3.fromRGB(128, 128, 128)
    lighting.FogEnd = 100000
    lighting.FogStart = 0
    
    -- Xóa các lighting effects
    for _, effect in ipairs(lighting:GetChildren()) do
        if effect:IsA("BloomEffect") or 
           effect:IsA("BlurEffect") or 
           effect:IsA("ColorCorrectionEffect") or 
           effect:IsA("DepthOfFieldEffect") or 
           effect:IsA("SunRaysEffect") then
            effect.Enabled = false
        end
    end
    
    print("[FPS Booster] Reduced lighting quality")
end

function FPS.restoreLighting()
    if not FPS.originalLighting.backed then return end
    
    local lighting = game:GetService("Lighting")
    
    lighting.GlobalShadows = FPS.originalLighting.GlobalShadows
    lighting.Brightness = FPS.originalLighting.Brightness
    lighting.OutdoorAmbient = FPS.originalLighting.OutdoorAmbient
    lighting.Ambient = FPS.originalLighting.Ambient
    lighting.FogEnd = FPS.originalLighting.FogEnd
    lighting.FogStart = FPS.originalLighting.FogStart
    
    -- Bật lại lighting effects
    for _, effect in ipairs(lighting:GetChildren()) do
        if effect:IsA("BloomEffect") or 
           effect:IsA("BlurEffect") or 
           effect:IsA("ColorCorrectionEffect") or 
           effect:IsA("DepthOfFieldEffect") or 
           effect:IsA("SunRaysEffect") then
            effect.Enabled = true
        end
    end
    
    print("[FPS Booster] Restored lighting")
end

----------------------------------------------------------
-- 🔹 Reduce Texture Quality
function FPS.reduceTextures()
    if not FPS.reduceTextureEnabled then return end
    
    local count = 0
    
    -- Giảm chất lượng texture của tất cả parts
    for _, obj in ipairs(Config.Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            -- Đơn giản hóa material
            if obj.Material ~= Enum.Material.SmoothPlastic then
                obj.Material = Enum.Material.SmoothPlastic
                count = count + 1
            end
            
            -- Xóa textures
            for _, child in ipairs(obj:GetChildren()) do
                if child:IsA("Decal") or 
                   child:IsA("Texture") or 
                   child:IsA("SurfaceAppearance") then
                    child:Destroy()
                    count = count + 1
                end
            end
        end
        
        -- Xóa MeshPart textures
        if obj:IsA("MeshPart") then
            obj.TextureID = ""
            count = count + 1
        end
    end
    
    print(string.format("[FPS Booster] Reduced %d textures", count))
end

----------------------------------------------------------
-- 🔹 Toggle Functions
function FPS.toggleRemoveEffects(enabled)
    FPS.removeEffectsEnabled = enabled
    
    if enabled then
        FPS.removeEffects()
    else
        FPS.restoreEffects()
    end
end

function FPS.toggleReduceLighting(enabled)
    FPS.reduceLightingEnabled = enabled
    
    if enabled then
        FPS.reduceLighting()
    else
        FPS.restoreLighting()
    end
end

function FPS.toggleReduceTextures(enabled)
    FPS.reduceTextureEnabled = enabled
    
    if enabled then
        FPS.reduceTextures()
    end
end

----------------------------------------------------------
-- 🔹 Remove Weapon Effects
function FPS.removeWeaponEffects()
    if FPS.weaponEffectsConnection then return end
    
    -- Xóa effects hiện tại trong character
    local function cleanCharacterEffects(character)
        if not character then return end
        
        for _, obj in ipairs(character:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or 
               obj:IsA("Trail") or 
               obj:IsA("Beam") or 
               obj:IsA("PointLight") or 
               obj:IsA("SpotLight") then
                
                if obj:IsA("ParticleEmitter") then
                    obj.Enabled = false
                else
                    pcall(function() obj:Destroy() end)
                end
            end
        end
    end
    
    -- Clean character hiện tại
    cleanCharacterEffects(Config.localPlayer.Character)
    
    -- Monitor và xóa effects mới
    FPS.weaponEffectsConnection = Config.RunService.Heartbeat:Connect(function()
        if not FPS.removeWeaponEffectsEnabled then return end
        
        local character = Config.localPlayer.Character
        if not character then return end
        
        -- Xóa effects trong tools/weapons
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") then
                for _, obj in ipairs(tool:GetDescendants()) do
                    if obj:IsA("ParticleEmitter") then
                        obj.Enabled = false
                    elseif obj:IsA("Trail") or obj:IsA("Beam") then
                        pcall(function() obj:Destroy() end)
                    end
                end
            end
        end
    end)
    
    print("[FPS Booster] Weapon effects removal enabled")
end

function FPS.stopRemoveWeaponEffects()
    if FPS.weaponEffectsConnection then
        FPS.weaponEffectsConnection:Disconnect()
        FPS.weaponEffectsConnection = nil
    end
    
    print("[FPS Booster] Weapon effects removal disabled")
end

function FPS.toggleRemoveWeaponEffects(enabled)
    FPS.removeWeaponEffectsEnabled = enabled
    
    if enabled then
        FPS.removeWeaponEffects()
    else
        FPS.stopRemoveWeaponEffects()
    end
end

----------------------------------------------------------
-- 🔹 Remove Projectiles (Đạn bay)
function FPS.removeProjectiles()
    if FPS.projectileConnection then return end
    
    FPS.projectileConnection = Config.RunService.Heartbeat:Connect(function()
        if not FPS.removeProjectilesEnabled then return end
        
        -- Xóa đạn và projectiles trong workspace
        for _, obj in ipairs(Config.Workspace:GetChildren()) do
            local name = obj.Name:lower()
            
            -- Detect projectiles by common names
            if name:find("bullet") or 
               name:find("projectile") or 
               name:find("shot") or 
               name:find("arrow") or
               name:find("rocket") or
               (obj:IsA("BasePart") and obj.Velocity.Magnitude > 100) then
                
                -- Xóa effects của projectile
                for _, child in ipairs(obj:GetDescendants()) do
                    if child:IsA("ParticleEmitter") or 
                       child:IsA("Trail") or 
                       child:IsA("Beam") or
                       child:IsA("PointLight") then
                        
                        if child:IsA("ParticleEmitter") then
                            child.Enabled = false
                        else
                            pcall(function() child:Destroy() end)
                        end
                    end
                end
            end
        end
    end)
    
    print("[FPS Booster] Projectile effects removal enabled")
end

function FPS.stopRemoveProjectiles()
    if FPS.projectileConnection then
        FPS.projectileConnection:Disconnect()
        FPS.projectileConnection = nil
    end
end

function FPS.toggleRemoveProjectiles(enabled)
    FPS.removeProjectilesEnabled = enabled
    
    if enabled then
        FPS.removeProjectiles()
    else
        FPS.stopRemoveProjectiles()
    end
end

----------------------------------------------------------
-- 🔹 Remove Debris (Vỏ đạn, mảnh vỡ)
function FPS.removeDebris()
    if FPS.debrisConnection then return end
    
    FPS.debrisConnection = Config.RunService.Heartbeat:Connect(function()
        if not FPS.removeDebrisEnabled then return end
        
        for _, obj in ipairs(Config.Workspace:GetChildren()) do
            local name = obj.Name:lower()
            
            -- Xóa debris/shells
            if name:find("shell") or 
               name:find("casing") or 
               name:find("debris") or 
               name:find("gibs") or
               name:find("blood") or
               name:find("gore") then
                
                pcall(function() obj:Destroy() end)
            end
        end
    end)
    
    print("[FPS Booster] Debris removal enabled")
end

function FPS.stopRemoveDebris()
    if FPS.debrisConnection then
        FPS.debrisConnection:Disconnect()
        FPS.debrisConnection = nil
    end
end

function FPS.toggleRemoveDebris(enabled)
    FPS.removeDebrisEnabled = enabled
    
    if enabled then
        FPS.removeDebris()
    else
        FPS.stopRemoveDebris()
    end
end

----------------------------------------------------------
-- 🔹 Reduce Sounds
function FPS.reduceSounds()
    if not FPS.reduceSoundsEnabled then return end
    
    local count = 0
    
    -- Giảm volume hoặc tắt sounds
    for _, obj in ipairs(Config.Workspace:GetDescendants()) do
        if obj:IsA("Sound") then
            -- Backup original volume
            if not FPS.originalSoundVolume[obj] then
                FPS.originalSoundVolume[obj] = obj.Volume
            end
            
            -- Giảm volume xuống 20% hoặc tắt hẳn
            obj.Volume = obj.Volume * 0.2
            count = count + 1
        end
    end
    
    print(string.format("[FPS Booster] Reduced %d sounds", count))
end

function FPS.restoreSounds()
    for obj, volume in pairs(FPS.originalSoundVolume) do
        if obj and obj.Parent then
            obj.Volume = volume
        end
    end
    
    FPS.originalSoundVolume = {}
    print("[FPS Booster] Restored sounds")
end

function FPS.toggleReduceSounds(enabled)
    FPS.reduceSoundsEnabled = enabled
    
    if enabled then
        FPS.reduceSounds()
    else
        FPS.restoreSounds()
    end
end

----------------------------------------------------------
-- 🔹 Reduce Animations
function FPS.reduceAnimations()
    if not FPS.reduceAnimationsEnabled then return end
    
    -- Giảm animation priority và speed
    local humanoid = Config.localPlayer.Character and Config.localPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end
    
    -- Giảm tất cả animation tracks
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        track.Priority = Enum.AnimationPriority.Core
        track:AdjustSpeed(1.5) -- Tăng tốc để animation kết thúc nhanh hơn
    end
    
    print("[FPS Booster] Reduced animations")
end

function FPS.toggleReduceAnimations(enabled)
    FPS.reduceAnimationsEnabled = enabled
    
    if enabled then
        FPS.reduceAnimations()
        
        -- Monitor và giảm animations mới
        Config.RunService.Heartbeat:Connect(function()
            if FPS.reduceAnimationsEnabled then
                FPS.reduceAnimations()
            end
        end)
    end
end

----------------------------------------------------------
-- 🔹 FPS Counter
function FPS.startFPSCounter()
    local lastTime = tick()
    local frameCount = 0
    
    Config.RunService.Heartbeat:Connect(function()
        frameCount = frameCount + 1
        local currentTime = tick()
        
        if currentTime - lastTime >= 1 then
            FPS.currentFPS = frameCount
            frameCount = 0
            lastTime = currentTime
        end
    end)
end

function FPS.getFPS()
    return FPS.currentFPS
end

----------------------------------------------------------
-- 🔹 Apply All Optimizations
function FPS.applyAll()
    FPS.toggleRemoveEffects(true)
    FPS.toggleReduceLighting(true)
    FPS.toggleReduceTextures(true)
    FPS.toggleRemoveWeaponEffects(true)
    FPS.toggleRemoveProjectiles(true)
    FPS.toggleRemoveDebris(true)
    FPS.toggleReduceSounds(true)
    FPS.toggleReduceAnimations(true)
    
    print("[FPS Booster] Applied all optimizations")
end

function FPS.disableAll()
    FPS.toggleRemoveEffects(false)
    FPS.toggleReduceLighting(false)
    FPS.toggleRemoveWeaponEffects(false)
    FPS.toggleRemoveProjectiles(false)
    FPS.toggleRemoveDebris(false)
    FPS.toggleReduceSounds(false)
    FPS.toggleReduceAnimations(false)
    
    print("[FPS Booster] Disabled all optimizations")
end

----------------------------------------------------------
-- 🔹 Cleanup
function FPS.cleanup()
    FPS.restoreEffects()
    FPS.restoreLighting()
    FPS.restoreSounds()
    FPS.stopRemoveWeaponEffects()
    FPS.stopRemoveProjectiles()
    FPS.stopRemoveDebris()
end

return FPS
