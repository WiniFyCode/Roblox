--[[
    Movement Module - Zombie Hyperloot
    Speed, NoClip, Camera Teleport, Noclip Cam
]]
-- Luau typechecker in some IDEs doesn't know executor globals
-- Try multiple ways to get executor functions
local function getExecutorFunction(name)
    -- Try from getfenv()
    local env = getfenv()
    if env and env[name] then
        return env[name]
    end
    -- Try from rawget(getfenv())
    local func = rawget(env or {}, name)
    if func then return func end
    -- Try from global (some executors expose directly)
    if _G and _G[name] then
        return _G[name]
    end
    return nil
end

local getgc = getExecutorFunction("getgc")
local debug = getExecutorFunction("debug")
local setconstant = (debug and debug.setconstant) or getExecutorFunction("setconstant")
local getconstants = (debug and debug.getconstants) or getExecutorFunction("getconstants")


local Movement = {}
local Config = nil

-- Connections
Movement.speedConnection = nil
Movement.originalWalkSpeed = nil


function Movement.init(config)
    Config = config
end
-- Runtime lifecycle (moved out of main.lua)
Movement._running = false
Movement._characterAddedConn = nil

function Movement.start()
    if Movement._running then return end
    Movement._running = true

    -- Apply current toggles
    Movement.applyAntiAFK()
    Movement.applySpeed()
    Movement.applyHipHeight()

    if Config.noclipCamEnabled then
        task.defer(Movement.applyNoclipCam)
    end

    -- Input hotkeys (camera teleport + auto rotate toggle)
    Movement.startCameraTeleportInput()

    -- Respawn hook (was in main.lua)
    if not Movement._characterAddedConn then
        Movement._characterAddedConn = Config.localPlayer.CharacterAdded:Connect(function(character)
            Movement.onCharacterAdded(character)
        end)
    end
end

function Movement.stop()
    Movement._running = false

    if Movement._characterAddedConn then
        Movement._characterAddedConn:Disconnect()
        Movement._characterAddedConn = nil
    end

    Movement.stopCameraTeleportInput()

    Movement.stopSpeedBoost()
    Movement.stopAntiAFK()
    Movement.disableHipHeight()

    if Config.noclipCamEnabled then
        Config.noclipCamEnabled = false
        Movement.setNoclipCam(false)
    end
end
-- Camera Teleport lifecycle (moved out of main.lua)
Movement._inputConn = nil
Movement._cameraTeleportThread = nil

function Movement.startCameraTeleportInput()
    if Movement._inputConn then return end

    Movement._inputConn = Config.UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or Config.scriptUnloaded then return end

        -- Auto Rotate Toggle (L key)
        if input.KeyCode == Config.autoRotateToggleKey then
            if not Config.autoRotateEnabled then return end
            Config.autoRotateActive = not (Config.autoRotateActive or false)
            -- Combat module quản lý auto rotate
            local combat = Config.Combat
            if combat and combat.toggleAutoRotate then
                combat.toggleAutoRotate(Config.autoRotateActive)
            end
            return
        end

        -- Camera Teleport (X key)
        if input.KeyCode ~= Config.cameraTeleportKey or not Config.cameraTeleportEnabled then
            return
        end

        if Config.cameraTeleportActive then
            -- Stop
            Config.cameraTeleportActive = false

            if Config.savedAimbotState ~= nil then
                Config.aimbotEnabled = Config.savedAimbotState
            end

            local char = Config.localPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if hrp and Config.cameraTeleportStartPosition then
                hrp.Anchored = false
                
                local targetCFrame = CFrame.new(Config.cameraTeleportStartPosition)
                
                if Config.teleportMode == "Tween" then
                    local TweenService = game:GetService("TweenService")
                    local tweenInfo = TweenInfo.new(Config.teleportTweenSpeed or 1, Enum.EasingStyle.Linear)
                    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
                    tween:Play()
                    tween.Completed:Wait()
                else
                    hrp.CFrame = targetCFrame
                end
            elseif hrp then
                hrp.Anchored = false
            end

            local camera = Config.Workspace.CurrentCamera
            camera.CameraSubject = Config.localPlayer.Character and Config.localPlayer.Character:FindFirstChild("Humanoid")
            return
        end

        -- Start
        Config.savedAimbotState = Config.aimbotEnabled
        Config.aimbotEnabled = false

        local char = Config.localPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            Config.cameraTeleportStartPosition = hrp.Position
        end

        Config.cameraTeleportActive = true

        if Movement._cameraTeleportThread then return end
        Movement._cameraTeleportThread = task.spawn(function()
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

            local currentTarget = Movement.selectInitialTarget() or waitForNewWaveAndSelect()
            if not currentTarget then
                Config.cameraTeleportActive = false
                Movement._cameraTeleportThread = nil
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
                            checkCount += 1
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

            -- Restore HRP
            local endChar = Config.localPlayer.Character
            local endHrp = endChar and endChar:FindFirstChild("HumanoidRootPart")
            if endHrp then
                endHrp.Anchored = false
                if Config.teleportToLastZombie and lastZombiePosition then
                    local targetCFrame = CFrame.new(lastZombiePosition + Vector3.new(0, 5, 0))
                    if Config.teleportMode == "Tween" then
                        local TweenService = game:GetService("TweenService")
                        local tweenInfo = TweenInfo.new(Config.teleportTweenSpeed or 2, Enum.EasingStyle.Linear)
                        local tween = TweenService:Create(endHrp, tweenInfo, {CFrame = targetCFrame})
                        tween:Play()
                        tween.Completed:Wait()
                    else
                        endHrp.CFrame = targetCFrame
                    end
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
            Movement._cameraTeleportThread = nil
        end)
    end)
end

function Movement.stopCameraTeleportInput()
    if Movement._inputConn then
        Movement._inputConn:Disconnect()
        Movement._inputConn = nil
    end
    Config.cameraTeleportActive = false
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
    -- Re-check functions when called (they might be loaded after script init)
    local currentGetgc = getExecutorFunction("getgc")
    local currentDebug = getExecutorFunction("debug")
    local currentSetconstant = (currentDebug and currentDebug.setconstant) or getExecutorFunction("setconstant")
    local currentGetconstants = (currentDebug and currentDebug.getconstants) or getExecutorFunction("getconstants")
    
    if not currentSetconstant or not currentGetgc or not currentGetconstants then
        warn("Exploit không hỗ trợ Noclip Cam (thiếu setconstant hoặc getconstants)")
        return false
    end
    
    local sc = currentSetconstant
    local gc = currentGetconstants

    local success = false
    local pop = Config.localPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"):WaitForChild("CameraModule"):WaitForChild("ZoomController"):WaitForChild("Popper")

    -- enabled = true → set 0 (noclip cam bật)
    -- enabled = false → set 0.25 (noclip cam tắt, camera bình thường)
    local targetValue = enabled and 0 or 0.25

    for _, v in pairs(currentGetgc()) do
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

function Movement.applyHipHeight()
    if Config.hipHeightEnabled then
        Movement.enableHipHeight(Config.hipHeight)
    else
        Movement.disableHipHeight()
    end
end

----------------------------------------------------------
-- 🔹 Cleanup
function Movement.cleanup()
    Movement.stopSpeedBoost()
    Movement.stopAntiAFK()
    Movement.disableHipHeight()

    if Config.noclipCamEnabled then
        Config.noclipCamEnabled = false
        Movement.setNoclipCam(false)
    end
end

return Movement
