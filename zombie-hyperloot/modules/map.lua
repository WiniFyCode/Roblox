--[[
    Map Module - Zombie Hyperloot
    Map Teleport, Start, Replay, Supply ESP
]]

-- Luau typechecker in some IDEs doesn't know executor globals
local _fireproximityprompt = rawget(getfenv(), "fireproximityprompt")
local _firetouchinterest = rawget(getfenv(), "firetouchinterest")
local _firetouchtransmitter = rawget(getfenv(), "firetouchtransmitter")

local Map = {}
local Config = nil

-- Supply ESP tracking
Map.supplyItems = {}
Map.supplyScreenGui = nil
Map.supplyFrame = nil
Map.supplyButtons = {}
Map.refreshConnection = nil

-- Extra buttons & cached prompts
Map.taskButton = nil
Map.carButton = nil
Map.cachedCarPrompt = nil
Map.cachedTaskPrompt = nil


-- Extra buttons & cached prompts
Map.taskButton = nil
Map.carButton = nil
Map.cachedCarPrompt = nil
Map.cachedTaskPrompt = nil


-- Auto Door tracking
Map.autoDoorEnabled = false
Map.doorConnection = nil
Map.lastDoorCheck = 0

-- Helper Functions
local function getPromptWorldPosition(prompt)
    if not prompt then return nil end
    local parent = prompt.Parent

    -- Trường hợp phổ biến: ProximityPrompt nằm trong Attachment gắn vào Part
    if parent and parent:IsA("Attachment") then
        local parentPart = parent.Parent
        if parentPart and parentPart:IsA("BasePart") then
            return parentPart.Position
        end
    end

    if parent then
        -- Nhiều map để Prompt trực tiếp dưới Part
        if parent:IsA("BasePart") then
            return parent.Position
        end

        -- Trường hợp như hình bạn gửi: Task/Car là folder/model, part thật nằm dưới (vd: default)
        local part = parent:FindFirstChildWhichIsA("BasePart", true)
        if part then
            return part.Position
        end
    end

    -- Một số Prompt có thuộc tính Adornee, nhưng không phải cái nào cũng có
    local ok, adornee = pcall(function()
        return prompt.Adornee
    end)
    if ok and adornee and adornee:IsA("BasePart") then
        return adornee.Position
    end

    return nil
end

local function firePromptOnce(prompt)
    if prompt and typeof(fireproximityprompt) == "function" then
        task.delay(0.25, function()
            pcall(function()
                if prompt and prompt.Enabled then
                    fireproximityprompt(prompt)
                end
            end)
        end)
    end
end

local function findCarPrompt()
    if Map.cachedCarPrompt and Map.cachedCarPrompt.Parent then
        return Map.cachedCarPrompt
    end

    local map = Config.Workspace:FindFirstChild("Map")
    if not map then return nil end

    -- Tìm bất kỳ ProximityPrompt nào có parent tên "Car" dưới Map
    for _, inst in ipairs(map:GetDescendants()) do
        if inst:IsA("ProximityPrompt") then
            local parent = inst.Parent
            if parent and parent.Name == "Car" then
                Map.cachedCarPrompt = inst
                return inst
            end
        end
    end

    return nil
end

local function findCarPart()
    local map = Config.Workspace:FindFirstChild("Map")
    if not map then return nil end

    for _, inst in ipairs(map:GetDescendants()) do
        if inst:IsA("BasePart") and inst.Name == "Car" then
            return inst
        end
    end

    return nil
end

local function findTaskPrompt()
    if Map.cachedTaskPrompt and Map.cachedTaskPrompt.Parent then
        return Map.cachedTaskPrompt
    end

    local map = Config.Workspace:FindFirstChild("Map")
    if not map then return nil end

    -- Tìm bất kỳ ProximityPrompt nào có parent tên "Task" dưới Map
    for _, inst in ipairs(map:GetDescendants()) do
        if inst:IsA("ProximityPrompt") then
            local parent = inst.Parent
            if parent and parent.Name == "Task" then
                Map.cachedTaskPrompt = inst
                return inst
            end
        end
    end

    return nil
end

local function findTaskPart()
    local map = Config.Workspace:FindFirstChild("Map")
    if not map then return nil end

    for _, inst in ipairs(map:GetDescendants()) do
        if inst:IsA("BasePart") and inst.Name == "Task" then
            return inst
        end
    end

    return nil
end


function Map.init(config)
    Config = config
end
-- Runtime lifecycle (moved out of main.lua)
Map._running = false

function Map.start()
    if Map._running then return end
    Map._running = true

    if Config.supplyESPEnabled then
        Map.startSupplyESP()
    end

    if Config.autoDoorEnabled then
        Map.startAutoDoor()
    end
end

function Map.stop()
    Map._running = false
    Map.stopSupplyESP()
    Map.stopAutoDoor()
end

----------------------------------------------------------
-- 🔹 Map Teleport & Start
function Map.getWaitAreaTouchPart()
    local ok, result = pcall(function()
        local eItem = Config.Workspace:FindFirstChild("EItem")
        if not eItem then return nil end
        local waitArea = eItem:FindFirstChild("WaitArea")
        if not waitArea then return nil end
        local waitArea4= waitArea:FindFirstChild("WaitArea4")
        if not waitArea4 then return nil end
        return waitArea4:FindFirstChild("TouchPart")
    end)

    if ok then return result end
    return nil
end

function Map.teleportToWaitAreaAndStart()
    if Config.scriptUnloaded then return end

    local char = Config.localPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hrp then
        warn("[MapTeleport] Could not find character or HumanoidRootPart")
        return
    end

    local touchPart = Map.getWaitAreaTouchPart()
    if not touchPart or not touchPart:IsA("BasePart") then
        warn("[MapTeleport] Không tìm thấy WaitArea TouchPart")
        return
    end

    local targetCFrame = touchPart.CFrame + Vector3.new(0, 4, 0)
    
    if Config.teleportMode == "Tween" then
        local TweenService = game:GetService("TweenService")
        local tweenInfo = TweenInfo.new(Config.teleportTweenSpeed or 2, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
        tween:Play()
        tween.Completed:Wait()
    else
        hrp.CFrame = targetCFrame
    end
    
    task.wait(0.5)

    local replicatedStorage = game:GetService("ReplicatedStorage")
    local remoteFolder = replicatedStorage:FindFirstChild("Remote")
    if not remoteFolder then
        warn("[MapTeleport] Không tìm thấy ReplicatedStorage.Remote")
        return
    end

    local remoteEvent = remoteFolder:FindFirstChild("RemoteEvent")
    if not remoteEvent then
        warn("[MapTeleport] Không tìm thấy RemoteEvent")
        return
    end

    local difficultyToSend = Config.selectedDifficulty
    if Config.selectedWorldId == 102 or Config.selectedWorldId == 201 then
        difficultyToSend = 1
    end

    local args = {
        1604900034,
        {
            difficulty = difficultyToSend,
            worldId = Config.selectedWorldId,
            maxCount = Config.selectedMaxCount,
            friendOnly = Config.selectedFriendOnly
        }
    }

    pcall(function()
        remoteEvent:FireServer(unpack(args))
    end)
end

function Map.replayCurrentMatch()
    if Config.scriptUnloaded then return end

    local replicatedStorage = game:GetService("ReplicatedStorage")
    local remoteFolder = replicatedStorage:FindFirstChild("Remote")
    if not remoteFolder then
        warn("[ReplayMatch] Could not find ReplicatedStorage.Remote")
        return
    end

    local remoteEvent = remoteFolder:FindFirstChild("RemoteEvent")
    if not remoteEvent then
        warn("[ReplayMatch] Không tìm thấy RemoteEvent")
        return
    end

    pcall(function()
        remoteEvent:FireServer(3463932402)
    end)
end

-- Teleport tới game chính (hub)
function Map.teleportToMainGame()
    if Config.scriptUnloaded then return end

    local TeleportService = game:GetService("TeleportService")
    local mainPlaceId = 100822312246972

    local ok, err = pcall(function()
        TeleportService:Teleport(mainPlaceId, Config.localPlayer)
    end)

    if not ok then
        warn("[MapTeleport] Failed to teleport to main game:", err)
    end
end


----------------------------------------------------------
-- 🔹 Supply ESP Functions
function Map.findAllSupplies()
    local supplies = {}

    local map = Config.Workspace:FindFirstChild("Map")
    if not map then return supplies end

    -- Duyệt qua tất cả children của Map
    for _, mapChild in ipairs(map:GetChildren()) do
        local eItem = mapChild:FindFirstChild("EItem")
        if eItem then
            -- Duyệt qua tất cả children của EItem (có thể là "3", "4", v.v.)
            for _, eItemChild in ipairs(eItem:GetChildren()) do
                -- Tìm SM_Prop_SupplyPile trong child này
                for _, descendant in ipairs(eItemChild:GetDescendants()) do
                    if descendant:IsA("BasePart") and string.match(descendant.Name, "SM_Prop_SupplyPile") then
                        table.insert(supplies, {
                            part = descendant,
                            name = descendant.Name,
                            position = descendant.Position
                        })
                        break -- Chỉ lấy 1 part từ mỗi supply pile
                    end
                end
            end
        end
    end

    return supplies
end

function Map.teleportToSupply(supplyData)
    local char = Config.localPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        warn("[Supply] Could not find HumanoidRootPart")
        return
    end

    if not supplyData or not supplyData.position then
        warn("[Supply] supplyData không hợp lệ")
        return
    end

    local targetPos = supplyData.position

    if Config.teleportMode == "Tween" then
        local TweenService = game:GetService("TweenService")
        local tweenInfo = TweenInfo.new(Config.teleportTweenSpeed or 2, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(targetPos + Vector3.new(0, 5, 0))})
        tween:Play()
        tween.Completed:Wait()
    else
        hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 5, 0))
    end
end

function Map.teleportToTask()
    if Config.scriptUnloaded then return end
    
    -- Find Task Prompt
    local prompt = Map.cachedTaskPrompt
    if not prompt or not prompt.Parent then
        local map = Config.Workspace:FindFirstChild("Map")
        if map then
            for _, inst in ipairs(map:GetDescendants()) do
                if inst:IsA("ProximityPrompt") then
                    local parent = inst.Parent
                    if parent and parent.Name == "Task" then
                        prompt = inst
                        Map.cachedTaskPrompt = inst
                        break
                    end
                end
            end
        end
    end
    
    if not prompt then
        warn("[MapTeleport] Không tìm thấy Task Prompt")
        return
    end
    
    local targetPos = getPromptWorldPosition(prompt)
    if not targetPos then
        warn("[MapTeleport] Không xác định được vị trí Task")
        return
    end
    
    local char = Config.localPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local targetCFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
    
    if Config.teleportMode == "Tween" then
        local TweenService = game:GetService("TweenService")
        local tweenInfo = TweenInfo.new(Config.teleportTweenSpeed or 2, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
        tween:Play()
        tween.Completed:Wait()
    else
        hrp.CFrame = targetCFrame
    end
    
    firePromptOnce(prompt)
end

function Map.teleportToCar()
    if Config.scriptUnloaded then return end
    
    local prompt = findCarPrompt()
    if not prompt then
        warn("[MapTeleport] Không tìm thấy Car Prompt")
        return
    end
    
    local targetPos = getPromptWorldPosition(prompt)
    if not targetPos then
        warn("[MapTeleport] Không xác định được vị trí Car")
        return
    end
    
    local char = Config.localPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local targetCFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
    
    if Config.teleportMode == "Tween" then
        local TweenService = game:GetService("TweenService")
        local tweenInfo = TweenInfo.new(Config.teleportTweenSpeed or 2, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
        tween:Play()
        tween.Completed:Wait()
    else
        hrp.CFrame = targetCFrame
    end
    
    firePromptOnce(prompt)
end

-- Helpers moved to top
function Map.createSupplyUI()
    -- Xóa UI cũ nếu có
    if Map.supplyScreenGui then
        Map.supplyScreenGui:Destroy()
        Map.supplyScreenGui = nil
    end

    -- Tạo ScreenGui
    Map.supplyScreenGui = Instance.new("ScreenGui")
    Map.supplyScreenGui.Name = "SupplyESP"
    Map.supplyScreenGui.ResetOnSpawn = false
    Map.supplyScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Tạo Frame chứa (không có title, không scroll)
    Map.supplyFrame = Instance.new("Frame")
    Map.supplyFrame.Name = "SupplyFrame"
    Map.supplyFrame.Size = UDim2.new(0, 140, 0, 100) -- Sẽ tự động resize theo số lượng
    Map.supplyFrame.BackgroundTransparency = 1 -- Trong suốt hoàn toàn
    Map.supplyFrame.BorderSizePixel = 0
    Map.supplyFrame.Parent = Map.supplyScreenGui

    -- UIListLayout để tự động sắp xếp buttons
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = Map.supplyFrame

    -- Tạo nút Task
    do
        local button = Instance.new("TextButton")
        button.Name = "TaskButton"
        button.Size = UDim2.new(0, 110, 0, 30)
        button.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        button.BackgroundTransparency = 0.05
        button.BorderSizePixel = 0
        button.Font = Enum.Font.GothamSemibold
        button.TextSize = 13
        button.TextColor3 = Color3.fromRGB(200, 200, 200)
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.Text = "Task"
        button.AutoButtonColor = false
        button.Visible = false
        button.Parent = Map.supplyFrame


        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 4)
        buttonCorner.Parent = button

        local buttonStroke = Instance.new("UIStroke")
        buttonStroke.Color = Color3.fromRGB(40, 40, 40)
        buttonStroke.Thickness = 1
        buttonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        buttonStroke.Parent = button

        local accentBar = Instance.new("Frame")
        accentBar.Name = "Accent"
        accentBar.Size = UDim2.new(1, 0, 0, 2)
        accentBar.Position = UDim2.new(0, 0, 1, -2)
        accentBar.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
        accentBar.BorderSizePixel = 0
        accentBar.Parent = button

        local accentCorner = Instance.new("UICorner")
        accentCorner.CornerRadius = UDim.new(0, 4)
        accentCorner.Parent = accentBar

        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 10)
        padding.PaddingRight = UDim.new(0, 10)
        padding.PaddingBottom = UDim.new(0, 2)
        padding.Parent = button

        button.MouseButton1Click:Connect(function()
            local prompt = findTaskPrompt()
            local worldPos = nil

            if prompt then
                worldPos = getPromptWorldPosition(prompt)
            end

            -- Fallback: nếu không có prompt thì teleport tới part "Task"
            if not worldPos then
                local taskPart = findTaskPart()
                if taskPart then
                    worldPos = taskPart.Position
                end
            end

            local char = Config.localPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and worldPos then
                local targetCFrame = CFrame.new(worldPos + Vector3.new(0, 5, 0))
                
                if Config.teleportMode == "Tween" then
                    local TweenService = game:GetService("TweenService")
                    local tweenInfo = TweenInfo.new(Config.teleportTweenSpeed or 2, Enum.EasingStyle.Linear)
                    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
                    tween:Play()
                    tween.Completed:Wait()
                else
                    hrp.CFrame = targetCFrame
                end

                if prompt then
                    firePromptOnce(prompt)
                end
            else
                warn("[Task] Cannot teleport to Task (position not found)")
            end
        end)


        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            buttonStroke.Color = Color3.fromRGB(60, 60, 60)
        end)

        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            buttonStroke.Color = Color3.fromRGB(40, 40, 40)
        end)

        Map.taskButton = button
    end

    -- Tạo nút Car
    do
        local button = Instance.new("TextButton")
        button.Name = "CarButton"
        button.Size = UDim2.new(0, 110, 0, 30)
        button.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        button.BackgroundTransparency = 0.05
        button.BorderSizePixel = 0
        button.Font = Enum.Font.GothamSemibold
        button.TextSize = 13
        button.TextColor3 = Color3.fromRGB(200, 200, 200)
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.Text = "Car"
        button.AutoButtonColor = false
        button.Visible = false
        button.Parent = Map.supplyFrame


        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 4)
        buttonCorner.Parent = button

        local buttonStroke = Instance.new("UIStroke")
        buttonStroke.Color = Color3.fromRGB(40, 40, 40)
        buttonStroke.Thickness = 1
        buttonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        buttonStroke.Parent = button

        local accentBar = Instance.new("Frame")
        accentBar.Name = "Accent"
        accentBar.Size = UDim2.new(1, 0, 0, 2)
        accentBar.Position = UDim2.new(0, 0, 1, -2)
        accentBar.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        accentBar.BorderSizePixel = 0
        accentBar.Parent = button

        local accentCorner = Instance.new("UICorner")
        accentCorner.CornerRadius = UDim.new(0, 4)
        accentCorner.Parent = accentBar

        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 10)
        padding.PaddingRight = UDim.new(0, 10)
        padding.PaddingBottom = UDim.new(0, 2)
        padding.Parent = button

        button.MouseButton1Click:Connect(function()
            local prompt = findCarPrompt()
            local worldPos = nil

            if prompt then
                worldPos = getPromptWorldPosition(prompt)
            end

            -- Fallback: nếu không có prompt thì teleport tới part "Car"
            if not worldPos then
                local carPart = findCarPart()
                if carPart then
                    worldPos = carPart.Position
                end
            end

            local char = Config.localPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and worldPos then
                local targetCFrame = CFrame.new(worldPos + Vector3.new(0, 5, 0))
                
                if Config.teleportMode == "Tween" then
                    local TweenService = game:GetService("TweenService")
                    local tweenInfo = TweenInfo.new(Config.teleportTweenSpeed or 2, Enum.EasingStyle.Linear)
                    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
                    tween:Play()
                    tween.Completed:Wait()
                else
                    hrp.CFrame = targetCFrame
                end

                if prompt then
                    firePromptOnce(prompt)
                end
            else
                warn("[Car] Không thể teleport tới Car (không tìm thấy vị trí)")
            end
        end)


        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            buttonStroke.Color = Color3.fromRGB(60, 60, 60)
        end)

        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            buttonStroke.Color = Color3.fromRGB(40, 40, 40)
        end)

        Map.carButton = button
    end

    Map.supplyScreenGui.Parent = game:GetService("CoreGui")

    -- Set vị trí ban đầu
    Map.updateSupplyPosition()

    return true
end


function Map.updateSupplyPosition()
    if not Map.supplyFrame then return end

    local totalHeight = Map.supplyFrame.Size.Y.Offset

    if Config.supplyESPPosition == "Right" then
        -- Bên phải màn hình
        Map.supplyFrame.Position = UDim2.new(1, -120, 0.5, -totalHeight / 2)
    else
        -- Bên trái màn hình (mặc định)
        Map.supplyFrame.Position = UDim2.new(0, 10, 0.5, -totalHeight / 2)
    end
end

function Map.updateSupplyDisplay()
    if not Map.supplyScreenGui or not Map.supplyFrame then
        Map.createSupplyUI()
    end

    -- Xóa buttons cũ
    for _, data in ipairs(Map.supplyButtons) do
        if data.button and data.button.Parent then
            data.button:Destroy()
        end
    end
    Map.supplyButtons = {}

    -- Tìm supplies mới
    Map.supplyItems = Map.findAllSupplies()

    if #Map.supplyItems == 0 then
        -- Ẩn frame nếu không có supply
        Map.supplyFrame.Visible = false
        return
    end

    Map.supplyFrame.Visible = true

    -- Tạo button cho mỗi supply
    for i, supply in ipairs(Map.supplyItems) do
        local button = Instance.new("TextButton")
        button.Name = "Supply_" .. i
        button.Size = UDim2.new(0, 110, 0, 30)
        button.BackgroundColor3 = Color3.fromRGB(15, 15, 15) -- Obsidian Main BG
        button.BackgroundTransparency = 0.05
        button.BorderSizePixel = 0
        button.Font = Enum.Font.GothamSemibold
        button.TextSize = 13
        button.TextColor3 = Color3.fromRGB(200, 200, 200)
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.AutoButtonColor = false
        button.Parent = Map.supplyFrame

        -- Bo góc đúng chuẩn Obsidian
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 4)
        buttonCorner.Parent = button

        -- Viền tinh tế (UIStroke)
        local buttonStroke = Instance.new("UIStroke")
        buttonStroke.Color = Color3.fromRGB(40, 40, 40) -- Obsidian Border Color
        buttonStroke.Thickness = 1
        buttonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        buttonStroke.Parent = button

        -- Accent Bar (Thanh chỉ thị phía bên dưới - Progress style)
        local accentBar = Instance.new("Frame")
        accentBar.Name = "Accent"
        accentBar.Size = UDim2.new(1, 0, 0, 2)
        accentBar.Position = UDim2.new(0, 0, 1, -2)
        accentBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        accentBar.BorderSizePixel = 0
        accentBar.Parent = button

        -- Bo góc cho thanh accent để khớp với nút
        local accentCorner = Instance.new("UICorner")
        accentCorner.CornerRadius = UDim.new(0, 4)
        accentCorner.Parent = accentBar

        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 10)
        padding.PaddingRight = UDim.new(0, 10)
        padding.PaddingBottom = UDim.new(0, 2)
        padding.Parent = button

        -- Click event
        button.MouseButton1Click:Connect(function()
            Map.teleportToSupply(supply)
        end)


        -- Hover effect
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            buttonStroke.Color = Color3.fromRGB(60, 60, 60)
        end)

        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            buttonStroke.Color = Color3.fromRGB(40, 40, 40)
        end)

        table.insert(Map.supplyButtons, {
            button = button,
            accent = accentBar,
            stroke = buttonStroke
        })
    end

    -- Tự động resize frame theo số lượng buttons (bao gồm 2 nút Task/Car)
    local totalButtons = #Map.supplyItems + 2
    local totalHeight = totalButtons * 32 + (totalButtons - 1) * 5 -- 32px mỗi button + 5px padding
    Map.supplyFrame.Size = UDim2.new(0, 140, 0, totalHeight)


    -- Update vị trí theo config
    Map.updateSupplyPosition()
end

function Map.updateSupplyDistances()
    if not Map.supplyScreenGui or #Map.supplyItems == 0 then return end

    local char = Config.localPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Tính khoảng cách thật rồi chia theo tỉ lệ (gần nhất -> xa nhất)
    local distances = {}
    local minDist = math.huge
    local maxDist = 0

    for i, supply in ipairs(Map.supplyItems) do
        local d = (hrp.Position - supply.position).Magnitude
        distances[i] = d
        if d < minDist then minDist = d end
        if d > maxDist then maxDist = d end
    end

    local range = maxDist - minDist
    if range < 1 then range = 1 end -- tránh chia 0

    for i, data in ipairs(Map.supplyButtons) do
        local supply = Map.supplyItems[i]
        local button = data.button
        local accent = data.accent
        local distance = distances[i]

        if button and supply and distance then
            button.Text = string.format("Supply %d: %.0fm", i, distance)

            -- Chuẩn hóa 0..1 theo min/max khoảng cách
            local t = (distance - minDist) / range -- 0 = gần nhất, 1 = xa nhất

            -- Đổi màu theo tỉ lệ thực tế: gần nhất xanh, xa nhất đỏ, giữa là vàng
            if t < 1/3 then
                accent.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Gần nhất
            elseif t < 2/3 then
                accent.BackgroundColor3 = Color3.fromRGB(255, 255, 0) -- Trung bình
            else
                accent.BackgroundColor3 = Color3.fromRGB(255, 100, 100) -- Xa nhất
            end
        end
    end
end

function Map.startSupplyESP()
    if Map.refreshConnection then return end

    -- Tạo UI lần đầu
    Map.createSupplyUI()
    Map.updateSupplyDisplay()

    -- Quét full Supply/Task/Car mỗi 5 giây để giảm lag
    task.spawn(function()
        while task.wait(5) do
            if Config.scriptUnloaded then break end
            if Config.supplyESPEnabled then
                -- Cập nhật danh sách Supply + nút Supply
                Map.updateSupplyDisplay()

                -- Cập nhật trạng thái Task/Car (có prompt thì hiện nút)
                if Map.taskButton then
                    Map.taskButton.Visible = (findTaskPrompt() ~= nil)
                end
                if Map.carButton then
                    Map.carButton.Visible = (findCarPrompt() ~= nil)
                end
            end
        end
    end)

    -- Heartbeat chỉ update khoảng cách (nhẹ)
    Map.refreshConnection = Config.RunService.Heartbeat:Connect(function()
        if not Config.supplyESPEnabled then return end
        Map.updateSupplyDistances()
    end)
end

function Map.stopSupplyESP()
    if Map.refreshConnection then
        Map.refreshConnection:Disconnect()
        Map.refreshConnection = nil
    end

    -- Xóa UI
    if Map.supplyScreenGui then
        Map.supplyScreenGui:Destroy()
        Map.supplyScreenGui = nil
    end

    Map.supplyButtons = {}
    Map.supplyItems = {}
end

----------------------------------------------------------
-- 🔹 Auto Door Functions

-- Lấy part cửa hiện tại (Workspace.FX.Task)
function Map.getDoorPart()
    local fx = Config.Workspace:FindFirstChild("FX") or Config.fxFolder
    if not fx then return nil end

    local taskPart = fx:FindFirstChild("Task")
    if taskPart and taskPart:IsA("BasePart") then
        return taskPart
    end

    return nil
end

-- Cho nhân vật chạm vào cửa 1 lần
function Map.openDoorOnce()
    local char = Config.localPlayer.Character
    local doorPart = Map.getDoorPart()

    if not char or not doorPart then
        return 0
    end

    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            if typeof(firetouchinterest) == "function" then
                firetouchinterest(part, doorPart, 0)
                firetouchinterest(part, doorPart, 1)
            end
        end
    end

    if typeof(firetouchtransmitter) == "function" then
        pcall(function()
            firetouchtransmitter(doorPart)
        end)
    end

    return 1
end

function Map.toggleAutoDoor(enabled)
    Map.autoDoorEnabled = enabled

    if enabled then
        Map.startAutoDoor()
    else
        Map.stopAutoDoor()
    end
end

function Map.startAutoDoor()
    Map.stopAutoDoor() -- Đảm bảo không có connection cũ
    Map.autoDoorEnabled = true

    local fx = Config.Workspace:FindFirstChild("FX") or Config.fxFolder
    if not fx then
        warn("[AutoDoor] Could not find FX to track door")
        return
    end

    local function tryOpenDoor()
        if Config.scriptUnloaded or not Map.autoDoorEnabled then
            return
        end

        local opened = Map.openDoorOnce()
        if opened > 0 then
            if Config.UI and Config.UI.Library then
                Config.UI.Library:Notify({
                    Title = "Map",
                    Description = "Door opened",
                    Time = 2
                })
            end
        end
    end

    -- Nếu cửa đã tồn tại sẵn thì mở luôn 1 lần
    tryOpenDoor()

    -- Khi trong FX có child mới tên "Task" (cửa), sẽ auto mở ngay
    Map.doorConnection = fx.ChildAdded:Connect(function(child)
        if child.Name == "Task" and child:IsA("BasePart") then
            tryOpenDoor()
        end
    end)

    print("[AutoDoor] Auto open door enabled")
end

function Map.stopAutoDoor()
    Map.autoDoorEnabled = false
    if Map.doorConnection then
        Map.doorConnection:Disconnect()
        Map.doorConnection = nil
    end
    print("[AutoDoor] Auto open door disabled")
end


----------------------------------------------------------
-- 🔹 Cleanup
function Map.cleanup()
    Map.stopSupplyESP()
    Map.stopAutoDoor()
end

return Map
