--[[
    Zombie Hyperloot - Main Entry Point
    by WiniFy
    
    Modular version - Load tất cả modules
]]

-- Load Modules
local Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/config.lua"))()
local Combat = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/combat.lua"))()
local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/esp.lua"))()
local Movement = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/movement.lua"))()
local Map = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/map.lua"))()
local Farm = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/farm.lua"))()
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/ui.lua"))()

-- Initialize Modules
Combat.init(Config)
ESP.init(Config)
Movement.init(Config)
Map.init(Config)
Farm.init(Config, ESP)
UI.init(Config, Combat, ESP, Movement, Map, Farm)

----------------------------------------------------------
-- 🔹 Cleanup Function
local renderSteppedConnection = nil
local entityChildAddedConnection = nil
local entityChildRemovedConnection = nil
local inputBeganConnection = nil
local characterAddedConnection = nil

local function cleanupScript()
    if Config.scriptUnloaded then return end
    Config.scriptUnloaded = true

    -- Tắt các toggle chính
    Config.aimbotEnabled = false
    Config.espPlayerEnabled = false
    Config.espZombieEnabled = false
    Config.espChestEnabled = false
    Config.hitboxEnabled = false
    Config.teleportEnabled = false
    Config.cameraTeleportEnabled = false
    Config.cameraTeleportActive = false
    Config.autoBulletBoxEnabled = false
    Config.autoSkillEnabled = false
    Config.noClipEnabled = false
    Config.speedEnabled = false
    Config.antiZombieEnabled = false
    Config.supplyESPEnabled = false

    -- Disconnect all connections
    if renderSteppedConnection then
        renderSteppedConnection:Disconnect()
        renderSteppedConnection = nil
    end
    if entityChildAddedConnection then
        entityChildAddedConnection:Disconnect()
        entityChildAddedConnection = nil
    end
    if entityChildRemovedConnection then
        entityChildRemovedConnection:Disconnect()
        entityChildRemovedConnection = nil
    end
    if inputBeganConnection then
        inputBeganConnection:Disconnect()
        inputBeganConnection = nil
    end
    if characterAddedConnection then
        characterAddedConnection:Disconnect()
        characterAddedConnection = nil
    end

    -- Cleanup modules
    Combat.cleanup()
    ESP.cleanup()
    Movement.cleanup()
    Map.cleanup()
    UI.cleanup()

    -- Khôi phục hitbox
    for _, zombie in ipairs(Config.entityFolder:GetChildren()) do
        Combat.restoreHitbox(zombie)
    end

    -- Reset camera và nhân vật
    local char = Config.localPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.Anchored = false end

    local camera = Config.Workspace.CurrentCamera
    if camera and char then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            camera.CameraSubject = humanoid
            camera.CameraType = Enum.CameraType.Custom
        end
    end

    print("[ZombieHyperloot] Script unloaded!")
end

----------------------------------------------------------
-- 🔹 Setup TrigerSkill Dupe
Combat.setupTrigerSkillDupe()

----------------------------------------------------------
-- 🔹 Setup ESP
ESP.initializePlayerESP()
ESP.watchChestDescendants()
if Config.espChestEnabled then
    ESP.applyChestESP()
end

----------------------------------------------------------
-- 🔹 Setup Combat
Combat.initFOVCircle()
Combat.setupMouseInput()
Combat.startAllSkillLoops()

----------------------------------------------------------
-- 🔹 Setup Movement
Movement.applyAntiZombie()
if Config.noclipCamEnabled then
    task.defer(Movement.applyNoclipCam)
end

-- Character respawn handler
characterAddedConnection = Config.localPlayer.CharacterAdded:Connect(Movement.onCharacterAdded)

----------------------------------------------------------
-- 🔹 Setup Farm
Farm.startAutoBulletBoxLoop()
Farm.setupChestTeleportInput()

----------------------------------------------------------
-- 🔹 Setup Map Auto Replay & Supply ESP
Map.startAutoReplayLoop()
Map.startSupplyESP()

----------------------------------------------------------
-- 🔹 Entity Folder Listeners (Hitbox)
entityChildAddedConnection = Config.entityFolder.ChildAdded:Connect(function(zombie)
    if zombie:IsA("Model") then
        local head = zombie:WaitForChild("Head", 3)
        if head then
            task.wait(0.5)
            if Config.hitboxEnabled then
                Combat.expandHitbox(zombie)
            end
        end
    end
end)

entityChildRemovedConnection = Config.entityFolder.ChildRemoved:Connect(function(zombie)
    Combat.processedZombies[zombie] = nil
    local highlight = zombie:FindFirstChild("ESP_Highlight")
    if highlight then highlight:Destroy() end
end)

----------------------------------------------------------
-- 🔹 Main Render Loop (Aimbot + ESP)
renderSteppedConnection = Config.RunService.RenderStepped:Connect(function()
    if Config.scriptUnloaded then return end

    local mousePos = Config.UserInputService:GetMouseLocation()
    
    -- Update FOV Circle
    if Combat.FOVCircle then
        Combat.FOVCircle.Position = mousePos
        Combat.FOVCircle.Radius = Config.aimbotFOVRadius
        Combat.FOVCircle.Visible = Config.aimbotEnabled and Config.aimbotFOVEnabled
        Combat.FOVCircle.Color = Config.aimbotEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 255)
        Combat.FOVCircle.Thickness = Config.aimbotEnabled and 2 or 1.5
    end
    
    -- ESP Update Loop
    if ESP.hasPlayerDrawing then
        -- Player ESP
        if Config.espPlayerEnabled then
            for _, plr in ipairs(Config.Players:GetPlayers()) do
                if plr ~= Config.localPlayer then
                    local char = plr.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if char and hum and hum.Health > 0 then
                        if Config.espPlayerTeamCheck and plr.Team == Config.localPlayer.Team then
                            ESP.hidePlayerESP(ESP.playerESPObjects[plr])
                        else
                            local ok, cf, size = pcall(char.GetBoundingBox, char)
                            if ok and cf and size then
                                ESP.drawPlayerESP(plr, cf, size, hum)
                            else
                                ESP.hidePlayerESP(ESP.playerESPObjects[plr])
                            end
                        end
                    else
                        ESP.hidePlayerESP(ESP.playerESPObjects[plr])
                    end
                end
            end
        else
            for _, data in pairs(ESP.playerESPObjects) do
                ESP.hidePlayerESP(data)
            end
        end

        -- Zombie ESP
        if Config.espZombieEnabled then
            local seenZombies = {}
            for _, zombie in ipairs(Config.entityFolder:GetChildren()) do
                if zombie:IsA("Model") then
                    local hum = zombie:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local ok, cf, size = pcall(zombie.GetBoundingBox, zombie)
                        if ok and cf and size then
                            ESP.drawZombieESP(zombie, cf, size, hum)
                            seenZombies[zombie] = true
                        else
                            ESP.hideZombieESP(ESP.zombieESPObjects[zombie])
                        end
                    else
                        ESP.hideZombieESP(ESP.zombieESPObjects[zombie])
                    end
                end
            end
            for model, data in pairs(ESP.zombieESPObjects) do
                if not seenZombies[model] then
                    ESP.hideZombieESP(data)
                end
            end
        else
            for _, data in pairs(ESP.zombieESPObjects) do
                ESP.hideZombieESP(data)
            end
        end
    end
    
    -- Aimbot
    if Config.aimbotEnabled then
        local active = true
        if Config.aimbotHoldMouse2 and not Combat.holdingMouse2 then
            active = false
        end
        
        if active then
            local char, part = Combat.getClosestAimbotTarget()
            if char and part then
                local targetPos = part.Position
                if Config.aimbotPrediction > 0 then
                    local vel = part.AssemblyLinearVelocity or part.Velocity or Vector3.new(0, 0, 0)
                    targetPos = targetPos + (vel * Config.aimbotPrediction)
                end
                
                local camera = Config.Workspace.CurrentCamera
                local cf = camera.CFrame
                local desired = CFrame.new(cf.Position, targetPos)
                
                -- Smoothness: 0 = instant, higher = smoother/slower
                if Config.aimbotSmoothness > 0 then
                    local alpha = 1 - Config.aimbotSmoothness
                    alpha = math.clamp(alpha, 0.01, 1)
                    camera.CFrame = cf:Lerp(desired, alpha)
                else
                    camera.CFrame = desired
                end
                
                if Combat.FOVCircle then
                    Combat.FOVCircle.Color = Color3.fromRGB(255, 0, 0)
                    Combat.FOVCircle.Thickness = 2.5
                end
            else
                if Combat.FOVCircle then
                    Combat.FOVCircle.Color = Color3.fromRGB(0, 255, 0)
                    Combat.FOVCircle.Thickness = 2
                end
            end
        end
    end
end)


----------------------------------------------------------
-- 🔹 Camera Teleport Input Handler
inputBeganConnection = Config.UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or Config.scriptUnloaded then return end
    
    -- HipHeight Toggle (M key)
    if input.KeyCode == Config.hipHeightToggleKey then
        Config.antiZombieEnabled = not Config.antiZombieEnabled
        Movement.applyAntiZombie()
    end
    
    -- Camera Teleport (X key)
    if input.KeyCode == Config.cameraTeleportKey and Config.cameraTeleportEnabled then
        if Config.cameraTeleportActive then
            Config.cameraTeleportActive = false
            
            if Config.savedAimbotState ~= nil then
                Config.aimbotEnabled = Config.savedAimbotState
            end
            
            local char = Config.localPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and Config.cameraTeleportStartPosition then
                hrp.Anchored = false
                hrp.CFrame = CFrame.new(Config.cameraTeleportStartPosition)
            elseif hrp then
                hrp.Anchored = false
            end
            
            local camera = Config.Workspace.CurrentCamera
            camera.CameraSubject = Config.localPlayer.Character and Config.localPlayer.Character:FindFirstChild("Humanoid")
            return
        end
        
        Config.savedAimbotState = Config.aimbotEnabled
        Config.aimbotEnabled = false
        
        local char = Config.localPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            Config.cameraTeleportStartPosition = hrp.Position
        end
        
        Config.cameraTeleportActive = true
        
        task.spawn(function()
            local function waitForNewWaveAndSelect()
                if Config.cameraTeleportWaveDelay <= 0 then
                    return Movement.selectInitialTarget()
                end

                local waited = 0
                while Config.cameraTeleportActive and waited < Config.cameraTeleportWaveDelay do
                    local candidate = Movement.selectInitialTarget()
                    if candidate then return candidate end
                    local step = math.min(0.25, Config.cameraTeleportWaveDelay - waited)
                    task.wait(step)
                    waited = waited + step
                end

                if not Config.cameraTeleportActive then return nil end
                return Movement.selectInitialTarget()
            end

            local camera = Config.Workspace.CurrentCamera
            local char = Config.localPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            local currentTarget = Movement.selectInitialTarget()
            if not currentTarget then
                currentTarget = waitForNewWaveAndSelect()
            end
            if not currentTarget then
                Config.cameraTeleportActive = false
                return
            end
            
            local lastZombiePosition = nil
            
            while Config.cameraTeleportActive and currentTarget do
                currentTarget = Movement.selectNextTarget(currentTarget)
                if Config.cameraTeleportActive and not currentTarget then
                    currentTarget = waitForNewWaveAndSelect()
                    if not currentTarget then break end
                end
                
                if currentTarget and currentTarget.zombie then
                    local humanoid = currentTarget.zombie:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health > 0 and humanoid.Parent then
                        local targetPosition = currentTarget.part.Position
                        lastZombiePosition = targetPosition
                        
                        camera.CameraSubject = humanoid
                        camera.CameraType = Enum.CameraType.Custom
                        local cameraOffset = Vector3.new(Config.cameraOffsetX, Config.cameraOffsetY, Config.cameraOffsetZ)
                        camera.CFrame = CFrame.lookAt(targetPosition + cameraOffset, targetPosition)
                        
                        local checkCount = 0
                        repeat
                            task.wait(0.1)
                            checkCount = checkCount + 1
                            if not Config.cameraTeleportActive then break end
                            if not humanoid or humanoid.Parent == nil or humanoid.Health <= 0 then break end
                            local lowerMaxZombie = Movement.findLowestMaxHealthZombie(currentTarget.zombie)
                            if lowerMaxZombie then break end
                            if checkCount > 300 then break end
                        until false
                    else
                        task.wait(0.2)
                    end
                else
                    task.wait(0.5)
                end
            end
            
            if hrp then
                hrp.Anchored = false
                if Config.teleportToLastZombie and lastZombiePosition then
                    hrp.CFrame = CFrame.new(lastZombiePosition + Vector3.new(0, 5, 0))
                end
            end
            
            if Config.savedAimbotState ~= nil then
                Config.aimbotEnabled = Config.savedAimbotState
            end
            
            local finalChar = Config.localPlayer.Character
            if finalChar then
                local finalHumanoid = finalChar:FindFirstChild("Humanoid")
                if finalHumanoid then
                    camera.CameraSubject = finalHumanoid
                end
            end
            
            Config.cameraTeleportActive = false
        end)
    end
    
    -- End key - Cleanup
    if input.KeyCode == Enum.KeyCode.End then
        cleanupScript()
    end
end)

----------------------------------------------------------
-- 🔹 Load UI
UI.loadLibraries()
UI.createWindow()
UI.buildAllTabs(cleanupScript)

print("[ZombieHyperloot] Script loaded successfully!")
print("[ZombieHyperloot] Press Right Shift to open menu")
