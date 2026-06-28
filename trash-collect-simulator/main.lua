-- Script auto collect trashes với UI
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local trashEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("RemoteEvents"):WaitForChild("TrashEvent")

-- ====== CẤU HÌNH ======
local Config = {
    AutoCollect = true,
    AutoCollectNew = true,
    CollectDelay = 0.1,
    LoopInterval = 5,
    EnableLoop = false,
    ShowDebugLogs = true,
    KeybindToggle = Enum.KeyCode.F,
}

-- ====== BIẾN ĐIỀU KHIỂN ======
local isRunning = true
local isCollecting = false
local loopConnection = nil
local childAddedConnection = nil
local totalCollected = 0
local trashCount = 0

-- ====== TẠO UI ======
local function createUI()
    -- Tạo ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoCollectUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 300, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Drop Shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.new(0, -10, 0, -10)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://1316040198"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.7
    shadow.Parent = mainFrame
    
    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    titleBar.BackgroundTransparency = 0.3
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -40, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🗑️ Auto Collect Trash"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.Parent = titleBar
    
    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    closeBtn.TextSize = 20
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = titleBar
    
    -- Drag functionality
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    closeBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = not mainFrame.Visible
    end)
    
    -- Content
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -20, 1, -60)
    content.Position = UDim2.new(0, 10, 0, 50)
    content.BackgroundTransparency = 1
    content.Parent = mainFrame
    
    -- Status Frame
    local statusFrame = Instance.new("Frame")
    statusFrame.Name = "StatusFrame"
    statusFrame.Size = UDim2.new(1, 0, 0, 60)
    statusFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    statusFrame.BackgroundTransparency = 0.5
    statusFrame.BorderSizePixel = 0
    statusFrame.Parent = content
    
    -- Status Label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, 0, 0, 25)
    statusLabel.Position = UDim2.new(0, 0, 0, 5)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Trạng thái: 🟢 Đang chạy"
    statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    statusLabel.TextSize = 14
    statusLabel.Font = Enum.Font.GothamSemibold
    statusLabel.Parent = statusFrame
    
    -- Stats
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Name = "StatsLabel"
    statsLabel.Size = UDim2.new(1, 0, 0, 20)
    statsLabel.Position = UDim2.new(0, 0, 0, 32)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Text = "Đã collect: 0 | Trashes: 0"
    statsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statsLabel.TextSize = 12
    statsLabel.Font = Enum.Font.Gotham
    statsLabel.Parent = statusFrame
    
    -- Separator
    local separator = Instance.new("Frame")
    separator.Size = UDim2.new(1, 0, 0, 1)
    separator.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    separator.BorderSizePixel = 0
    separator.Parent = content
    separator.Position = UDim2.new(0, 0, 0, 65)
    
    -- Control Buttons
    local controls = Instance.new("Frame")
    controls.Name = "Controls"
    controls.Size = UDim2.new(1, 0, 0, 120)
    controls.Position = UDim2.new(0, 0, 0, 75)
    controls.BackgroundTransparency = 1
    controls.Parent = content
    
    -- Toggle Button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleBtn"
    toggleBtn.Size = UDim2.new(1, 0, 0, 35)
    toggleBtn.Position = UDim2.new(0, 0, 0, 0)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = "⏸️ TẠM DỪNG"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextSize = 14
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.Parent = controls
    
    -- Collect Now Button
    local collectBtn = Instance.new("TextButton")
    collectBtn.Name = "CollectBtn"
    collectBtn.Size = UDim2.new(1, 0, 0, 35)
    collectBtn.Position = UDim2.new(0, 0, 0, 40)
    collectBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 200)
    collectBtn.BorderSizePixel = 0
    collectBtn.Text = "📦 COLLECT NGAY"
    collectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    collectBtn.TextSize = 14
    collectBtn.Font = Enum.Font.GothamBold
    collectBtn.Parent = controls
    
    -- Settings Button
    local settingsBtn = Instance.new("TextButton")
    settingsBtn.Name = "SettingsBtn"
    settingsBtn.Size = UDim2.new(1, 0, 0, 35)
    settingsBtn.Position = UDim2.new(0, 0, 0, 80)
    settingsBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
    settingsBtn.BorderSizePixel = 0
    settingsBtn.Text = "⚙️ CÀI ĐẶT"
    settingsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    settingsBtn.TextSize = 14
    settingsBtn.Font = Enum.Font.GothamBold
    settingsBtn.Parent = controls
    
    -- Settings Panel (Hidden by default)
    local settingsPanel = Instance.new("Frame")
    settingsPanel.Name = "SettingsPanel"
    settingsPanel.Size = UDim2.new(1, 0, 0, 150)
    settingsPanel.Position = UDim2.new(0, 0, 0, 205)
    settingsPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    settingsPanel.BackgroundTransparency = 0.5
    settingsPanel.BorderSizePixel = 0
    settingsPanel.Visible = false
    settingsPanel.Parent = content
    
    -- Auto Collect New
    local autoNewLabel = Instance.new("TextLabel")
    autoNewLabel.Size = UDim2.new(0.6, 0, 0, 25)
    autoNewLabel.Position = UDim2.new(0, 5, 0, 5)
    autoNewLabel.BackgroundTransparency = 1
    autoNewLabel.Text = "Auto collect mới:"
    autoNewLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    autoNewLabel.TextSize = 12
    autoNewLabel.TextXAlignment = Enum.TextXAlignment.Left
    autoNewLabel.Font = Enum.Font.Gotham
    autoNewLabel.Parent = settingsPanel
    
    local autoNewToggle = Instance.new("TextButton")
    autoNewToggle.Name = "AutoNewToggle"
    autoNewToggle.Size = UDim2.new(0, 60, 0, 25)
    autoNewToggle.Position = UDim2.new(0.65, 0, 0, 5)
    autoNewToggle.BackgroundColor3 = Config.AutoCollectNew and Color3.fromRGB(60, 200, 60) or Color3.fromRGB(200, 60, 60)
    autoNewToggle.BorderSizePixel = 0
    autoNewToggle.Text = Config.AutoCollectNew and "ON" or "OFF"
    autoNewToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoNewToggle.TextSize = 12
    autoNewToggle.Font = Enum.Font.GothamBold
    autoNewToggle.Parent = settingsPanel
    
    -- Loop Enable
    local loopLabel = Instance.new("TextLabel")
    loopLabel.Size = UDim2.new(0.6, 0, 0, 25)
    loopLabel.Position = UDim2.new(0, 5, 0, 35)
    loopLabel.BackgroundTransparency = 1
    loopLabel.Text = "Loop collect:"
    loopLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    loopLabel.TextSize = 12
    loopLabel.TextXAlignment = Enum.TextXAlignment.Left
    loopLabel.Font = Enum.Font.Gotham
    loopLabel.Parent = settingsPanel
    
    local loopToggle = Instance.new("TextButton")
    loopToggle.Name = "LoopToggle"
    loopToggle.Size = UDim2.new(0, 60, 0, 25)
    loopToggle.Position = UDim2.new(0.65, 0, 0, 35)
    loopToggle.BackgroundColor3 = Config.EnableLoop and Color3.fromRGB(60, 200, 60) or Color3.fromRGB(200, 60, 60)
    loopToggle.BorderSizePixel = 0
    loopToggle.Text = Config.EnableLoop and "ON" or "OFF"
    loopToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    loopToggle.TextSize = 12
    loopToggle.Font = Enum.Font.GothamBold
    loopToggle.Parent = settingsPanel
    
    -- Delay Slider
    local delayLabel = Instance.new("TextLabel")
    delayLabel.Size = UDim2.new(0.5, 0, 0, 20)
    delayLabel.Position = UDim2.new(0, 5, 0, 65)
    delayLabel.BackgroundTransparency = 1
    delayLabel.Text = "Delay: " .. Config.CollectDelay .. "s"
    delayLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    delayLabel.TextSize = 11
    delayLabel.TextXAlignment = Enum.TextXAlignment.Left
    delayLabel.Font = Enum.Font.Gotham
    delayLabel.Parent = settingsPanel
    
    local delaySlider = Instance.new("Frame")
    delaySlider.Name = "DelaySlider"
    delaySlider.Size = UDim2.new(0.4, 0, 0, 4)
    delaySlider.Position = UDim2.new(0.55, 0, 0, 73)
    delaySlider.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    delaySlider.BorderSizePixel = 0
    delaySlider.Parent = settingsPanel
    
    local delayFill = Instance.new("Frame")
    delayFill.Name = "DelayFill"
    delayFill.Size = UDim2.new(Config.CollectDelay / 0.5, 0, 1, 0)
    delayFill.BackgroundColor3 = Color3.fromRGB(60, 200, 200)
    delayFill.BorderSizePixel = 0
    delayFill.Parent = delaySlider
    
    -- Delay Button (Thay vì slider phức tạp)
    local delayBtn = Instance.new("TextButton")
    delayBtn.Size = UDim2.new(0, 30, 0, 20)
    delayBtn.Position = UDim2.new(0.9, 0, 0, 66)
    delayBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    delayBtn.BorderSizePixel = 0
    delayBtn.Text = "⏱"
    delayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    delayBtn.TextSize = 14
    delayBtn.Font = Enum.Font.Gotham
    delayBtn.Parent = settingsPanel
    
    -- Loop Interval
    local intervalLabel = Instance.new("TextLabel")
    intervalLabel.Size = UDim2.new(0.5, 0, 0, 20)
    intervalLabel.Position = UDim2.new(0, 5, 0, 95)
    intervalLabel.BackgroundTransparency = 1
    intervalLabel.Text = "Loop interval: " .. Config.LoopInterval .. "s"
    intervalLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    intervalLabel.TextSize = 11
    intervalLabel.TextXAlignment = Enum.TextXAlignment.Left
    intervalLabel.Font = Enum.Font.Gotham
    intervalLabel.Parent = settingsPanel
    
    local intervalBtn = Instance.new("TextButton")
    intervalBtn.Size = UDim2.new(0, 30, 0, 20)
    intervalBtn.Position = UDim2.new(0.9, 0, 0, 96)
    intervalBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    intervalBtn.BorderSizePixel = 0
    intervalBtn.Text = "⏱"
    intervalBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    intervalBtn.TextSize = 14
    intervalBtn.Font = Enum.Font.Gotham
    intervalBtn.Parent = settingsPanel
    
    -- Keybind
    local keybindLabel = Instance.new("TextLabel")
    keybindLabel.Size = UDim2.new(0.6, 0, 0, 20)
    keybindLabel.Position = UDim2.new(0, 5, 0, 120)
    keybindLabel.BackgroundTransparency = 1
    keybindLabel.Text = "Phím tắt: " .. tostring(Config.KeybindToggle)
    keybindLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    keybindLabel.TextSize = 11
    keybindLabel.TextXAlignment = Enum.TextXAlignment.Left
    keybindLabel.Font = Enum.Font.Gotham
    keybindLabel.Parent = settingsPanel
    
    -- Footer
    local footer = Instance.new("TextLabel")
    footer.Name = "Footer"
    footer.Size = UDim2.new(1, 0, 0, 20)
    footer.Position = UDim2.new(0, 0, 1, -25)
    footer.BackgroundTransparency = 1
    footer.Text = "Nhấn F để bật/tắt | Kéo để di chuyển"
    footer.TextColor3 = Color3.fromRGB(100, 100, 120)
    footer.TextSize = 10
    footer.Font = Enum.Font.Gotham
    footer.Parent = mainFrame
    
    -- ====== UI FUNCTIONS ======
    
    -- Update status
    local function updateStatus()
        local status = statusLabel
        local statusText = isRunning and "🟢 Đang chạy" or "🔴 Đã tạm dừng"
        status.Text = "Trạng thái: " .. statusText
        status.TextColor3 = isRunning and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
        
        statsLabel.Text = "Đã collect: " .. totalCollected .. " | Trashes: " .. trashCount
        toggleBtn.Text = isRunning and "⏸️ TẠM DỪNG" or "▶️ TIẾP TỤC"
        toggleBtn.BackgroundColor3 = isRunning and Color3.fromRGB(60, 200, 60) or Color3.fromRGB(200, 150, 60)
    end
    
    -- Update trash count
    local function updateTrashCount()
        local trashesFolder = Workspace:FindFirstChild("Scriptable")
        if trashesFolder then
            local trashes = trashesFolder:FindFirstChild("Trashes")
            if trashes then
                trashCount = #trashes:GetChildren()
            end
        end
        statsLabel.Text = "Đã collect: " .. totalCollected .. " | Trashes: " .. trashCount
    end
    
    -- Toggle auto collect
    local function toggleAutoCollect()
        isRunning = not isRunning
        updateStatus()
        
        if isRunning then
            log("🟢 ĐÃ BẬT auto collect")
            task.wait(0.5)
            collectAllTrashes()
        else
            log("🔴 ĐÃ TẮT auto collect")
        end
    end
    
    -- ====== BUTTON EVENTS ======
    
    toggleBtn.MouseButton1Click:Connect(toggleAutoCollect)
    
    collectBtn.MouseButton1Click:Connect(function()
        collectAllTrashes()
    end)
    
    settingsBtn.MouseButton1Click:Connect(function()
        settingsPanel.Visible = not settingsPanel.Visible
        local height = settingsPanel.Visible and 150 or 0
        content.Size = UDim2.new(1, -20, 1, -60 + height)
    end)
    
    autoNewToggle.MouseButton1Click:Connect(function()
        Config.AutoCollectNew = not Config.AutoCollectNew
        autoNewToggle.BackgroundColor3 = Config.AutoCollectNew and Color3.fromRGB(60, 200, 60) or Color3.fromRGB(200, 60, 60)
        autoNewToggle.Text = Config.AutoCollectNew and "ON" or "OFF"
        setupAutoCollect()
        log("🔄 Auto collect mới: " .. (Config.AutoCollectNew and "BẬT" or "TẮT"))
    end)
    
    loopToggle.MouseButton1Click:Connect(function()
        Config.EnableLoop = not Config.EnableLoop
        loopToggle.BackgroundColor3 = Config.EnableLoop and Color3.fromRGB(60, 200, 60) or Color3.fromRGB(200, 60, 60)
        loopToggle.Text = Config.EnableLoop and "ON" or "OFF"
        startLoop()
        log("🔄 Loop collect: " .. (Config.EnableLoop and "BẬT" or "TẮT"))
    end)
    
    -- Delay change
    local delayOptions = {0.05, 0.1, 0.2, 0.3, 0.5}
    local delayIndex = 2
    
    delayBtn.MouseButton1Click:Connect(function()
        delayIndex = delayIndex + 1
        if delayIndex > #delayOptions then delayIndex = 1 end
        Config.CollectDelay = delayOptions[delayIndex]
        delayLabel.Text = "Delay: " .. Config.CollectDelay .. "s"
        delayFill.Size = UDim2.new(Config.CollectDelay / 0.5, 0, 1, 0)
        log("⏱️ Đã đổi delay thành: " .. Config.CollectDelay .. "s")
    end)
    
    -- Interval change
    local intervalOptions = {2, 5, 10, 15, 30, 60}
    local intervalIndex = 2
    
    intervalBtn.MouseButton1Click:Connect(function()
        intervalIndex = intervalIndex + 1
        if intervalIndex > #intervalOptions then intervalIndex = 1 end
        Config.LoopInterval = intervalOptions[intervalIndex]
        intervalLabel.Text = "Loop interval: " .. Config.LoopInterval .. "s"
        startLoop()
        log("⏱️ Đã đổi loop interval thành: " .. Config.LoopInterval .. "s")
    end)
    
    return {
        UpdateStatus = updateStatus,
        UpdateTrashCount = updateTrashCount,
        Toggle = toggleAutoCollect
    }
end

-- ====== HÀM LOG ======
local function log(message, isWarning)
    if Config.ShowDebugLogs then
        if isWarning then
            warn(message)
        else
            print(message)
        end
    end
end

-- ====== HÀM COLLECT ======
function collectTrash(trashModel)
    if not isRunning then return end
    if not trashModel or not trashModel:IsA("Model") then return end
    
    local objectId = trashModel:GetAttribute("ObjectId") or trashModel.Name
    
    if objectId then
        local args = {"Destroy", objectId}
        trashEvent:FireServer(unpack(args))
        totalCollected = totalCollected + 1
        if ui then ui.UpdateTrashCount() end
        log("✅ Đã collect: " .. trashModel.Name)
    end
end

-- ====== COLLECT TẤT CẢ ======
function collectAllTrashes()
    if not isRunning then return end
    if isCollecting then 
        log("⚠️ Đang collect, vui lòng đợi...")
        return 
    end
    
    isCollecting = true
    
    local trashesFolder = Workspace:FindFirstChild("Scriptable")
    if not trashesFolder then
        log("❌ Không tìm thấy folder Scriptable", true)
        isCollecting = false
        return
    end
    
    local trashes = trashesFolder:FindFirstChild("Trashes")
    if not trashes then
        log("❌ Không tìm thấy folder Trashes", true)
        isCollecting = false
        return
    end
    
    local trashList = trashes:GetChildren()
    log("🔄 Đang collect " .. #trashList .. " trashes...")
    
    for _, trash in pairs(trashList) do
        if not isRunning then break end
        if trash:IsA("Model") then
            collectTrash(trash)
            task.wait(Config.CollectDelay)
        end
    end
    
    log("✅ Hoàn thành collect tất cả trashes!")
    if ui then ui.UpdateTrashCount() end
    isCollecting = false
end

-- ====== SETUP AUTO COLLECT ======
function setupAutoCollect()
    local trashesFolder = Workspace:FindFirstChild("Scriptable")
    if not trashesFolder then
        log("❌ Không tìm thấy folder Scriptable", true)
        return
    end
    
    local trashes = trashesFolder:FindFirstChild("Trashes")
    if not trashes then
        log("❌ Không tìm thấy folder Trashes", true)
        return
    end
    
    if childAddedConnection then
        childAddedConnection:Disconnect()
        childAddedConnection = nil
    end
    
    if Config.AutoCollectNew then
        childAddedConnection = trashes.ChildAdded:Connect(function(newTrash)
            if isRunning and Config.AutoCollectNew then
                task.wait(0.5)
                collectTrash(newTrash)
                if ui then ui.UpdateTrashCount() end
            end
        end)
        log("👀 Đã bật auto collect cho trash mới")
    end
    
    trashes.ChildRemoved:Connect(function(removedTrash)
        if ui then ui.UpdateTrashCount() end
        log("🗑️ Trash đã bị xóa: " .. (removedTrash.Name or "Unknown"))
    end)
end

-- ====== LOOP COLLECT ======
function startLoop()
    if loopConnection then
        loopConnection:Disconnect()
        loopConnection = nil
    end
    
    if Config.EnableLoop then
        loopConnection = game:GetService("RunService").Heartbeat:Connect(function()
            if isRunning then
                collectAllTrashes()
                task.wait(Config.LoopInterval)
            end
        end)
        log("🔄 Đã bật loop collect (mỗi " .. Config.LoopInterval .. " giây)")
    end
end

-- ====== PHÍM TẮT ======
function setupKeybind()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Config.KeybindToggle then
            if ui then ui.Toggle() end
        end
    end)
    log("⌨️ Phím tắt bật/tắt: " .. tostring(Config.KeybindToggle))
end

-- ====== HÀM CHÍNH ======
local ui = nil

local function main()
    if not player then
        log("❌ Không tìm thấy LocalPlayer", true)
        return
    end
    
    log("🚀 Bắt đầu auto collect trashes...")
    
    -- Tạo UI
    ui = createUI()
    log("✅ Đã tạo UI")
    
    -- Collect lần đầu
    task.wait(1)
    collectAllTrashes()
    
    -- Setup auto collect
    setupAutoCollect()
    
    -- Setup loop
    startLoop()
    
    -- Setup phím tắt
    setupKeybind()
    
    -- Update UI mỗi 2 giây
    game:GetService("RunService").Heartbeat:Connect(function()
        if ui and isRunning then
            ui.UpdateTrashCount()
        end
    end)
end

-- ====== CHẠY SCRIPT ======
main()

-- ====== EXPORT FUNCTIONS ======
_G.AutoCollect = {
    Enable = function()
        isRunning = true
        if ui then ui.UpdateStatus() end
        log("🟢 Đã bật auto collect")
        collectAllTrashes()
    end,
    
    Disable = function()
        isRunning = false
        if ui then ui.UpdateStatus() end
        log("🔴 Đã tắt auto collect")
    end,
    
    Toggle = function()
        if ui then ui.Toggle() end
    end,
    
    CollectNow = collectAllTrashes,
    
    GetStatus = function()
        return {
            Running = isRunning,
            Collecting = isCollecting,
            AutoCollectNew = Config.AutoCollectNew,
            LoopEnabled = Config.EnableLoop,
            Keybind = Config.KeybindToggle,
            Delay = Config.CollectDelay,
            LoopInterval = Config.LoopInterval,
            TotalCollected = totalCollected,
            TrashCount = trashCount
        }
    end
}

print("✅ Script đã sẵn sàng!")
print("📌 UI đã được tạo, nhấn F để bật/tắt")
print("📌 Kéo title bar để di chuyển UI")
print("📌 Nhấn ✕ để ẩn/hiện UI")