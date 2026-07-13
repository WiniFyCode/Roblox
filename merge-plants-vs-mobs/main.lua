local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(
    ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net")
)

-- States
local AutoBuy = false
local AutoMerge = false
local AutoHit = false
local ESPEnabled = false

-- ESP objects
local ESPFolder = nil
local ESPRefreshDelay = 1

-- Delays
local BuyDelay = 0.1
local MergeDelay = 0.5
local HitDelay = 0.01


local function ClearESP()
    -- Xoá toàn bộ ESP cũ để tránh bị trùng label khi bật lại.
    if ESPFolder then
        ESPFolder:Destroy()
        ESPFolder = nil
    end
end

local function CreateESPLabel(parent, text, color, size)
    -- Tạo BillboardGui hiển thị tên slot hoặc số cây trên object được chọn.
    local b = Instance.new("BillboardGui")
    b.Name = "PackFarmESP"
    b.Parent = ESPFolder
    b.Adornee = parent
    b.Size = size
    b.StudsOffset = Vector3.new(0, -1, 0)
    b.AlwaysOnTop = true

    local t = Instance.new("TextLabel")
    t.Parent = b
    t.Size = UDim2.new(1, 0, 1, 0)
    t.BackgroundTransparency = 1
    t.Text = text
    t.TextColor3 = color
    t.TextSize = 14
    t.Font = Enum.Font.GothamBold
    t.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    t.TextStrokeTransparency = 0.3
end

local function EnableESP()
    -- Quét toàn bộ plot rồi tạo ESP cho MergeSlot và Plant placement.
    ClearESP()

    local map = workspace:FindFirstChild("Map")
    local plots = map and map:FindFirstChild("Plots")

    if not plots then
        return
    end

    ESPFolder = Instance.new("Folder")
    ESPFolder.Name = "PackFarmESP"
    ESPFolder.Parent = workspace

    for _, plotData in pairs(plots:GetChildren()) do
        local functionals = plotData:FindFirstChild("Functionals")
        local interactibles = functionals and functionals:FindFirstChild("Interactibles")
        local mergeSlots = interactibles and interactibles:FindFirstChild("MergeSlots")

        if mergeSlots then
            for _, part in pairs(mergeSlots:GetChildren()) do
                -- Hiển thị tên MergeSlot như 1, 2, 3...
                CreateESPLabel(
                    part,
                    part.Name,
                    Color3.fromRGB(255, 100, 100),
                    UDim2.new(0, 60, 0, 25)
                )
            end
        end

        local plantArea = functionals and functionals:FindFirstChild("PlantArea")
        local plantPlacements = plantArea and plantArea:FindFirstChild("PlantPlacements")

        if plantPlacements then
            for _, child in pairs(plantPlacements:GetChildren()) do
                local row = child:FindFirstChild("Row")

                if row then
                    for _, part in pairs(row:GetChildren()) do
                        for _, subObj in pairs(part:GetChildren()) do
                            local plantNumber = subObj.Name:match("Plant_(%d+)")

                            if plantNumber then
                                -- Hiển thị số plant dạng P1, P2, P3...
                                CreateESPLabel(
                                    subObj,
                                    string.format("P%s", plantNumber),
                                    Color3.fromRGB(0, 255, 50),
                                    UDim2.new(0, 50, 0, 25)
                                )
                            end
                        end
                    end
                end
            end
        end
    end
end

local Window = Rayfield:CreateWindow({
    Name = "Pack Farm",
    LoadingTitle = "Pack Farm",
    LoadingSubtitle = "Auto System",
    ConfigurationSaving = {
        Enabled = false,
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = false,
})


local Main = Window:CreateTab("Main", 4483362458)
local Misc = Window:CreateTab("Misc", 4483362458)

-- Merge All Button
Main:CreateButton({
    Name = "🌱 Merge All",
    Callback = function()
        pcall(function()
            Net:FireServer("MergeAll")
        end)
    end,
})


-- Auto Merge
Main:CreateToggle({
    Name = "🌱 Auto Merge",
    CurrentValue = false,
    Flag = "AutoMerge",
    Callback = function(Value)

        AutoMerge = Value

        if Value then
            task.spawn(function()

                while AutoMerge do

                    pcall(function()
                        Net:FireServer("MergeAll")
                    end)

                    task.wait(MergeDelay)

                end

            end)
        end

    end,
})


Main:CreateSlider({
    Name = "Merge Delay",
    Range = {0.1, 2},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = MergeDelay,
    Flag = "MergeDelayNew",

    Callback = function(Value)
        MergeDelay = Value
    end,
})



-- Auto Buy Pack
Main:CreateToggle({
    Name = "📦 Auto Buy Pack",
    CurrentValue = false,
    Flag = "AutoBuy",

    Callback = function(Value)

        AutoBuy = Value

        if Value then

            task.spawn(function()

                while AutoBuy do

                    pcall(function()
                        Net:FireServer("BuyPack")
                    end)

                    task.wait(BuyDelay)

                end

            end)

        end

    end,
})


Main:CreateSlider({
    Name = "Buy Delay",
    Range = {0.01, 1},
    Increment = 0.01,
    Suffix = "s",
    CurrentValue = BuyDelay,
    Flag = "BuyDelayNew",

    Callback = function(Value)
        BuyDelay = Value
    end,
})



-- Auto Hit
Main:CreateToggle({
    Name = "⚔️ Auto Hit",
    CurrentValue = false,
    Flag = "AutoHit",

    Callback = function(Value)

        AutoHit = Value

        if Value then

            task.spawn(function()

                while AutoHit do

                    pcall(function()
                        Net:FireServer("SwordSwing")
                    end)

                    task.wait(HitDelay)

                end

            end)

        end

    end,
})


Main:CreateSlider({
    Name = "⚔️ Hit Delay",
    Range = {0.01, 1},
    Increment = 0.01,
    Suffix = "s",
    CurrentValue = HitDelay,
    Flag = "SwordHitDelay",

    Callback = function(Value)
        HitDelay = Value
    end,
})


-- ESP MergeSlot / Plants
Misc:CreateToggle({
    Name = "👁️ ESP Merge/Plants",
    CurrentValue = false,
    Flag = "ESPMergePlants",

    Callback = function(Value)
        ESPEnabled = Value

        if Value then
            print("ESP đã bật! (MergeSlot: 1, 2, 3...)")

            task.spawn(function()
                -- Làm mới ESP liên tục để cây mới/thay đổi vẫn hiện label.
                while ESPEnabled do
                    EnableESP()
                    task.wait(ESPRefreshDelay)
                end
            end)
        else
            ClearESP()
        end
    end,
})

-- Rejoin Server
Misc:CreateButton({
    Name = "🔄 Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(
            game.PlaceId,
            game:GetService("Players").LocalPlayer
        )
    end,
})


-- Set Speed
local SpeedValue = 16

Misc:CreateSlider({
    Name = "⚡ Walk Speed",
    Range = {16, 200},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = SpeedValue,
    Flag = "WalkSpeed",

    Callback = function(Value)
        SpeedValue = Value

        pcall(function()
            local Character = game.Players.LocalPlayer.Character
            local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

            if Humanoid then
                Humanoid.WalkSpeed = Value
            end
        end)
    end,
})


-- Apply lại khi respawn
game.Players.LocalPlayer.CharacterAdded:Connect(function(Character)

    task.wait(1)

    local Humanoid = Character:FindFirstChildOfClass("Humanoid")

    if Humanoid then
        Humanoid.WalkSpeed = SpeedValue
    end

end)

Rayfield:Notify({
    Title = "Pack Farm",
    Content = "Loaded successfully!",
    Duration = 5,
    Image = 4483362458,
})