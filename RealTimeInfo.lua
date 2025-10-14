-- Real Time Info Display Script
-- Hiển thị FPS, PING, thời gian thực với GUI đẹp

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

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

local serverHopMostButton = createMenuButton("Server Hop (Most Players)", function()
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"))
    end)
    
    if success and result and result.data then
        for _, server in pairs(result.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id)
                break
            end
        end
    end
end)

local serverHopLeastButton = createMenuButton("Server Hop (Least Players)", function()
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
    end)
    
    if success and result and result.data then
        for _, server in pairs(result.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id)
                break
            end
        end
    end
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

-- ESP Functions (định nghĩa trước khi sử dụng)
local function createESP(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local character = player.Character
    local humanoidRootPart = character.HumanoidRootPart
    
    -- Tạo Highlight với viền rainbow
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Parent = character
    highlight.FillColor = Color3.fromRGB(0, 255, 255) -- Cyan
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0) -- Bắt đầu với đỏ
    highlight.FillTransparency = 0.3
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
    
    -- Tạo rainbow animation cho viền
    local rainbowConnection
    rainbowConnection = RunService.Heartbeat:Connect(function()
        if highlight and highlight.Parent then
            local time = tick()
            local r = math.sin(time * 2) * 0.5 + 0.5
            local g = math.sin(time * 2 + 2) * 0.5 + 0.5
            local b = math.sin(time * 2 + 4) * 0.5 + 0.5
            highlight.OutlineColor = Color3.new(r, g, b)
        else
            rainbowConnection:Disconnect()
        end
    end)
    
    -- Lưu ESP objects
    espObjects[player] = {
        highlight = highlight,
        billboardGui = billboardGui,
        nameLabel = nameLabel,
        rainbowConnection = rainbowConnection
    }
end

local function removeESP(player)
    if espObjects[player] then
        if espObjects[player].highlight then
            espObjects[player].highlight:Destroy()
        end
        if espObjects[player].billboardGui then
            espObjects[player].billboardGui:Destroy()
        end
        if espObjects[player].rainbowConnection then
            espObjects[player].rainbowConnection:Disconnect()
        end
        espObjects[player] = nil
    end
end

local function enableESP()
    -- Tạo ESP cho tất cả người chơi hiện tại
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            -- Đợi character load nếu cần
            if player.Character then
                createESP(player)
            else
                player.CharacterAdded:Connect(function()
                    createESP(player)
                end)
            end
        end
    end
    
    -- Connect events cho người chơi mới
    local playerAddedConnection = Players.PlayerAdded:Connect(function(player)
        if espEnabled then
            -- Xử lý character spawn cho người chơi mới
            local function onCharacterAdded(character)
                spawn(function()
                    wait(2) -- Đợi character load hoàn toàn
                    if espEnabled and player.Parent then -- Kiểm tra player vẫn còn trong game
                        createESP(player)
                    end
                end)
            end
            
            if player.Character then
                onCharacterAdded(player.Character)
            else
                player.CharacterAdded:Connect(onCharacterAdded)
            end
        end
    end)
    
    local playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
        removeESP(player)
    end)
    
    -- Lưu connections để cleanup sau
    espConnections.playerAdded = playerAddedConnection
    espConnections.playerRemoving = playerRemovingConnection
    
    -- Tạo connection để kiểm tra liên tục các người chơi
    local checkPlayersConnection = RunService.Heartbeat:Connect(function()
        if espEnabled then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and not espObjects[player] then
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
    
    -- Cập nhật text button
    toggleEspButton.Text = "ESP: " .. (espEnabled and "ON" or "OFF")
end)

local reloadScriptButton = createMenuButton("Reload Script", function()
    -- Reload script bằng cách destroy và tạo lại
    if ScreenGui then
        ScreenGui:Destroy()
    end
    
    -- Chờ một chút rồi load lại script từ clipboard hoặc local
    wait(0.1)
    print("[RealTimeInfo] Script reloaded! Please re-execute the script manually.")
end)

local hiddenScriptButton = createMenuButton("Hidden Script", function()
    -- Toggle ẩn/hiện script
    if MainFrame.Visible then
        MainFrame.Visible = false
        hiddenScriptButton.Text = "Show Script"
    else
        MainFrame.Visible = true
        hiddenScriptButton.Text = "Hidden Script"
    end
end)

-- Biến để tính FPS
local lastTime = 0
local frameCount = 0
local fps = 0

-- Biến để tính PING
local lastPingTime = 0
local ping = 0

-- Biến để lưu thông tin game
local gameName = "Unknown Game"
local placeName = "Unknown Place"
local placeId = game.PlaceId
local gameId = game.GameId
-- ====== LẤY PLACE NAME ======
local success, info = pcall(function()
	return MarketplaceService:GetProductInfo(placeId)
end)

if success and info and info.Name then
	placeName = info.Name
else
	warn("[PLACE ERROR] Không thể lấy thông tin Place:", info)
end

-- ====== LẤY GAME NAME ======
local HttpService = game:GetService("HttpService")

-- Hàm lấy game name từ API
local function getGameName()
	local success, result = pcall(function()
		-- Sử dụng API chính thức của Roblox
		local url = "https://games.roblox.com/v1/games?universeIds=" .. tostring(gameId)
		
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
	gameName = retrievedGameName
else
	gameName = "Unknown Game"
	warn("[GAME ERROR] Không thể lấy tên game từ API")
end

-- Kiểm tra nếu placeName giống gameName thì chỉ hiển thị gameName
local displayName = gameName
if placeName ~= gameName then
	displayName = gameName .. " | " .. placeName
end

-- Tạo Info Label (tất cả thông tin trong 1 label)
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Name = "InfoLabel"
InfoLabel.Parent = MainFrame
InfoLabel.Size = UDim2.new(0, 0, 1, 0) -- Tự động co giãn theo nội dung
InfoLabel.Position = UDim2.new(0, 5, 0, 0)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = displayName .. " | FPS: 60 | PING: 50ms | TIME: 12:34:56 | PLAYER: 15/20"
InfoLabel.TextColor3 = Color3.fromRGB(200, 200, 200) -- Màu xám nhạt
InfoLabel.TextSize = 12
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel.TextWrapped = false -- Không wrap text

-- Hàm cập nhật tất cả thông tin
local function updateAllInfo()
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
    
    -- Cập nhật thời gian
    local realTime = os.date("*t")
    local timeString = string.format("%02d:%02d:%02d", realTime.hour, realTime.min, realTime.sec)
    
    -- Cập nhật Server Info
    local playerCount = #Players:GetPlayers()
    local maxPlayers = game.PrivateServerId and 20 or game.Players.MaxPlayers
    
    -- Cập nhật InfoLabel
    InfoLabel.Text = displayName .. " | FPS: " .. fps .. " | PING: " .. ping .. "ms | TIME: " .. timeString .. " | PLAYER: " .. playerCount .. "/" .. maxPlayers
    
    -- Tự động điều chỉnh kích thước MainFrame theo nội dung
    local textBounds = InfoLabel.TextBounds
    local newWidth = textBounds.X + 10 -- Thêm 10px padding
    MainFrame.Size = UDim2.new(0, newWidth, 0, 25)
end

-- Kết nối RenderStepped để cập nhật liên tục
local connection
connection = RunService.RenderStepped:Connect(function()
    updateAllInfo()
end)

-- Xử lý chuột phải để hiển thị context menu
MainFrame.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        local mouse = LocalPlayer:GetMouse()
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

-- Tạo hotkey để ẩn/hiện GUI (F9)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F9 then
        MainFrame.Visible = not MainFrame.Visible
        if not MainFrame.Visible then
            ContextMenu.Visible = false
        end
        -- Cập nhật text button
        if hiddenScriptButton then
            hiddenScriptButton.Text = MainFrame.Visible and "Hidden Script" or "Show Script"
        end
    end
end)

-- Cleanup khi script bị hủy
game:BindToClose(function()
    if connection then
        connection:Disconnect()
    end
    
    -- Cleanup ESP
    if espEnabled then
        disableESP()
    end
    
    if ScreenGui then
        ScreenGui:Destroy()
    end
end)
