--[[
    Loader Module - Zombie Hyperloot (Obsidian UI Style)
    Modern, Dark, and Clean Loading Screen
]]

local Loader = {}
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

Loader.ScreenGui = nil
Loader.MainFrame = nil
Loader.BarFill = nil
Loader.StatusLabel = nil
Loader.PercentageLabel = nil

function Loader.start()
    -- Cleanup
    if CoreGui:FindFirstChild("ZombieHyperlootLoader") then
        CoreGui.ZombieHyperlootLoader:Destroy()
    end

    -- Create ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ZombieHyperlootLoader"
    ScreenGui.Parent = CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.IgnoreGuiInset = true -- Full screen coverage if needed
    Loader.ScreenGui = ScreenGui

    -- Colors (Obsidian Style)
    local Colors = {
        Background = Color3.fromRGB(18, 18, 18), -- Darker background
        Accent = Color3.fromRGB(255, 60, 60),    -- Red accent (matching Zombie theme) or user preference
        Text = Color3.fromRGB(240, 240, 240),
        SubText = Color3.fromRGB(160, 160, 160),
        BarBg = Color3.fromRGB(30, 30, 30),
        Border = Color3.fromRGB(45, 45, 45)
    }

    -- Main Container
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Colors.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.5, -175, 0.5, -90) -- Slightly larger
    MainFrame.Size = UDim2.new(0, 350, 0, 180)
    MainFrame.ClipsDescendants = true

    -- Stroke (Subtle Border)
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Parent = MainFrame
    UIStroke.Color = Colors.Border
    UIStroke.Thickness = 1
    
    -- Top Bar (Visual Header)
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Parent = MainFrame
    TopBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TopBar.BackgroundTransparency = 0.95
    TopBar.BorderSizePixel = 0
    TopBar.Size = UDim2.new(1, 0, 0, 40)
    
    -- Title Text (Moved to TopBar)
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Parent = TopBar -- Parented to TopBar
    Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Title.BackgroundTransparency = 1.000
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.Size = UDim2.new(1, -30, 1, 0)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "ZOMBIE HYPERLOOT"
    Title.TextColor3 = Colors.Text
    Title.TextSize = 16.000 -- Smaller size for header
    Title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Subtitle (Moved up)
    local Subtitle = Instance.new("TextLabel")
    Subtitle.Name = "Subtitle"
    Subtitle.Parent = MainFrame
    Subtitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Subtitle.BackgroundTransparency = 1.000
    Subtitle.Position = UDim2.new(0, 20, 0, 55) -- Adjusted position
    Subtitle.Size = UDim2.new(1, -40, 0, 20)
    Subtitle.Font = Enum.Font.Gotham
    Subtitle.Text = "Premium Script Hub | Developed by WiniFy | I have stopped updating this script."
    Subtitle.TextColor3 = Colors.SubText
    Subtitle.TextSize = 13.000 -- Slightly larger
    Subtitle.TextXAlignment = Enum.TextXAlignment.Left

    -- Loading Bar Container
    local BarBg = Instance.new("Frame")
    BarBg.Name = "BarBg"
    BarBg.Parent = MainFrame
    BarBg.BackgroundColor3 = Colors.BarBg
    BarBg.BorderSizePixel = 0
    BarBg.Position = UDim2.new(0, 20, 0, 125)
    BarBg.Size = UDim2.new(1, -40, 0, 4) -- Thinner, sleeker bar

    -- Loading Bar Fill
    local BarFill = Instance.new("Frame")
    BarFill.Name = "BarFill"
    BarFill.Parent = BarBg
    BarFill.BackgroundColor3 = Colors.Accent
    BarFill.BorderSizePixel = 0
    BarFill.Size = UDim2.new(0, 0, 1, 0)
    
    -- Subtle Glow on Bar
    local BarGlow = Instance.new("ImageLabel")
    BarGlow.Name = "BarGlow"
    BarGlow.Parent = BarFill
    BarGlow.BackgroundTransparency = 1
    BarGlow.Image = "rbxassetid://9291399385" -- Soft glow texture
    BarGlow.ImageColor3 = Colors.Accent
    BarGlow.ImageTransparency = 0.5
    BarGlow.Position = UDim2.new(0, -15, 0.5, -15)
    BarGlow.Size = UDim2.new(1, 30, 0, 30)
    BarGlow.ScaleType = Enum.ScaleType.Slice
    BarGlow.SliceCenter = Rect.new(15, 15, 115, 115)

    Loader.BarFill = BarFill

    -- Status Label (Bottom Left)
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Name = "StatusLabel"
    StatusLabel.Parent = MainFrame
    StatusLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    StatusLabel.BackgroundTransparency = 1.000
    StatusLabel.Position = UDim2.new(0, 20, 0, 135)
    StatusLabel.Size = UDim2.new(0.7, 0, 0, 20)
    StatusLabel.Font = Enum.Font.GothamMedium
    StatusLabel.Text = "Initializing..."
    StatusLabel.TextColor3 = Colors.SubText
    StatusLabel.TextSize = 11.000
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    Loader.StatusLabel = StatusLabel
    
    -- Percentage Label (Bottom Right)
    local PercentageLabel = Instance.new("TextLabel")
    PercentageLabel.Name = "PercentageLabel"
    PercentageLabel.Parent = MainFrame
    PercentageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    PercentageLabel.BackgroundTransparency = 1.000
    PercentageLabel.Position = UDim2.new(1, -70, 0, 135)
    PercentageLabel.Size = UDim2.new(0, 50, 0, 20)
    PercentageLabel.Font = Enum.Font.GothamBold
    PercentageLabel.Text = "0%"
    PercentageLabel.TextColor3 = Colors.Text
    PercentageLabel.TextSize = 11.000
    PercentageLabel.TextXAlignment = Enum.TextXAlignment.Right
    Loader.PercentageLabel = PercentageLabel

    Loader.MainFrame = MainFrame
    
    -- Intro Animation (Fade In + Slide Up)
    MainFrame.BackgroundTransparency = 1
    UIStroke.Transparency = 1
    Title.TextTransparency = 1
    Subtitle.TextTransparency = 1
    BarBg.BackgroundTransparency = 1
    StatusLabel.TextTransparency = 1
    PercentageLabel.TextTransparency = 1
    
    -- Initial Offset
    MainFrame.Position = UDim2.new(0.5, -175, 0.5, -70)
    
    local info = TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    
    TweenService:Create(MainFrame, info, {Position = UDim2.new(0.5, -175, 0.5, -90), BackgroundTransparency = 0.05}):Play() -- Slight transparency for glass effect
    TweenService:Create(UIStroke, info, {Transparency = 0.8}):Play()
    TweenService:Create(Title, info, {TextTransparency = 0}):Play()
    TweenService:Create(Subtitle, info, {TextTransparency = 0}):Play()
    TweenService:Create(BarBg, info, {BackgroundTransparency = 0}):Play()
    TweenService:Create(StatusLabel, info, {TextTransparency = 0}):Play()
    TweenService:Create(PercentageLabel, info, {TextTransparency = 0}):Play()
    
    task.wait(0.5)
end

function Loader.update(percent, status)
    if not Loader.ScreenGui then return end
    
    -- Clamping percent between 0 and 1
    percent = math.clamp(percent, 0, 1)
    
    -- Tween Bar
    local info = TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
    if Loader.BarFill then
        TweenService:Create(Loader.BarFill, info, {Size = UDim2.new(percent, 0, 1, 0)}):Play()
    end
    
    -- Update Text
    if Loader.StatusLabel then
        Loader.StatusLabel.Text = status or "Loading..."
    end
    
    if Loader.PercentageLabel then
        Loader.PercentageLabel.Text = math.floor(percent * 100) .. "%"
    end
end

function Loader.stop()
    if not Loader.ScreenGui then return end
    
    -- Success Status
    Loader.update(1, "Successfully Loaded")
    
    if Loader.BarFill then
        local BarGlow = Loader.BarFill:FindFirstChild("BarGlow")
        if BarGlow then
            TweenService:Create(BarGlow, TweenInfo.new(0.5), {ImageColor3 = Color3.fromRGB(100, 255, 100)}):Play()
        end
        TweenService:Create(Loader.BarFill, TweenInfo.new(0.5), {BackgroundColor3 = Color3.fromRGB(100, 255, 100)}):Play()
    end
    
    task.wait(1.0) -- Wait a bit longer to show success
    
    -- Out Animation (Scale Down + Fade Out)
    local info = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    if Loader.MainFrame then
        TweenService:Create(Loader.MainFrame, info, {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}):Play()
        -- Fade out contents
        for _, child in pairs(Loader.MainFrame:GetDescendants()) do
    if child:IsA("UIStroke") then
        TweenService:Create(child, TweenInfo.new(0.3), {
            Transparency = 1
        }):Play()

    elseif child:IsA("TextLabel") then
        TweenService:Create(child, TweenInfo.new(0.3), {
            TextTransparency = 1,
            BackgroundTransparency = 1
        }):Play()

    elseif child:IsA("ImageLabel") then
        TweenService:Create(child, TweenInfo.new(0.3), {
            ImageTransparency = 1,
            BackgroundTransparency = 1
        }):Play()

    elseif child:IsA("Frame") then
        TweenService:Create(child, TweenInfo.new(0.3), {
            BackgroundTransparency = 1
        }):Play()
    end
end
    end
    
    task.wait(0.6)
    if Loader.ScreenGui then
        Loader.ScreenGui:Destroy()
        Loader.ScreenGui = nil
    end
end

return Loader
