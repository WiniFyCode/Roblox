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

-- Auto Door tracking
Map.autoDoorEnabled = false
Map.doorConnection = nil
Map.lastDoorCheck = 0

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
        Map.supplyFrame.Position = UDim2.new(1, -160, 0.5, -totalHeight / 2)
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
        button.Size = UDim2.new(0, 150, 0, 32)
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
            Map.teleportToSupply(supply.position)
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
    
    for i, data in ipairs(Map.supplyButtons) do
        local supply = Map.supplyItems[i]
        local button = data.button
        local accent = data.accent
        
        if button and supply then
            local distance = (hrp.Position - supply.position).Magnitude
            button.Text = string.format("Supply %d: %.0fm", i, distance)
            
            -- Đổi màu Accent Bar theo khoảng cách
            if distance < 50 then
                accent.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Xanh lá - gần
            elseif distance < 150 then
                accent.BackgroundColor3 = Color3.fromRGB(255, 255, 0) -- Vàng - trung bình
            else
                accent.BackgroundColor3 = Color3.fromRGB(255, 100, 100) -- Đỏ - xa
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

    Map.doorConnection = task.spawn(function()
        while task.wait(5) do -- Kiểm tra mỗi 5 giây
            if Config.scriptUnloaded or not Map.autoDoorEnabled then
                break
            end

            local char = Config.localPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if char and hrp then
                local opened = Map.openDoorOnce()
                if opened > 0 then
                    print("[AutoDoor] Đã mở cửa")
                end
            end
        end

        Map.doorConnection = nil
    end)

    print("[AutoDoor] Auto open door đã được bật")
end

function Map.stopAutoDoor()
    Map.autoDoorEnabled = false
    if Map.doorConnection then
        Map.doorConnection = nil
        print("[AutoDoor] Auto open door đã được tắt")
    end
end


----------------------------------------------------------
-- 🔹 Cleanup
function Map.cleanup()
    Map.stopSupplyESP()
    Map.stopAutoDoor()
end

return Map
