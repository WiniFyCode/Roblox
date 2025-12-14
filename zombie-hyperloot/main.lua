--[[
    Zombie Hyperloot - Main Entry Point
    by WiniFy
    
    Modular version - Load từng modules để giảm lag
]]

----------------------------------------------------------
-- 🔹 Loading Screen UI
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

----------------------------------------------------------
-- 🔹 Get Last Commit Time from GitHub
local function getLastCommitTime()
    local defaultTime = "2025-12-14 08:50"
    
    local success, result = pcall(function()
        -- GitHub API endpoint để lấy commit cuối cùng của toàn bộ folder zombie-hyperloot
        -- (không phải chỉ file main.lua, mà là bất kỳ file nào trong folder)
        -- Tương đương với: https://github.com/WiniFyCode/Roblox/commits/main/zombie-hyperloot
        local url = "https://api.github.com/repos/WiniFyCode/Roblox/commits?path=zombie-hyperloot&per_page=1"
        local response = game:HttpGet(url, true)
        local data = HttpService:JSONDecode(response)
        
        if data and data[1] and data[1].commit and data[1].commit.author and data[1].commit.author.date then
            local commitDate = data[1].commit.author.date
            -- Format: "2025-12-14T03:19:00Z" (UTC) -> "2025-12-14 10:19" (UTC+7)
            local year, month, day, hour, minute = string.match(commitDate, "(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d)")
            if year and month and day and hour and minute then
                -- Convert UTC to UTC+7 (Vietnam timezone)
                local hourNum = tonumber(hour)
                local minuteNum = tonumber(minute)
                hourNum = hourNum + 7
                
                -- Handle day overflow
                local dayNum = tonumber(day)
                if hourNum >= 24 then
                    hourNum = hourNum - 24
                    dayNum = dayNum + 1
                    -- Simple day increment (không xử lý month/year overflow vì ít khi xảy ra)
                end
                
                local formattedHour = string.format("%02d", hourNum)
                local formattedMinute = string.format("%02d", minuteNum)
                local formattedDay = string.format("%02d", dayNum)
                return string.format("%s-%s-%s %s:%s", year, month, formattedDay, formattedHour, formattedMinute)
            end
        end
        return nil
    end)
    
    if success and result and result ~= "" then
        return result
    end
    
    -- Fallback về default time nếu API fail
    return defaultTime
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ZombieHyperlootLoader"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 400, 0, 150)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -75)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -40, 0, 40)
title.Position = UDim2.new(0, 20, 0, 15)
title.BackgroundTransparency = 1
title.Text = "Zombie Hyperloot"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 24
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = mainFrame

-- Subtitle
local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.Size = UDim2.new(1, -40, 0, 20)
subtitle.Position = UDim2.new(0, 20, 0, 50)
subtitle.BackgroundTransparency = 1
subtitle.Text = "by WiniFy - Last update: " .. getLastCommitTime()
subtitle.TextColor3 = Color3.fromRGB(150, 150, 150)
subtitle.TextSize = 18
subtitle.Font = Enum.Font.Gotham
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = mainFrame

-- Progress Bar Background
local progressBg = Instance.new("Frame")
progressBg.Name = "ProgressBg"
progressBg.Size = UDim2.new(1, -40, 0, 8)
progressBg.Position = UDim2.new(0, 20, 0, 85)
progressBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
progressBg.BorderSizePixel = 0
progressBg.Parent = mainFrame

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(0, 4)
progressCorner.Parent = progressBg

-- Progress Bar Fill
local progressFill = Instance.new("Frame")
progressFill.Name = "ProgressFill"
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
progressFill.BorderSizePixel = 0
progressFill.Parent = progressBg

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 4)
fillCorner.Parent = progressFill

-- Status Text
local statusText = Instance.new("TextLabel")
statusText.Name = "StatusText"
statusText.Size = UDim2.new(1, -40, 0, 30)
statusText.Position = UDim2.new(0, 20, 0, 105)
statusText.BackgroundTransparency = 1
statusText.Text = "Initializing..."
statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
statusText.TextSize = 13
statusText.Font = Enum.Font.Gotham
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Parent = mainFrame

-- Update Progress Function
local function updateProgress(current, total, text)
    local progress = current / total
    progressFill:TweenSize(
        UDim2.new(progress, 0, 1, 0),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        0.3,
        true
    )
    statusText.Text = string.format("[%d/%d] %s", current, total, text)
end

----------------------------------------------------------
-- 🔹 Load Modules with Progress
local Config, Visuals, Combat, ESP, Movement, Map, Farm, HUD, UI, Character

updateProgress(1, 10, "Loading Config...")
Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/config.lua"))()
task.wait(0.15)

updateProgress(2, 10, "Loading Visuals...")
Visuals = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/visuals.lua"))()
Visuals.init(Config)
task.wait(0.15)

updateProgress(3, 10, "Loading Combat...")
Combat = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/combat.lua"))()
Combat.init(Config, Visuals)
task.wait(0.15)

updateProgress(4, 10, "Loading ESP...")
ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/esp.lua"))()
ESP.init(Config)
task.wait(0.15)

updateProgress(5, 10, "Loading Movement...")
Movement = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/movement.lua"))()
Movement.init(Config)
task.wait(0.15)

updateProgress(6, 10, "Loading Map...")
Map = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/map.lua"))()
Map.init(Config)
task.wait(0.15)

updateProgress(7, 10, "Loading Farm...")
Farm = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/farm.lua"))()
Farm.init(Config, ESP)
task.wait(0.15)

updateProgress(8, 10, "Loading HUD...")
HUD = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/hud.lua"))()
HUD.init(Config)
task.wait(0.15)

updateProgress(9, 10, "Loading Character...")
Character = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/character.lua"))()
Character.init(Config)

updateProgress(10, 10, "Loading UI...")
UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/ui.lua"))()
UI.init(Config, Combat, ESP, Movement, Map, Farm, HUD, Visuals, Character)
task.wait(0.3)

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
    Config.espBobEnabled = false
    Config.autoDoorEnabled = false

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
    HUD.cleanup()
    Visuals.cleanup()
    Character.cleanup()
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

    -- Notify script unload
    if Config.UI and Config.UI.Fluent then
        Config.UI.Fluent:Notify({
            Title = "Zombie Hyperloot",
            Content = "Script unloaded successfully",
            SubContent = "All features disabled and cleaned up",
            Duration = 4
        })
    end
end

----------------------------------------------------------
-- 🔹 Enable MouseLock (Auto-enable on script start)
pcall(function()
    local args = {1469938953, "MouseLock", true}
    game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
end)

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
ESP.startBobESP() -- Start Bob ESP với refresh mỗi 5s



----------------------------------------------------------
-- 🔹 Setup Combat
Combat.initFOVCircle()
Combat.setupMouseInput()
Character.startAllSkillLoops()

----------------------------------------------------------
-- 🔹 Setup Movement
Movement.applyAntiZombie()
if Config.noclipCamEnabled then
    task.defer(Movement.applyNoclipCam)
end

-- Setup Auto Rotate
Combat.setRotationSmoothness(Config.autoRotateSmoothness)

-- Character respawn handler
characterAddedConnection = Config.localPlayer.CharacterAdded:Connect(function(character)
    Movement.onCharacterAdded(character)
    HUD.onCharacterAdded(character)
end)

----------------------------------------------------------
-- 🔹 Setup Farm
Farm.startAutoBulletBoxLoop()
Farm.setupChestTeleportInput()

----------------------------------------------------------
-- 🔹 Setup Map Auto Replay, Supply ESP & Auto Door
Map.startAutoReplayLoop()
Map.startSupplyESP()

-- Start Auto Door nếu được bật
if Config.autoDoorEnabled then
    Map.startAutoDoor()
end

----------------------------------------------------------
-- 🔹 Setup HUD
task.wait(1) -- Đợi HUD load
HUD.backupOriginalValues() -- Backup và set default colors
HUD.applyLobbyPlayerInfoVisibility()
HUD.startExpDisplay() -- Bật EXP display mặc định

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
local highlightUpdateTick = 0
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
    
    -- Update Highlights (every 0.5s to reduce lag)
    highlightUpdateTick = highlightUpdateTick + 1
    if highlightUpdateTick >= 30 then
        highlightUpdateTick = 0
        ESP.updateZombieHighlights()
        ESP.updatePlayerHighlights()
        ESP.updateBobHighlights()
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

        -- Bob ESP (giống ESP Player - chỉ name + distance)
        if Config.espBobEnabled then
            local seenBobs = {}
            local bobs = ESP.findAllBobs()
            for _, bobData in ipairs(bobs) do
                local bobModel = bobData.model
                local hum = bobData.humanoid
                if hum and hum.Health > 0 then
                    local ok, cf, size = pcall(bobModel.GetBoundingBox, bobModel)
                    if ok and cf and size then
                        ESP.drawBobESP(bobModel, cf, size, hum)
                        seenBobs[bobModel] = true
                    else
                        ESP.hideBobESP(ESP.bobESPObjects[bobModel])
                    end
                else
                    ESP.hideBobESP(ESP.bobESPObjects[bobModel])
                end
            end
            for model, data in pairs(ESP.bobESPObjects) do
                if not seenBobs[model] then
                    ESP.hideBobESP(data)
                end
            end
        else
            for _, data in pairs(ESP.bobESPObjects) do
                ESP.hideBobESP(data)
            end
        end
    end
    
    -- Aimbot
    local shouldAutoFire = false

    if Config.aimbotEnabled then
        local active = true
        if Config.aimbotHoldMouse2 and not Combat.holdingMouse2 then
            active = false
        end
        
        if active then
            local char, part = Combat.getClosestAimbotTarget()
            if char and part then
                shouldAutoFire = true
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

    if Combat.setAutoFireActive then
        Combat.setAutoFireActive(shouldAutoFire)
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
    
    -- Auto Rotate Toggle (R key)
    if input.KeyCode == Config.autoRotateToggleKey then
        Config.autoRotateEnabled = not Config.autoRotateEnabled
        Combat.toggleAutoRotate(Config.autoRotateEnabled)
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
statusText.Text = "Finalizing..."
UI.loadLibraries()
UI.createWindow()
UI.buildAllTabs(cleanupScript)

-- Success message
statusText.Text = "✓ Loaded successfully!"
statusText.TextColor3 = Color3.fromRGB(100, 255, 100)
progressFill.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
task.wait(1)

-- Fade out loading screen
for i = 0, 1, 0.1 do
    mainFrame.BackgroundTransparency = i
    title.TextTransparency = i
    subtitle.TextTransparency = i
    progressBg.BackgroundTransparency = i
    progressFill.BackgroundTransparency = i
    statusText.TextTransparency = i
    task.wait(0.05)
end

screenGui:Destroy()

-- Success notification
if Config.UI and Config.UI.Fluent then
    Config.UI.Fluent:Notify({
        Title = "Zombie Hyperloot",
        Content = "Script loaded successfully!",
        SubContent = "Press Right Ctrl to open menu | R key for Auto Rotate",
        Duration = 6
    })
end

print("[ZombieHyperloot] Script loaded successfully!")
print("[ZombieHyperloot] Press Right Ctrl to open menu")
