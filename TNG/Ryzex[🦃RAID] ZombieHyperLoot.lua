-- Ｒ¥乙乇メ ⚡ Pro Aimbot + ESP (SPDM Team)

--// services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local EntityFolder = workspace:FindFirstChild("Entity")

--// gui parent
local guiParent = (gethui and gethui()) or game:GetService("CoreGui")
local accentColor = Color3.fromRGB(180, 110, 255)
local darkPurple = Color3.fromRGB(25, 10, 40)

--// config
local Config = {
    MenuKey = Enum.KeyCode.Insert,
    KeyString = "WAVE1337",
    Aimbot = {
        Enabled = true,
        HoldMouse2 = true,
        TeamCheck = false,
        AimPart = "Head",
        TargetMode = "Zombies", -- Zombies / Players / All
        Smoothness = 0.20,
        Prediction = 0.08,
        FOVEnabled = true,
        FOVRadius = 150
    },
    ESP = {
        Enabled = true,
        Boxes = true,
        Tracers = true,
        Names = true,
        Health = true
    },
    Visuals = {
        Crosshair = false
    }
}

--// key ui
local AccessGranted = false

local KeyGui = Instance.new("ScreenGui")
KeyGui.Name = "Ｒ¥乙乇メ_KeyUI"
KeyGui.ResetOnSpawn = false
KeyGui.Parent = guiParent

local KeyFrame = Instance.new("Frame")
KeyFrame.Size = UDim2.new(0, 380, 0, 200)
KeyFrame.Position = UDim2.new(0.5, -190, 0.5, -100)
KeyFrame.BackgroundColor3 = darkPurple
KeyFrame.BorderSizePixel = 0
KeyFrame.Parent = KeyGui

local kCorner = Instance.new("UICorner", KeyFrame)
kCorner.CornerRadius = UDim.new(0, 14)

local KeyTitle = Instance.new("TextLabel")
KeyTitle.BackgroundTransparency = 1
KeyTitle.Size = UDim2.new(1, -20, 0, 40)
KeyTitle.Position = UDim2.new(0, 10, 0, 10)
KeyTitle.Font = Enum.Font.GothamBold
KeyTitle.TextSize = 20
KeyTitle.TextColor3 = Color3.fromRGB(240, 230, 255)
KeyTitle.Text = "🔐 Ｒ¥乙乇メ Violet Aimbot"
KeyTitle.TextXAlignment = Enum.TextXAlignment.Left
KeyTitle.Parent = KeyFrame

local KeyDesc = Instance.new("TextLabel")
KeyDesc.BackgroundTransparency = 1
KeyDesc.Size = UDim2.new(1, -20, 0, 40)
KeyDesc.Position = UDim2.new(0, 10, 0, 50)
KeyDesc.Font = Enum.Font.Gotham
KeyDesc.TextSize = 14
KeyDesc.TextColor3 = Color3.fromRGB(210, 200, 240)
KeyDesc.TextWrapped = true
KeyDesc.TextXAlignment = Enum.TextXAlignment.Left
KeyDesc.Text = "Entre la key pour ouvrir le menu ✨"
KeyDesc.Parent = KeyFrame

local KeyBox = Instance.new("TextBox")
KeyBox.Size = UDim2.new(1, -40, 0, 36)
KeyBox.Position = UDim2.new(0, 20, 0, 100)
KeyBox.BackgroundColor3 = Color3.fromRGB(35, 18, 60)
KeyBox.BorderSizePixel = 0
KeyBox.Font = Enum.Font.GothamSemibold
KeyBox.PlaceholderText = "Key ici..."
KeyBox.Text = ""
KeyBox.TextSize = 16
KeyBox.TextColor3 = Color3.fromRGB(235, 225, 255)
KeyBox.Parent = KeyFrame
local kbc = Instance.new("UICorner", KeyBox)
kbc.CornerRadius = UDim.new(0, 10)

local KeyButton = Instance.new("TextButton")
KeyButton.Size = UDim2.new(0, 150, 0, 32)
KeyButton.Position = UDim2.new(0.5, -75, 0, 150)
KeyButton.BackgroundColor3 = accentColor
KeyButton.BorderSizePixel = 0
KeyButton.Font = Enum.Font.GothamBold
KeyButton.TextSize = 16
KeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyButton.Text = "Unlock 🔑"
KeyButton.Parent = KeyFrame
local kbtnc = Instance.new("UICorner", KeyButton)
kbtnc.CornerRadius = UDim.new(0, 10)

KeyButton.MouseButton1Click:Connect(function()
    if KeyBox.Text == Config.KeyString then
        AccessGranted = true
        TweenService:Create(KeyFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1
        }):Play()
        task.delay(0.35, function()
            KeyGui:Destroy()
        end)
    else
        KeyTitle.Text = "❌ Mauvaise key"
        KeyTitle.TextColor3 = Color3.fromRGB(255, 120, 120)
    end
end)

repeat task.wait() until AccessGranted

--// main gui
local MainGui = Instance.new("ScreenGui")
MainGui.Name = "Ｒ¥乙乇メ_ProAimbot"
MainGui.ResetOnSpawn = false
MainGui.Parent = guiParent

if syn and syn.protect_gui then
    pcall(function()
        syn.protect_gui(MainGui)
    end)
end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 650, 0, 380)
MainFrame.Position = UDim2.new(0.5, -325, 0.5, -190)
MainFrame.BackgroundColor3 = darkPurple
MainFrame.BorderSizePixel = 0
MainFrame.Parent = MainGui
local mfCorner = Instance.new("UICorner", MainFrame)
mfCorner.CornerRadius = UDim.new(0, 16)

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 34)
TopBar.BackgroundColor3 = Color3.fromRGB(35, 16, 60)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame
local tbCorner = Instance.new("UICorner", TopBar)
tbCorner.CornerRadius = UDim.new(0, 16)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.BackgroundTransparency = 1
TitleLabel.Size = UDim2.new(1, -140, 1, 0)
TitleLabel.Position = UDim2.new(0, 16, 0, 0)
TitleLabel.Text = "Ｒ¥乙乇メ 💜 Pro Aimbot & ESP"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 18
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.TextColor3 = Color3.fromRGB(240, 230, 255)
TitleLabel.Parent = TopBar

local SubLabel = Instance.new("TextLabel")
SubLabel.BackgroundTransparency = 1
SubLabel.Size = UDim2.new(0, 140, 1, 0)
SubLabel.Position = UDim2.new(1, -140, 0, 0)
SubLabel.Text = "SPDM Team ⚡"
SubLabel.Font = Enum.Font.GothamSemibold
SubLabel.TextSize = 14
SubLabel.TextXAlignment = Enum.TextXAlignment.Right
SubLabel.TextColor3 = Color3.fromRGB(210, 190, 235)
SubLabel.Parent = TopBar

do
    local dragging = false
    local dragStart
    local startPos

    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)

    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

local LeftBar = Instance.new("Frame")
LeftBar.Size = UDim2.new(0, 160, 1, -34)
LeftBar.Position = UDim2.new(0, 0, 0, 34)
LeftBar.BackgroundColor3 = Color3.fromRGB(20, 8, 35)
LeftBar.BorderSizePixel = 0
LeftBar.Parent = MainFrame

local lbCorner = Instance.new("UICorner", LeftBar)
lbCorner.CornerRadius = UDim.new(0, 16)

local NavHolder = Instance.new("Frame")
NavHolder.BackgroundTransparency = 1
NavHolder.Size = UDim2.new(1, 0, 1, -90)
NavHolder.Position = UDim2.new(0, 0, 0, 10)
NavHolder.Parent = LeftBar

local NavLayout = Instance.new("UIListLayout")
NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
NavLayout.Padding = UDim.new(0, 6)
NavLayout.Parent = NavHolder

local NameHolder = Instance.new("Frame")
NameHolder.BackgroundTransparency = 1
NameHolder.Size = UDim2.new(1, -20, 0, 70)
NameHolder.Position = UDim2.new(0, 10, 1, -80)
NameHolder.Parent = LeftBar

local Avatar = Instance.new("ImageLabel")
Avatar.Size = UDim2.new(0, 60, 0, 60)
Avatar.Position = UDim2.new(0, 0, 0, 5)
Avatar.BackgroundColor3 = Color3.fromRGB(40, 20, 70)
Avatar.BorderSizePixel = 0
Avatar.Parent = NameHolder
local avCorner = Instance.new("UICorner", Avatar)
avCorner.CornerRadius = UDim.new(1, 0)

local NameLabel = Instance.new("TextLabel")
NameLabel.BackgroundTransparency = 1
NameLabel.Size = UDim2.new(1, -70, 0, 24)
NameLabel.Position = UDim2.new(0, 70, 0, 8)
NameLabel.Font = Enum.Font.GothamBold
NameLabel.TextSize = 14
NameLabel.TextXAlignment = Enum.TextXAlignment.Left
NameLabel.TextColor3 = Color3.fromRGB(240, 230, 255)
NameLabel.Text = LocalPlayer.DisplayName .. " 😈"
NameLabel.Parent = NameHolder

local UserLabel = Instance.new("TextLabel")
UserLabel.BackgroundTransparency = 1
UserLabel.Size = UDim2.new(1, -70, 0, 20)
UserLabel.Position = UDim2.new(0, 70, 0, 32)
UserLabel.Font = Enum.Font.Gotham
UserLabel.TextSize = 13
UserLabel.TextXAlignment = Enum.TextXAlignment.Left
UserLabel.TextColor3 = Color3.fromRGB(210, 200, 240)
UserLabel.Text = "@" .. LocalPlayer.Name
UserLabel.Parent = NameHolder

pcall(function()
    local thumb, ready = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    if ready then
        Avatar.Image = thumb
    end
end)

local PagesHolder = Instance.new("Frame")
PagesHolder.Size = UDim2.new(1, -170, 1, -44)
PagesHolder.Position = UDim2.new(0, 170, 0, 44)
PagesHolder.BackgroundTransparency = 1
PagesHolder.Parent = MainFrame

local Pages = {}

local function createPage(name)
    local f = Instance.new("Frame")
    f.Name = name
    f.Size = UDim2.new(1, 0, 1, 0)
    f.BackgroundColor3 = Color3.fromRGB(30, 12, 50)
    f.BorderSizePixel = 0
    f.Visible = false
    f.Parent = PagesHolder
    local c = Instance.new("UICorner", f)
    c.CornerRadius = UDim.new(0, 12)

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 8)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = f

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.Parent = f

    Pages[name] = f
    return f
end

local function showPage(name)
    for n, f in pairs(Pages) do
        f.Visible = (n == name)
    end
end

local function createNavButton(text, emoji, pageName, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(35, 15, 55)
    btn.BorderSizePixel = 0
    btn.Text = emoji .. "  " .. text
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(220, 210, 245)
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = NavHolder
    btn.LayoutOrder = order or 1
    local c = Instance.new("UICorner", btn)
    c.CornerRadius = UDim.new(0, 10)

    btn.MouseButton1Click:Connect(function()
        showPage(pageName)
        for _, other in ipairs(NavHolder:GetChildren()) do
            if other:IsA("TextButton") then
                other.BackgroundColor3 = Color3.fromRGB(35, 15, 55)
            end
        end
        btn.BackgroundColor3 = accentColor
    end)
end

local function createToggle(parent, text, default, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -10, 0, 30)
    holder.BackgroundTransparency = 1
    holder.Parent = parent

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -80, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(235, 225, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = text
    label.Parent = holder

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 60, 0, 24)
    button.Position = UDim2.new(1, -70, 0.5, -12)
    button.BackgroundColor3 = default and accentColor or Color3.fromRGB(55, 30, 80)
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamBold
    button.TextSize = 12
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = default and "ON" or "OFF"
    button.AutoButtonColor = false
    button.Parent = holder
    local c = Instance.new("UICorner", button)
    c.CornerRadius = UDim.new(0, 12)

    local state = default

    local function setState(v)
        state = v
        button.Text = state and "ON" or "OFF"
        button.BackgroundColor3 = state and accentColor or Color3.fromRGB(55, 30, 80)
        if callback then
            callback(state)
        end
    end

    button.MouseButton1Click:Connect(function()
        setState(not state)
    end)

    setState(default)
    return setState
end

local function createSlider(parent, text, min, max, default, decimals, callback)
    decimals = decimals or 0
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -10, 0, 40)
    holder.BackgroundTransparency = 1
    holder.Parent = parent

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0.5, 0, 0, 18)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(235, 225, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = text
    label.Parent = holder

    local valueLabel = Instance.new("TextLabel")
    valueLabel.BackgroundTransparency = 1
    valueLabel.Size = UDim2.new(0.5, 0, 0, 18)
    valueLabel.Position = UDim2.new(0.5, 0, 0, 0)
    valueLabel.Font = Enum.Font.Gotham
    valueLabel.TextSize = 13
    valueLabel.TextColor3 = Color3.fromRGB(210, 200, 240)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = holder

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -10, 0, 8)
    bar.Position = UDim2.new(0, 0, 0, 24)
    bar.BackgroundColor3 = Color3.fromRGB(55, 30, 80)
    bar.BorderSizePixel = 0
    bar.Parent = holder
    local bc = Instance.new("UICorner", bar)
    bc.CornerRadius = UDim.new(0, 6)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = accentColor
    fill.BorderSizePixel = 0
    fill.Parent = bar
    local fc = Instance.new("UICorner", fill)
    fc.CornerRadius = UDim.new(0, 6)

    local sliding = false
    local value = default

    local function formatVal(v)
        local mult = 10 ^ decimals
        return math.floor(v * mult + 0.5) / mult
    end

    local function updateFromX(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        value = min + (max - min) * rel
        value = formatVal(value)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        valueLabel.Text = tostring(value)
        if callback then
            callback(value)
        end
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true
            updateFromX(input.Position.X)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromX(input.Position.X)
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = false
        end
    end)

    valueLabel.Text = tostring(formatVal(default))
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    if callback then
        callback(default)
    end
end

local MainPage = createPage("Main")
local AimbotPage = createPage("Aimbot")
local ESPPage = createPage("ESP")
local VisualPage = createPage("Visuals")
local MiscPage = createPage("Misc")

createNavButton("Home", "🏠", "Main", 1)
createNavButton("Aimbot", "🎯", "Aimbot", 2)
createNavButton("ESP", "👁️", "ESP", 3)
createNavButton("Visuals", "🎨", "Visuals", 4)
createNavButton("Divers", "⚙️", "Misc", 5)

showPage("Aimbot")

do
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Size = UDim2.new(1, -20, 0, 50)
    t.Font = Enum.Font.GothamBold
    t.TextSize = 20
    t.TextColor3 = Color3.fromRGB(240, 230, 255)
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextYAlignment = Enum.TextYAlignment.Top
    t.TextWrapped = true
    t.Text = "Bienvenue dans Ｒ¥乙乇メ 💜\nAimbot + ESP complet, touche INSERT pour afficher / cacher."
    t.Parent = MainPage
end

createToggle(AimbotPage, "🎯 Aimbot Enabled", Config.Aimbot.Enabled, function(v)
    Config.Aimbot.Enabled = v
end)

createToggle(AimbotPage, "🖱️ Clique droit pour viser", Config.Aimbot.HoldMouse2, function(v)
    Config.Aimbot.HoldMouse2 = v
end)

createToggle(AimbotPage, "🤝 Team check (players)", Config.Aimbot.TeamCheck, function(v)
    Config.Aimbot.TeamCheck = v
end)

do
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -10, 0, 30)
    holder.BackgroundTransparency = 1
    holder.Parent = AimbotPage

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(235, 225, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = "🎯 Aim Part"
    label.Parent = holder

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 120, 0, 24)
    btn.Position = UDim2.new(1, -130, 0.5, -12)
    btn.BackgroundColor3 = Color3.fromRGB(55, 30, 80)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(235, 225, 255)
    btn.Text = "Head"
    btn.Parent = holder
    local c = Instance.new("UICorner", btn)
    c.CornerRadius = UDim.new(0, 10)

    local parts = {"Head", "UpperTorso", "HumanoidRootPart"}
    local index = 1
    Config.Aimbot.AimPart = parts[index]

    btn.MouseButton1Click:Connect(function()
        index = index + 1
        if index > #parts then
            index = 1
        end
        Config.Aimbot.AimPart = parts[index]
        btn.Text = parts[index]
    end)
end

do
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -10, 0, 30)
    holder.BackgroundTransparency = 1
    holder.Parent = AimbotPage

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(235, 225, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = "👾 Target"
    label.Parent = holder

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 120, 0, 24)
    btn.Position = UDim2.new(1, -130, 0.5, -12)
    btn.BackgroundColor3 = Color3.fromRGB(55, 30, 80)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(235, 225, 255)
    btn.Text = "Zombies (Entity)"
    btn.Parent = holder
    local c = Instance.new("UICorner", btn)
    c.CornerRadius = UDim.new(0, 10)

    local modes = {"Zombies", "Players", "All"}
    local names = {
        Zombies = "Zombies (Entity)",
        Players = "Joueurs",
        All = "Tous"
    }
    local idx = 1
    Config.Aimbot.TargetMode = modes[idx]

    btn.MouseButton1Click:Connect(function()
        idx = idx + 1
        if idx > #modes then idx = 1 end
        Config.Aimbot.TargetMode = modes[idx]
        btn.Text = names[modes[idx]]
    end)
end

createToggle(AimbotPage, "📸 FOV Enabled", Config.Aimbot.FOVEnabled, function(v)
    Config.Aimbot.FOVEnabled = v
end)

createSlider(AimbotPage, "📏 FOV Radius", 40, 400, Config.Aimbot.FOVRadius, 0, function(v)
    Config.Aimbot.FOVRadius = v
end)

createSlider(AimbotPage, "🐍 Smoothness", 0, 1, Config.Aimbot.Smoothness, 2, function(v)
    Config.Aimbot.Smoothness = v
end)

createSlider(AimbotPage, "🔮 Prediction", 0, 0.3, Config.Aimbot.Prediction, 2, function(v)
    Config.Aimbot.Prediction = v
end)

createToggle(ESPPage, "👁️ ESP Enabled", Config.ESP.Enabled, function(v)
    Config.ESP.Enabled = v
end)
createToggle(ESPPage, "📦 Boxes", Config.ESP.Boxes, function(v)
    Config.ESP.Boxes = v
end)
createToggle(ESPPage, "📍 Tracers", Config.ESP.Tracers, function(v)
    Config.ESP.Tracers = v
end)
createToggle(ESPPage, "🏷️ Names", Config.ESP.Names, function(v)
    Config.ESP.Names = v
end)
createToggle(ESPPage, "❤️ Health bar", Config.ESP.Health, function(v)
    Config.ESP.Health = v
end)

createToggle(VisualPage, "➕ Crosshair", Config.Visuals.Crosshair, function(v)
    Config.Visuals.Crosshair = v
end)

local hint = Instance.new("TextLabel")
hint.BackgroundTransparency = 1
hint.Size = UDim2.new(1, -20, 0, 50)
hint.Font = Enum.Font.Gotham
hint.TextSize = 14
hint.TextColor3 = Color3.fromRGB(210, 200, 240)
hint.TextWrapped = true
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.TextYAlignment = Enum.TextYAlignment.Top
hint.Text = "💡 Conseil : combine FOV + Smooth pour un aimbot clean."
hint.Parent = VisualPage

do
    local info = Instance.new("TextLabel")
    info.BackgroundTransparency = 1
    info.Size = UDim2.new(1, -20, 0, 60)
    info.Font = Enum.Font.Gotham
    info.TextSize = 14
    info.TextColor3 = Color3.fromRGB(210, 200, 240)
    info.TextWrapped = true
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.TextYAlignment = Enum.TextYAlignment.Top
    info.Text = "Touche Insert ⌨️ pour afficher/cacher le menu.\nClique droit pour lock aimbot (configurable)."
    info.Parent = MiscPage

    local unload = Instance.new("TextButton")
    unload.Size = UDim2.new(0, 150, 0, 30)
    unload.Position = UDim2.new(0, 0, 0, 70)
    unload.BackgroundColor3 = Color3.fromRGB(140, 50, 80)
    unload.BorderSizePixel = 0
    unload.Font = Enum.Font.GothamBold
    unload.TextSize = 14
    unload.TextColor3 = Color3.fromRGB(255, 255, 255)
    unload.Text = "Unload script 🧹"
    unload.Parent = MiscPage
    local uc = Instance.new("UICorner", unload)
    uc.CornerRadius = UDim.new(0, 10)

    unload.MouseButton1Click:Connect(function()
        MainGui:Destroy()
    end)
end

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Config.MenuKey then
        MainGui.Enabled = not MainGui.Enabled
    end
end)

------------------------------------------------------------------
-- ESP + AIMBOT
------------------------------------------------------------------

local hasDrawing = false
do
    local ok, obj = pcall(function()
        return Drawing.new("Line")
    end)
    if ok and obj then
        hasDrawing = true
        obj:Remove()
    end
end

local FOVCircle
local CrosshairLines = {}
local ESPObjects = {}

if hasDrawing then
    local ok, obj = pcall(function()
        return Drawing.new("Circle")
    end)
    if ok and obj then
        FOVCircle = obj
        FOVCircle.NumSides = 64
        FOVCircle.Thickness = 1.5
        FOVCircle.Filled = false
        FOVCircle.Color = accentColor
        FOVCircle.Visible = true
    end

    for i = 1, 4 do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Thickness = 1.5
        line.Color = Color3.fromRGB(255, 255, 255)
        CrosshairLines[i] = line
    end
end

local function newDrawing(t, props)
    local o = Drawing.new(t)
    for k, v in pairs(props) do
        o[k] = v
    end
    return o
end

local function createESPElements()
    return {
        Box       = newDrawing("Square", {Visible = false, Thickness = 2, Filled = false, Color = accentColor}),
        Name      = newDrawing("Text",   {Visible = false, Center = true, Outline = true, Size = 14, Font = 2, Color = Color3.new(1,1,1)}),
        Tracer    = newDrawing("Line",   {Visible = false, Thickness = 1, Color = accentColor}),
        HealthBar = newDrawing("Line",   {Visible = false, Thickness = 3, Color = Color3.new(0,1,0)})
    }
end

local function getBoxScreenPoints(cf, size)
    local half = size / 2
    local points = {}
    local visible = true

    for x = -1, 1, 2 do
        for y = -1, 1, 2 do
            for z = -1, 1, 2 do
                local corner = cf * Vector3.new(half.X * x, half.Y * y, half.Z * z)
                local screenPos, onScreen = Camera:WorldToViewportPoint(corner)
                if not onScreen then
                    visible = false
                end
                table.insert(points, Vector2.new(screenPos.X, screenPos.Y))
            end
        end
    end

    return points, visible
end

local function hideAll(data)
    if not data then return end
    data.Box.Visible = false
    data.Name.Visible = false
    data.Tracer.Visible = false
    data.HealthBar.Visible = false
end

local function drawESP(key, cf, size, humanoid, label)
    if not hasDrawing then return end

    local points, visible = getBoxScreenPoints(cf, size)
    if not visible or #points == 0 then
        hideAll(ESPObjects[key])
        return
    end

    local data = ESPObjects[key]
    if not data then
        data = createESPElements()
        ESPObjects[key] = data
    end

    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    for _, pt in ipairs(points) do
        minX = math.min(minX, pt.X)
        minY = math.min(minY, pt.Y)
        maxX = math.max(maxX, pt.X)
        maxY = math.max(maxY, pt.Y)
    end

    local boxWidth, boxHeight = maxX - minX, maxY - minY
    if boxWidth <= 3 or boxHeight <= 4 then
        hideAll(data)
        return
    end

    local slimWidth = boxWidth * 0.7
    local slimX = minX + (boxWidth - slimWidth) / 2
    local baseColor = accentColor
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)

    local hp    = humanoid and humanoid.Health or 0
    local maxHp = humanoid and humanoid.MaxHealth or 100
    local ratio = math.clamp(maxHp > 0 and hp / maxHp or 0, 0, 1)

    if Config.ESP.Boxes then
        data.Box.Visible  = true
        data.Box.Position = Vector2.new(slimX, minY)
        data.Box.Size     = Vector2.new(slimWidth, boxHeight)
        data.Box.Color    = baseColor
    else
        data.Box.Visible = false
    end

    if Config.ESP.Names then
        data.Name.Visible  = true
        data.Name.Text     = string.format("%s [%d]", label, math.floor(hp))
        data.Name.Position = Vector2.new(slimX + slimWidth / 2, minY - 18)
        data.Name.Color    = baseColor
    else
        data.Name.Visible = false
    end

    if Config.ESP.Tracers then
        data.Tracer.Visible = true
        data.Tracer.From    = screenCenter
        data.Tracer.To      = Vector2.new(slimX + slimWidth / 2, maxY)
        data.Tracer.Color   = baseColor
    else
        data.Tracer.Visible = false
    end

    if Config.ESP.Health then
        local barHeight = boxHeight * ratio
        data.HealthBar.Visible = true
        data.HealthBar.From = Vector2.new(slimX - 5, maxY)
        data.HealthBar.To   = Vector2.new(slimX - 5, maxY - barHeight)
        data.HealthBar.Color = Color3.fromRGB((1 - ratio) * 255, ratio * 255, 0)
    else
        data.HealthBar.Visible = false
    end
end

-- aimbot helpers
local function getTargets()
    local t = {}

    if Config.Aimbot.TargetMode == "Players" or Config.Aimbot.TargetMode == "All" then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hum = plr.Character:FindFirstChildWhichIsA("Humanoid")
                if hum and hum.Health > 0 then
                    if not Config.Aimbot.TeamCheck or plr.Team ~= LocalPlayer.Team then
                        table.insert(t, plr.Character)
                    end
                end
            end
        end
    end

    if EntityFolder and (Config.Aimbot.TargetMode == "Zombies" or Config.Aimbot.TargetMode == "All") then
        for _, m in ipairs(EntityFolder:GetChildren()) do
            if m:IsA("Model") then
                local hum = m:FindFirstChildWhichIsA("Humanoid")
                if hum and hum.Health > 0 then
                    table.insert(t, m)
                end
            end
        end
    end

    return t
end

local function getClosestTarget()
    local mousePos = UIS:GetMouseLocation()
    local closestChar, closestPart
    local closestDist = math.huge

    for _, char in ipairs(getTargets()) do
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        if hum and hum.Health > 0 then
            local part = char:FindFirstChild(Config.Aimbot.AimPart)
            if not part then
                part = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
            end
            if part then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen and screenPos.Z > 0 then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if (not Config.Aimbot.FOVEnabled) or dist <= Config.Aimbot.FOVRadius then
                        if dist < closestDist then
                            closestDist = dist
                            closestChar = char
                            closestPart = part
                        end
                    end
                end
            end
        end
    end

    return closestChar, closestPart
end

local holdingMouse2 = false

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        holdingMouse2 = true
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        holdingMouse2 = false
    end
end)

RunService.RenderStepped:Connect(function()
    local mousePos = UIS:GetMouseLocation()
    local viewport = Camera.ViewportSize

    -- FOV
    if FOVCircle then
        FOVCircle.Position = mousePos
        FOVCircle.Radius   = Config.Aimbot.FOVRadius
        FOVCircle.Color    = accentColor
        FOVCircle.Visible  = Config.Aimbot.FOVEnabled
    end

    -- crosshair
    if #CrosshairLines > 0 then
        local size = 6
        local cx, cy = mousePos.X, mousePos.Y
        for _, l in ipairs(CrosshairLines) do
            l.Visible = Config.Visuals.Crosshair
        end
        if Config.Visuals.Crosshair then
            CrosshairLines[1].From = Vector2.new(cx - size, cy)
            CrosshairLines[1].To   = Vector2.new(cx - 1,   cy)
            CrosshairLines[2].From = Vector2.new(cx + 1,   cy)
            CrosshairLines[2].To   = Vector2.new(cx + size,cy)
            CrosshairLines[3].From = Vector2.new(cx, cy - size)
            CrosshairLines[3].To   = Vector2.new(cx, cy - 1)
            CrosshairLines[4].From = Vector2.new(cx, cy + 1)
            CrosshairLines[4].To   = Vector2.new(cx, cy + size)
        end
    end

    -- ESP
    if hasDrawing and Config.ESP.Enabled then
        local seen = {}

        -- players
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local char = plr.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if char and hum and hum.Health > 0 then
                    local ok, cf, size = pcall(char.GetBoundingBox, char)
                    if ok and cf and size then
                        drawESP(plr, cf, size, hum, plr.Name)
                        seen[plr] = true
                    end
                end
            end
        end

        -- zombies
        if EntityFolder then
            for _, m in ipairs(EntityFolder:GetChildren()) do
                if m:IsA("Model") then
                    local hum = m:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local ok, cf, size = pcall(m.GetBoundingBox, m)
                        if ok and cf and size then
                            drawESP(m, cf, size, hum, m.Name)
                            seen[m] = true
                        end
                    end
                end
            end
        end

        for key, data in pairs(ESPObjects) do
            if not seen[key] then
                hideAll(data)
            end
        end
    else
        for _, data in pairs(ESPObjects) do
            hideAll(data)
        end
    end

    -- Aimbot
    if Config.Aimbot.Enabled then
        local active = true
        if Config.Aimbot.HoldMouse2 and not holdingMouse2 then
            active = false
        end

        if active then
            local char, part = getClosestTarget()
            if char and part then
                local targetPos = part.Position
                if Config.Aimbot.Prediction > 0 then
                    local vel = part.AssemblyLinearVelocity or part.Velocity
                    targetPos = targetPos + (vel * Config.Aimbot.Prediction)
                end
                local cf = Camera.CFrame
                local desired = CFrame.new(cf.Position, targetPos)
                if Config.Aimbot.Smoothness > 0 then
                    Camera.CFrame = cf:Lerp(desired, Config.Aimbot.Smoothness)
                else
                    Camera.CFrame = desired
                end
            end
        end
    end
end)
