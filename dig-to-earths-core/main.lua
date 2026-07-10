local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(
    ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net")
)

-- States
local AutoBuy = false
local AutoMerge = false
local AutoHit = false

-- Delays
local BuyDelay = 0.1
local MergeDelay = 0.5
local HitDelay = 0.01


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