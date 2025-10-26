-- Real Time Info Display Script
-- Hiển thị FPS, PING, thời gian thực với GUI đẹp

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Hit Box System Variables (moved to top to avoid reference errors)
local hitBoxSize = 5 -- Kích thước hit box mặc định

-- Tạo ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RealTimeInfo"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false

-- Tạo Frame chính
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.Size = UDim2.new(0, 0, 0, 25) -- Tự động co giãn
MainFrame.Position = UDim2.new(0, 10, 0, 10)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20) -- Màu đen đậm
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true

-- Tạo Border
local Border = Instance.new("UIStroke")
Border.Parent = MainFrame
Border.Color = Color3.fromRGB(60, 60, 60) -- Màu xám tối
Border.Thickness = 1

-- Tạo Corner (vuông góc)
local Corner = Instance.new("UICorner")
Corner.Parent = MainFrame
Corner.CornerRadius = UDim.new(0, 0)

-- Tạo Title (bỏ title để tiết kiệm không gian)

-- Tạo Context Menu
local ContextMenu = Instance.new("Frame")
ContextMenu.Name = "ContextMenu"
ContextMenu.Parent = ScreenGui
ContextMenu.Size = UDim2.new(0, 0, 0, 0)
ContextMenu.Position = UDim2.new(0, 0, 0, 0)
ContextMenu.BackgroundColor3 = Color3.fromRGB(20, 20, 20) -- Giống MainFrame
ContextMenu.BorderSizePixel = 0
ContextMenu.Visible = false
ContextMenu.ZIndex = 15
ContextMenu.AutomaticSize = Enum.AutomaticSize.XY

local ContextPadding = Instance.new("UIPadding")
ContextPadding.Parent = ContextMenu
ContextPadding.PaddingTop = UDim.new(0, 6)
ContextPadding.PaddingBottom = UDim.new(0, 6)
ContextPadding.PaddingLeft = UDim.new(0, 6)
ContextPadding.PaddingRight = UDim.new(0, 6)

local ContextLayout = Instance.new("UIListLayout")
ContextLayout.Parent = ContextMenu
ContextLayout.FillDirection = Enum.FillDirection.Vertical
ContextLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContextLayout.Padding = UDim.new(0, 4)

-- Tạo Border cho Context Menu
local ContextBorder = Instance.new("UIStroke")
ContextBorder.Parent = ContextMenu
ContextBorder.Color = Color3.fromRGB(60, 60, 60) -- Giống MainFrame
ContextBorder.Thickness = 1

-- Tạo Corner cho Context Menu
local ContextCorner = Instance.new("UICorner")
ContextCorner.Parent = ContextMenu
ContextCorner.CornerRadius = UDim.new(0, 0)

-- Tạo Hit Box Settings Frame
local HitBoxSettingsFrame = Instance.new("Frame")
HitBoxSettingsFrame.Name = "HitBoxSettings"
HitBoxSettingsFrame.Parent = ScreenGui
HitBoxSettingsFrame.Size = UDim2.new(0, 250, 0, 120)
HitBoxSettingsFrame.Position = UDim2.new(0, 300, 0, 10)
HitBoxSettingsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
HitBoxSettingsFrame.BorderSizePixel = 0
HitBoxSettingsFrame.Visible = false
HitBoxSettingsFrame.ZIndex = 20

local HitBoxBorder = Instance.new("UIStroke")
HitBoxBorder.Parent = HitBoxSettingsFrame
HitBoxBorder.Color = Color3.fromRGB(60, 60, 60)
HitBoxBorder.Thickness = 1

local HitBoxCorner = Instance.new("UICorner")
HitBoxCorner.Parent = HitBoxSettingsFrame
HitBoxCorner.CornerRadius = UDim.new(0, 0)

local HitBoxPadding = Instance.new("UIPadding")
HitBoxPadding.Parent = HitBoxSettingsFrame
HitBoxPadding.PaddingTop = UDim.new(0, 10)
HitBoxPadding.PaddingBottom = UDim.new(0, 10)
HitBoxPadding.PaddingLeft = UDim.new(0, 10)
HitBoxPadding.PaddingRight = UDim.new(0, 10)

-- Title
local HitBoxTitle = Instance.new("TextLabel")
HitBoxTitle.Name = "Title"
HitBoxTitle.Parent = HitBoxSettingsFrame
HitBoxTitle.Size = UDim2.new(1, 0, 0, 25)
HitBoxTitle.BackgroundTransparency = 1
HitBoxTitle.Text = "Hit Box Settings"
HitBoxTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
HitBoxTitle.TextSize = 14
HitBoxTitle.Font = Enum.Font.GothamBold
HitBoxTitle.TextXAlignment = Enum.TextXAlignment.Center

-- Size Label
local HitBoxSizeLabel = Instance.new("TextLabel")
HitBoxSizeLabel.Name = "SizeLabel"
HitBoxSizeLabel.Parent = HitBoxSettingsFrame
HitBoxSizeLabel.Size = UDim2.new(0, 80, 0, 25)
HitBoxSizeLabel.Position = UDim2.new(0, 0, 0, 35)
HitBoxSizeLabel.BackgroundTransparency = 1
HitBoxSizeLabel.Text = "Size:"
HitBoxSizeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
HitBoxSizeLabel.TextSize = 12
HitBoxSizeLabel.Font = Enum.Font.Gotham
HitBoxSizeLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Size TextBox
local HitBoxSizeTextBox = Instance.new("TextBox")
HitBoxSizeTextBox.Name = "SizeTextBox"
HitBoxSizeTextBox.Parent = HitBoxSettingsFrame
HitBoxSizeTextBox.Size = UDim2.new(0, 60, 0, 25)
HitBoxSizeTextBox.Position = UDim2.new(0, 90, 0, 35)
HitBoxSizeTextBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
HitBoxSizeTextBox.BorderSizePixel = 0
HitBoxSizeTextBox.Text = tostring(hitBoxSize)
HitBoxSizeTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
HitBoxSizeTextBox.TextSize = 12
HitBoxSizeTextBox.Font = Enum.Font.Gotham
HitBoxSizeTextBox.PlaceholderText = "Size"

local HitBoxTextBoxCorner = Instance.new("UICorner")
HitBoxTextBoxCorner.Parent = HitBoxSizeTextBox
HitBoxTextBoxCorner.CornerRadius = UDim.new(0, 0)

local HitBoxTextBoxBorder = Instance.new("UIStroke")
HitBoxTextBoxBorder.Parent = HitBoxSizeTextBox
HitBoxTextBoxBorder.Color = Color3.fromRGB(60, 60, 60)
HitBoxTextBoxBorder.Thickness = 1

-- Apply Button
local HitBoxApplyButton = Instance.new("TextButton")
HitBoxApplyButton.Name = "ApplyButton"
HitBoxApplyButton.Parent = HitBoxSettingsFrame
HitBoxApplyButton.Size = UDim2.new(0, 80, 0, 25)
HitBoxApplyButton.Position = UDim2.new(0, 160, 0, 35)
HitBoxApplyButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
HitBoxApplyButton.BorderSizePixel = 0
HitBoxApplyButton.Text = "Apply"
HitBoxApplyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
HitBoxApplyButton.TextSize = 12
HitBoxApplyButton.Font = Enum.Font.Gotham

local HitBoxApplyCorner = Instance.new("UICorner")
HitBoxApplyCorner.Parent = HitBoxApplyButton
HitBoxApplyCorner.CornerRadius = UDim.new(0, 0)

-- Close Button
local HitBoxCloseButton = Instance.new("TextButton")
HitBoxCloseButton.Name = "CloseButton"
HitBoxCloseButton.Parent = HitBoxSettingsFrame
HitBoxCloseButton.Size = UDim2.new(0, 25, 0, 25)
HitBoxCloseButton.Position = UDim2.new(1, -25, 0, 0)
HitBoxCloseButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
HitBoxCloseButton.BorderSizePixel = 0
HitBoxCloseButton.Text = "X"
HitBoxCloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
HitBoxCloseButton.TextSize = 14
HitBoxCloseButton.Font = Enum.Font.GothamBold

local HitBoxCloseCorner = Instance.new("UICorner")
HitBoxCloseCorner.Parent = HitBoxCloseButton
HitBoxCloseCorner.CornerRadius = UDim.new(0, 0)

-- Tạo các button trong menu
local function createMenuButton(text, callback)
    local button = Instance.new("TextButton")
    button.Name = text .. "Button"
    button.Parent = ContextMenu
    button.Size = UDim2.new(0, 0, 0, 30)
    button.BackgroundColor3 = Color3.fromRGB(20, 20, 20) -- Giống MainFrame
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(200, 200, 200) -- Giống InfoLabel
    button.TextSize = 12 -- Giống InfoLabel
    button.Font = Enum.Font.Gotham -- Giống InfoLabel
    button.TextXAlignment = Enum.TextXAlignment.Left -- Giống InfoLabel
    button.ZIndex = 20 -- ZIndex cao để text hiển thị rõ
    button.AutoButtonColor = false
    button.AutomaticSize = Enum.AutomaticSize.X
    
    -- Tạo Corner cho button
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.Parent = button
    buttonCorner.CornerRadius = UDim.new(0, 0)
    
    -- Tạo Border cho button
    local buttonBorder = Instance.new("UIStroke")
    buttonBorder.Parent = button
    buttonBorder.Color = Color3.fromRGB(60, 60, 60) -- Giống MainFrame
    buttonBorder.Thickness = 1

    local buttonPadding = Instance.new("UIPadding")
    buttonPadding.Parent = button
    buttonPadding.PaddingLeft = UDim.new(0, 10)
    buttonPadding.PaddingRight = UDim.new(0, 10)
    
    -- Hiệu ứng hover
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        }):Play()
    end)
    
    -- Xử lý click
    button.MouseButton1Click:Connect(function()
        callback()
        ContextMenu.Visible = false
    end)
    
    return button
end

-- Tạo các button menu
local rejoinButton = createMenuButton("Rejoin Server", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)

-- Hàm chung cho server hop
local function serverHop(sortOrder)
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=" .. sortOrder .. "&limit=100"))
    end)
    
    if success and result and result.data then
        for _, server in pairs(result.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id)
                break
            end
        end
    end
end

local serverHopMostButton = createMenuButton("Server Hop (Most Players)", function()
    serverHop("Desc")
end)

local serverHopLeastButton = createMenuButton("Server Hop (Least Players)", function()
    serverHop("Asc")
end)

local loadInfiniteYieldButton = createMenuButton("Load Infinite Yield", function()
    local success, error = pcall(function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    end)
    
    if success then
        print("[RealTimeInfo] Infinite Yield loaded successfully!")
    else
        warn("[RealTimeInfo] Failed to load Infinite Yield:", error)
    end
end)

-- ESP System Variables
local espEnabled = false
local espConnections = {}
local espObjects = {}
local playerConnections = {} -- Lưu connections cho từng player

-- Hit Box System Variables
local hitBoxEnabled = false
local hitBoxObjects = {} -- Lưu hit box objects

-- Lưu trạng thái ESP để tự động khôi phục khi qua ván mới
local function saveESPState()
    if ScreenGui then
        ScreenGui:SetAttribute("ESPEnabled", espEnabled)
    end
end

local function loadESPState()
    if ScreenGui then
        local savedState = ScreenGui:GetAttribute("ESPEnabled")
        if savedState ~= nil then
            return savedState
        end
    end
    return false
end

-- Hit Box Functions
local function removeHitBox(player)
    if not player then return end
    
    if hitBoxObjects and hitBoxObjects[player] then
        local hitBoxData = hitBoxObjects[player]
        if hitBoxData.box and hitBoxData.box.Destroy then
            hitBoxData.box:Destroy()
        end
        hitBoxObjects[player] = nil
    end
end

local function createHitBox(player)
    if not player or not player.Parent or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    -- Xóa hit box cũ nếu có
    removeHitBox(player)
    
    local character = player.Character
    local humanoidRootPart = character.HumanoidRootPart
    
    -- Tạo BoxHandleAdornment cho hit box
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "HitBox"
    box.Parent = humanoidRootPart
    box.Adornee = humanoidRootPart
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Color3 = Color3.fromRGB(255, 0, 0) -- Màu đỏ
    box.Transparency = 0.3
    box.Size = Vector3.new(hitBoxSize, hitBoxSize, hitBoxSize)
    
    -- Lưu hit box object
    hitBoxObjects[player] = {
        box = box,
        character = character
    }
    
    return true
end

local function updateHitBoxSize()
    for player, hitBoxData in pairs(hitBoxObjects) do
        if hitBoxData.box and hitBoxData.box.Parent then
            hitBoxData.box.Size = Vector3.new(hitBoxSize, hitBoxSize, hitBoxSize)
        end
    end
end

local function enableHitBox()
    -- Tạo hit box cho tất cả người chơi hiện tại
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            createHitBox(player)
        end
    end
    
    -- Connect events cho người chơi mới
    local playerAddedConnection = Players.PlayerAdded:Connect(function(player)
        if hitBoxEnabled then
            createHitBox(player)
        end
    end)
    
    local playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
        removeHitBox(player)
    end)
    
    -- Lưu connections
    espConnections.hitBoxPlayerAdded = playerAddedConnection
    espConnections.hitBoxPlayerRemoving = playerRemovingConnection
end

local function disableHitBox()
    -- Xóa tất cả hit box objects
    for player, _ in pairs(hitBoxObjects) do
        removeHitBox(player)
    end
    
    -- Disconnect events
    if espConnections.hitBoxPlayerAdded then
        espConnections.hitBoxPlayerAdded:Disconnect()
        espConnections.hitBoxPlayerAdded = nil
    end
    if espConnections.hitBoxPlayerRemoving then
        espConnections.hitBoxPlayerRemoving:Disconnect()
        espConnections.hitBoxPlayerRemoving = nil
    end
end

-- ESP Functions (định nghĩa trước khi sử dụng)
local function removeESP(player)
    if not player then return end
    
    if espObjects and espObjects[player] then
        local espData = espObjects[player]
        if espData.highlight and espData.highlight.Destroy then
            espData.highlight:Destroy()
        end
        if espData.billboardGui and espData.billboardGui.Destroy then
            espData.billboardGui:Destroy()
        end
        if espData.rainbowConnection and espData.rainbowConnection.Disconnect then
            espData.rainbowConnection:Disconnect()
        end
        espObjects[player] = nil
    end
    
    -- Xóa connections cho player này
    if playerConnections and playerConnections[player] then
        local connections = playerConnections[player]
        for _, connection in pairs(connections) do
            if connection and connection.Disconnect then
                connection:Disconnect()
            end
        end
        playerConnections[player] = nil
    end
end

local function createESP(player)
    if not player or not player.Parent or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    -- Xóa ESP cũ nếu có
    removeESP(player)
    
    local character = player.Character
    local humanoidRootPart = character.HumanoidRootPart
    
    -- Tạo Highlight với viền rainbow
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Parent = character
    highlight.FillColor = Color3.fromRGB(0, 255, 255) -- Cyan
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0) -- Bắt đầu với đỏ
    highlight.FillTransparency = 0.9
    highlight.OutlineTransparency = 0
    
    -- Tạo BillboardGui cho tên
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "ESP_NameTag"
    billboardGui.Parent = humanoidRootPart
    billboardGui.Size = UDim2.new(0, 200, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 5, 0) -- Tăng từ 3 lên 5 để cao hơn
    billboardGui.AlwaysOnTop = true
    -- billboardGui.MaxDistance = 1000 // Giới hạn khoảng cách hiển thị (mặc định 1000)
    
    -- Tạo TextLabel cho tên
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Parent = billboardGui
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.DisplayName
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- Trắng
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) -- Đen
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.TextYAlignment = Enum.TextYAlignment.Center
    
    -- Tạo rainbow animation cho viền (tối ưu: cập nhật mỗi 0.1s thay vì mỗi frame)
    local rainbowConnection
    local lastRainbowUpdate = 0
    rainbowConnection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        if currentTime - lastRainbowUpdate >= 0.1 then -- Cập nhật mỗi 0.1 giây
            if highlight and highlight.Parent and character and character.Parent then
                local r = math.sin(currentTime * 2) * 0.5 + 0.5
                local g = math.sin(currentTime * 2 + 2) * 0.5 + 0.5
                local b = math.sin(currentTime * 2 + 4) * 0.5 + 0.5
                highlight.OutlineColor = Color3.new(r, g, b)
                lastRainbowUpdate = currentTime
            else
                rainbowConnection:Disconnect()
            end
        end
    end)
    
    -- Lưu ESP objects
    espObjects[player] = {
        highlight = highlight,
        billboardGui = billboardGui,
        nameLabel = nameLabel,
        rainbowConnection = rainbowConnection,
        character = character
    }
    
    return true
end

local function setupPlayerESP(player)
    if not player or player == LocalPlayer or not player.Parent then return end
    
    -- Xóa connections cũ nếu có
    if playerConnections and playerConnections[player] then
        for _, connection in pairs(playerConnections[player]) do
            if connection then
                connection:Disconnect()
            end
        end
        playerConnections[player] = nil
    end
    
    -- Đảm bảo playerConnections tồn tại
    if not playerConnections then
        playerConnections = {}
    end
    
    playerConnections[player] = {}
    
    -- Tạo ESP cho character hiện tại nếu có
    local function tryCreateESP()
        if espEnabled and player.Parent and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            createESP(player)
        end
    end
    
    -- Thử tạo ESP ngay lập tức
    tryCreateESP()
    
    -- Lắng nghe khi character spawn/respawn
    local characterAddedConnection = player.CharacterAdded:Connect(function(character)
        if espEnabled and player.Parent then
            -- Đợi character load hoàn toàn
            local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
            if humanoidRootPart then
                task.wait(1) -- Đợi thêm 1 giây để đảm bảo character đã load xong
                if espEnabled and player.Parent then
                    createESP(player)
                end
            end
        end
        
        -- Tạo hit box nếu được bật
        if hitBoxEnabled and player.Parent then
            local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
            if humanoidRootPart then
                task.wait(1)
                if hitBoxEnabled and player.Parent then
                    createHitBox(player)
                end
            end
        end
    end)
    
    -- Lắng nghe khi character bị destroy (die)
    local characterRemovingConnection = player.CharacterRemoving:Connect(function()
        if espObjects[player] then
            removeESP(player)
        end
        if hitBoxObjects[player] then
            removeHitBox(player)
        end
    end)
    
    -- Lưu connections (kiểm tra an toàn)
    if playerConnections and playerConnections[player] then
        playerConnections[player].characterAdded = characterAddedConnection
        playerConnections[player].characterRemoving = characterRemovingConnection
    end
end

local function enableESP()
    -- Tạo ESP cho tất cả người chơi hiện tại
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            setupPlayerESP(player)
        end
    end
    
    -- Connect events cho người chơi mới
    local playerAddedConnection = Players.PlayerAdded:Connect(function(player)
        if espEnabled then
            setupPlayerESP(player)
        end
    end)
    
    local playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
        removeESP(player)
    end)
    
    -- Lưu connections để cleanup sau
    espConnections.playerAdded = playerAddedConnection
    espConnections.playerRemoving = playerRemovingConnection
    
    -- Tạo connection để kiểm tra liên tục các người chơi (backup)
    local checkPlayersConnection = RunService.Heartbeat:Connect(function()
        if espEnabled then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Parent and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and not espObjects[player] then
                    -- Nếu player có character nhưng chưa có ESP, tạo ESP
                    createESP(player)
                end
            end
        end
    end)
    
    espConnections.checkPlayers = checkPlayersConnection
end

local function disableESP()
    -- Xóa tất cả ESP objects
    for player, _ in pairs(espObjects) do
        removeESP(player)
    end
    
    -- Xóa tất cả player connections
    if playerConnections then
        for player, connections in pairs(playerConnections) do
            if connections then
                for _, connection in pairs(connections) do
                    if connection and connection.Disconnect then
                        connection:Disconnect()
                    end
                end
            end
        end
        playerConnections = {}
    end
    
    -- Disconnect events
    if espConnections.playerAdded then
        espConnections.playerAdded:Disconnect()
        espConnections.playerAdded = nil
    end
    if espConnections.playerRemoving then
        espConnections.playerRemoving:Disconnect()
        espConnections.playerRemoving = nil
    end
    if espConnections.checkPlayers then
        espConnections.checkPlayers:Disconnect()
        espConnections.checkPlayers = nil
    end
end

-- Tạo ESP Button sau khi đã định nghĩa các hàm
local toggleEspButton
toggleEspButton = createMenuButton("ESP: OFF", function()
    espEnabled = not espEnabled
    
    if espEnabled then
        enableESP()
    else
        disableESP()
    end
    
    -- Lưu trạng thái ESP
    saveESPState()
    
    -- Cập nhật text button
    toggleEspButton.Text = "ESP: " .. (espEnabled and "ON" or "OFF")
end)

-- Tạo Invisible Frame để click khi ẩn script
local InvisibleFrame = Instance.new("Frame")
InvisibleFrame.Name = "InvisibleFrame"
InvisibleFrame.Parent = ScreenGui
InvisibleFrame.Size = UDim2.new(0, 200, 0, 25) -- Kích thước tương tự MainFrame
InvisibleFrame.Position = UDim2.new(0, 10, 0, 10)
InvisibleFrame.BackgroundTransparency = 1 -- Hoàn toàn trong suốt
InvisibleFrame.BorderSizePixel = 0
InvisibleFrame.Active = true
InvisibleFrame.Visible = false -- Mặc định ẩn

local hiddenScriptButton = createMenuButton("Hidden Script", function()
    -- Toggle ẩn/hiện script
    if MainFrame.Visible then
        MainFrame.Visible = false
        InvisibleFrame.Visible = true -- Hiện invisible frame
        hiddenScriptButton.Text = "Show Script"
    else
        MainFrame.Visible = true
        InvisibleFrame.Visible = false -- Ẩn invisible frame
        hiddenScriptButton.Text = "Hidden Script"
    end
end)

-- Tạo Hit Box Button
local toggleHitBoxButton
toggleHitBoxButton = createMenuButton("Hit Box: OFF", function()
    hitBoxEnabled = not hitBoxEnabled
    
    if hitBoxEnabled then
        enableHitBox()
    else
        disableHitBox()
    end
    
    -- Cập nhật text button
    toggleHitBoxButton.Text = "Hit Box: " .. (hitBoxEnabled and "ON" or "OFF")
end)

-- Tạo Hit Box Settings Button
local hitBoxSettingsButton = createMenuButton("Hit Box Settings", function()
    HitBoxSettingsFrame.Visible = not HitBoxSettingsFrame.Visible
end)

-- Biến để tính FPS
local lastTime = tick()
local frameCount = 0
local fps = 0

-- Biến để tính PING
local lastPingTime = 0
local ping = 0

-- Biến để tính TIME (cập nhật mỗi giây)
local lastTimeUpdate = 0
local timeString = "00:00:00"

-- Biến để lưu thông tin game
local GAME_NAME = "Unknown Game"
local PLACE_NAME = "Unknown Place"
local PLACE_ID = game.PlaceId
local GAME_ID = game.GameId
-- ====== LẤY PLACE NAME ======
local success, info = pcall(function()
	return MarketplaceService:GetProductInfo(PLACE_ID)
end)

if success and info and info.Name then
	PLACE_NAME = info.Name
else
	warn("[PLACE ERROR] Không thể lấy thông tin Place:", info)
end

-- ====== LẤY GAME NAME ======
local HttpService = game:GetService("HttpService")

-- Hàm lấy game name từ API
local function getGameName()
	local success, result = pcall(function()
		-- Sử dụng API chính thức của Roblox
		local url = "https://games.roblox.com/v1/games?universeIds=" .. tostring(GAME_ID)
		
		-- Thử với game:HttpGet trước (executor)
		if game.HttpGet then
			local response = game:HttpGet(url, true)
			return HttpService:JSONDecode(response)
		end
		
		-- Fallback: sử dụng HttpService:GetAsync
		return HttpService:GetAsync(url)
	end)
	
	if success and result then
		local data
		if type(result) == "string" then
			data = HttpService:JSONDecode(result)
		else
			data = result
		end
		
		if data and data.data and data.data[1] and data.data[1].name then
			return data.data[1].name
		end
	end
	
	return nil
end

-- Thử lấy game name
local retrievedGameName = getGameName()
if retrievedGameName then
	GAME_NAME = retrievedGameName
else
	GAME_NAME = "Unknown Game"
	warn("[GAME ERROR] Không thể lấy tên game từ API")
end

-- Kiểm tra nếu PLACE_NAME giống GAME_NAME thì chỉ hiển thị GAME_NAME
local DISPLAY_NAME = GAME_NAME
if PLACE_NAME ~= GAME_NAME then
	DISPLAY_NAME = GAME_NAME .. " | " .. PLACE_NAME
end

-- Tạo Info Label (tất cả thông tin trong 1 label)
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Name = "InfoLabel"
InfoLabel.Parent = MainFrame
InfoLabel.Size = UDim2.new(0, 0, 1, 0) -- Tự động co giãn theo nội dung
InfoLabel.Position = UDim2.new(0, 5, 0, 0)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = DISPLAY_NAME .. " | FPS: 60 | PING: 50ms | TIME: 12:34:56 | PLAYER: 15/20"
InfoLabel.TextColor3 = Color3.fromRGB(200, 200, 200) -- Màu xám nhạt
InfoLabel.TextSize = 12
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel.TextWrapped = false -- Không wrap text

-- Biến để lưu thông tin tĩnh (chỉ cập nhật 1 lần)
local staticInfo = {
    displayName = DISPLAY_NAME,
    maxPlayers = game.PrivateServerId and 20 or game.Players.MaxPlayers
}

-- Hàm cập nhật thông tin tĩnh (chỉ gọi khi cần thiết)
local function updateStaticInfo()
    staticInfo.maxPlayers = game.PrivateServerId and 20 or game.Players.MaxPlayers
    -- Có thể thêm các thông tin tĩnh khác ở đây nếu cần
end

-- Hàm cập nhật thông tin động (FPS, PING, TIME, PLAYER COUNT)
local function updateDynamicInfo()
    -- Cập nhật FPS
    frameCount = frameCount + 1
    local currentTime = tick()
    
    if currentTime - lastTime >= 1 then
        fps = math.floor(frameCount / (currentTime - lastTime))
        frameCount = 0
        lastTime = currentTime
    end
    
    -- Cập nhật PING
    if currentTime - lastPingTime >= 1 then
        local success, result = pcall(function()
            return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        
        if success and result then
            ping = math.floor(result)
        end
        
        lastPingTime = currentTime
    end
    
    -- Cập nhật thời gian (chỉ mỗi giây)
    if currentTime - lastTimeUpdate >= 1 then
        local realTime = os.date("*t")
        timeString = string.format("%02d:%02d:%02d", realTime.hour, realTime.min, realTime.sec)
        lastTimeUpdate = currentTime
    end
    
    -- Cập nhật Player Count
    local playerCount = #Players:GetPlayers()
    
    -- Cập nhật InfoLabel với thông tin tĩnh + động
    InfoLabel.Text = staticInfo.displayName .. " | FPS: " .. fps .. " | PING: " .. ping .. "ms | TIME: " .. timeString .. " | PLAYER: " .. playerCount .. "/" .. staticInfo.maxPlayers
    
    -- Tự động điều chỉnh kích thước MainFrame theo nội dung
    local textBounds = InfoLabel.TextBounds
    local newWidth = textBounds.X + 10 -- Thêm 10px padding
    MainFrame.Size = UDim2.new(0, newWidth, 0, 25)
    
    -- Đồng bộ kích thước với InvisibleFrame
    InvisibleFrame.Size = UDim2.new(0, newWidth, 0, 25)
end

-- Kết nối RenderStepped để cập nhật liên tục
local connection
connection = RunService.RenderStepped:Connect(function()
    updateDynamicInfo()
end)

-- Function để cập nhật text button dựa trên trạng thái hiện tại
local function updateHiddenButtonText()
    if MainFrame.Visible then
        hiddenScriptButton.Text = "Hidden Script"
    else
        hiddenScriptButton.Text = "Show Script"
    end
end

-- Xử lý chuột phải để hiển thị context menu
MainFrame.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        local mouse = LocalPlayer:GetMouse()
        updateHiddenButtonText() -- Cập nhật text trước khi hiển thị menu
        ContextMenu.Position = UDim2.new(0, mouse.X, 0, mouse.Y)
        ContextMenu.Visible = true
    end
end)

-- Xử lý chuột phải cho InvisibleFrame (khi script bị ẩn)
InvisibleFrame.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        local mouse = LocalPlayer:GetMouse()
        updateHiddenButtonText() -- Cập nhật text trước khi hiển thị menu
        ContextMenu.Position = UDim2.new(0, mouse.X, 0, mouse.Y)
        ContextMenu.Visible = true
    end
end)

-- Đóng context menu khi click ra ngoài
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
        ContextMenu.Visible = false
    end
end)

-- Tự động khôi phục trạng thái ESP khi script khởi động
local function autoRestoreESP()
    local savedState = loadESPState()
    if savedState then
        espEnabled = true
        enableESP()
        toggleEspButton.Text = "ESP: ON"
        print("[RealTimeInfo] ESP automatically restored from previous session")
    end
end

-- Khôi phục ESP sau khi script load xong
task.spawn(function()
    task.wait(2) -- Đợi script load hoàn toàn
    autoRestoreESP()
end)

-- Hit Box Settings Event Handlers
HitBoxApplyButton.MouseButton1Click:Connect(function()
    local newSize = tonumber(HitBoxSizeTextBox.Text)
    if newSize and newSize > 0 and newSize <= 50 then -- Giới hạn từ 1-50
        hitBoxSize = newSize
        updateHitBoxSize()
        print("[RealTimeInfo] Hit Box size updated to: " .. hitBoxSize)
    else
        warn("[RealTimeInfo] Invalid hit box size! Please enter a number between 1-50")
        HitBoxSizeTextBox.Text = tostring(hitBoxSize) -- Reset về giá trị cũ
    end
end)

HitBoxCloseButton.MouseButton1Click:Connect(function()
    HitBoxSettingsFrame.Visible = false
end)

-- Hover effects cho buttons
HitBoxApplyButton.MouseEnter:Connect(function()
    TweenService:Create(HitBoxApplyButton, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    }):Play()
end)

HitBoxApplyButton.MouseLeave:Connect(function()
    TweenService:Create(HitBoxApplyButton, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundColor3 = Color3.fromRGB(0, 120, 0)
    }):Play()
end)

HitBoxCloseButton.MouseEnter:Connect(function()
    TweenService:Create(HitBoxCloseButton, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    }):Play()
end)

HitBoxCloseButton.MouseLeave:Connect(function()
    TweenService:Create(HitBoxCloseButton, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    }):Play()
end)

-- Cập nhật thông tin tĩnh khi có thay đổi về server
Players.PlayerAdded:Connect(function()
    updateStaticInfo()
end)

-- Cleanup khi player rời khỏi game
Players.PlayerRemoving:Connect(function(leavingPlayer)
    -- Cập nhật thông tin tĩnh cho tất cả players
    updateStaticInfo()
    
    -- Cleanup khi LocalPlayer rời game
    if leavingPlayer == LocalPlayer then
        if connection then
            connection:Disconnect()
        end
        
        -- Cleanup ESP
        if espEnabled then
            disableESP()
        end
        
        -- Cleanup Hit Box
        if hitBoxEnabled then
            disableHitBox()
        end
        
        if ScreenGui then
            ScreenGui:Destroy()
        end
    end
end)
