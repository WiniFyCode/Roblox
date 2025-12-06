--[[
    Map Module - Zombie Hyperloot
    Map Teleport, Start, Replay, Supply ESP
]]

local Map = {}
local Config = nil

-- Supply ESP tracking
Map.supplyItems = {}
Map.supplyUIElements = {}
Map.refreshConnection = nil
Map.hasDrawing = false

function Map.init(config)
    Config = config
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
        warn("[MapTeleport] Không tìm thấy nhân vật hoặc HumanoidRootPart")
        return
    end

    local touchPart = Map.getWaitAreaTouchPart()
    if not touchPart or not touchPart:IsA("BasePart") then
        warn("[MapTeleport] Không tìm thấy WaitArea TouchPart")
        return
    end

    hrp.CFrame = touchPart.CFrame + Vector3.new(0, 4, 0)
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
        warn("[ReplayMatch] Không tìm thấy ReplicatedStorage.Remote")
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

-- Auto Replay Loop
function Map.startAutoReplayLoop()
    task.spawn(function()
        while task.wait(3) do
            if Config.scriptUnloaded then break end
            if Config.autoReplayEnabled then
                Map.replayCurrentMatch()
            end
        end
    end)
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

function Map.createSupplyUI()
    -- Kiểm tra Drawing API
    local ok, obj = pcall(function()
        return Drawing.new("Text")
    end)
    if ok and obj then
        Map.hasDrawing = true
        obj:Remove()
    else
        warn("[Supply] Drawing API không khả dụng")
        return false
    end
    
    return true
end

function Map.updateSupplyDisplay()
    if not Map.hasDrawing then return end
    
    -- Xóa UI cũ
    for _, element in ipairs(Map.supplyUIElements) do
        if element.Remove then
            pcall(function() element:Remove() end)
        end
    end
    Map.supplyUIElements = {}
    
    -- Tìm supplies mới
    Map.supplyItems = Map.findAllSupplies()
    
    if #Map.supplyItems == 0 then return end
    
    -- Vẽ UI mới
    local screenHeight = Config.Workspace.CurrentCamera.ViewportSize.Y
    local startY = (screenHeight / 2) - (#Map.supplyItems * 25 / 2) -- Center vertically
    local startX = 20 -- Bên trái màn hình
    
    -- Title
    local titleText = Drawing.new("Text")
    titleText.Text = "=== SUPPLIES ==="
    titleText.Size = 18
    titleText.Font = 2
    titleText.Color = Color3.fromRGB(255, 255, 0)
    titleText.Position = Vector2.new(startX, startY - 30)
    titleText.Outline = true
    titleText.Visible = true
    table.insert(Map.supplyUIElements, titleText)
    
    -- Supply items
    for i, supply in ipairs(Map.supplyItems) do
        local char = Config.localPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local distance = hrp and (hrp.Position - supply.position).Magnitude or 0
        
        -- Text hiển thị
        local displayText = string.format("[%d] %s - %.0fm", i, supply.name, distance)
        
        local text = Drawing.new("Text")
        text.Text = displayText
        text.Size = 16
        text.Font = 2
        text.Color = Color3.fromRGB(255, 255, 255)
        text.Position = Vector2.new(startX, startY + (i - 1) * 25)
        text.Outline = true
        text.Visible = true
        
        table.insert(Map.supplyUIElements, text)
    end
    
    -- Count text
    local countText = Drawing.new("Text")
    countText.Text = string.format("Total: %d supplies", #Map.supplyItems)
    countText.Size = 14
    countText.Font = 2
    countText.Color = Color3.fromRGB(100, 255, 100)
    countText.Position = Vector2.new(startX, startY + #Map.supplyItems * 25 + 10)
    countText.Outline = true
    countText.Visible = true
    table.insert(Map.supplyUIElements, countText)
end

function Map.startSupplyESP()
    if Map.refreshConnection then return end
    
    -- Tạo UI lần đầu
    if not Map.createSupplyUI() then
        warn("[Supply] Không thể khởi tạo Supply UI")
        return
    end
    
    Map.updateSupplyDisplay()
    
    -- Auto refresh mỗi 15 giây
    task.spawn(function()
        while task.wait(15) do
            if Config.scriptUnloaded then break end
            if Config.supplyESPEnabled then
                Map.updateSupplyDisplay()
            end
        end
    end)
    
    -- Update distance realtime (mỗi 0.5s)
    Map.refreshConnection = Config.RunService.Heartbeat:Connect(function()
        if not Config.supplyESPEnabled or #Map.supplyItems == 0 then return end
        
        -- Chỉ update distance, không tìm lại supplies
        local char = Config.localPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        -- Update text elements (bỏ qua title và count)
        for i = 2, #Map.supplyUIElements - 1 do
            local element = Map.supplyUIElements[i]
            local supply = Map.supplyItems[i - 1]
            if element and supply then
                local distance = (hrp.Position - supply.position).Magnitude
                element.Text = string.format("[%d] %s - %.0fm", i - 1, supply.name, distance)
                
                -- Đổi màu theo khoảng cách
                if distance < 50 then
                    element.Color = Color3.fromRGB(0, 255, 0) -- Xanh lá - gần
                elseif distance < 150 then
                    element.Color = Color3.fromRGB(255, 255, 0) -- Vàng - trung bình
                else
                    element.Color = Color3.fromRGB(255, 100, 100) -- Đỏ - xa
                end
            end
        end
    end)
end

function Map.stopSupplyESP()
    if Map.refreshConnection then
        Map.refreshConnection:Disconnect()
        Map.refreshConnection = nil
    end
    
    -- Xóa UI
    for _, element in ipairs(Map.supplyUIElements) do
        if element.Remove then
            pcall(function() element:Remove() end)
        end
    end
    Map.supplyUIElements = {}
    Map.supplyItems = {}
end

function Map.cleanup()
    Map.stopSupplyESP()
end

return Map
