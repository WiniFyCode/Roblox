--[[
    Map Module - Zombie Hyperloot
    Map Teleport, Start, Replay, Supply ESP
]]

local Map = {}
local Config = nil

-- Supply ESP tracking
Map.supplyItems = {}
Map.supplyScreenGui = nil
Map.supplyFrame = nil
Map.supplyButtons = {}
Map.refreshConnection = nil

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

function Map.teleportToSupply(supplyPosition)
    local char = Config.localPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        warn("[Supply] Không tìm thấy HumanoidRootPart")
        return
    end
    
    -- Teleport tới supply (cao hơn 5 studs để tránh bị stuck)
    hrp.CFrame = CFrame.new(supplyPosition + Vector3.new(0, 5, 0))
end

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
        Map.supplyFrame.Position = UDim2.new(1, -150, 0.5, -totalHeight / 2)
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
    for _, button in ipairs(Map.supplyButtons) do
        if button and button.Parent then
            button:Destroy()
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
        button.Size = UDim2.new(0, 140, 0, 35)
        button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        button.BackgroundTransparency = 0.2
        button.BorderSizePixel = 1
        button.BorderColor3 = Color3.fromRGB(100, 100, 100)
        button.Font = Enum.Font.SourceSans
        button.TextSize = 14
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.Parent = Map.supplyFrame
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = button
        
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 4)
        padding.PaddingRight = UDim.new(0, 4)
        padding.Parent = button
        
        -- Click event
        button.MouseButton1Click:Connect(function()
            Map.teleportToSupply(supply.position)
        end)
        
        -- Hover effect
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end)
        
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        end)
        
        table.insert(Map.supplyButtons, button)
    end
    
    -- Tự động resize frame theo số lượng buttons
    local totalHeight = #Map.supplyItems * 32 + (#Map.supplyItems - 1) * 5 -- 32px mỗi button + 5px padding
    Map.supplyFrame.Size = UDim2.new(0, 140, 0, totalHeight)
    
    -- Update vị trí theo config
    Map.updateSupplyPosition()
end

function Map.updateSupplyDistances()
    if not Map.supplyScreenGui or #Map.supplyItems == 0 then return end
    
    local char = Config.localPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    for i, button in ipairs(Map.supplyButtons) do
        local supply = Map.supplyItems[i]
        if button and supply then
            local distance = (hrp.Position - supply.position).Magnitude
            button.Text = string.format("Supply %d: %.0fm", i, distance)
            
            -- Đổi màu theo khoảng cách
            if distance < 50 then
                button.BorderColor3 = Color3.fromRGB(0, 255, 0) -- Xanh lá - gần
                button.TextColor3 = Color3.fromRGB(0, 255, 0)
            elseif distance < 150 then
                button.BorderColor3 = Color3.fromRGB(255, 255, 0) -- Vàng - trung bình
                button.TextColor3 = Color3.fromRGB(255, 255, 0)
            else
                button.BorderColor3 = Color3.fromRGB(255, 100, 100) -- Đỏ - xa
                button.TextColor3 = Color3.fromRGB(255, 100, 100)
            end
        end
    end
end

function Map.startSupplyESP()
    if Map.refreshConnection then return end
    
    -- Tạo UI lần đầu
    Map.createSupplyUI()
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
    
    -- Update distance realtime
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

function Map.cleanup()
    Map.stopSupplyESP()
end

return Map
