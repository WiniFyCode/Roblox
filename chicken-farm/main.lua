_G.AutoCollectEggs = true

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

local Character = Player.Character or Player.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")

Player.CharacterAdded:Connect(function(char)
    Character = char
    HRP = char:WaitForChild("HumanoidRootPart")
end)

local RemoteFunction = ReplicatedStorage
    :WaitForChild("Paper")
    :WaitForChild("Remotes")
    :WaitForChild("__remotefunction")

task.spawn(function()
    while _G.AutoCollectEggs do
        local collected = false
        local EggsFolder = workspace:FindFirstChild("Eggs")

        if EggsFolder and HRP then
            for _, Egg in ipairs(EggsFolder:GetChildren()) do
                if not _G.AutoCollectEggs then
                    break
                end

                local Part = Egg:FindFirstChild("Part")

                if Part then
                    pcall(function()
                        firetouchinterest(HRP, Part, 0)
                        task.wait()
                        firetouchinterest(HRP, Part, 1)
                    end)

                    collected = true
                    task.wait(0.05)
                end
            end
        end

        if collected then
            pcall(function()
                RemoteFunction:InvokeServer("Deposit Eggs")
            end)

            task.wait(0.1)

            pcall(function()
                RemoteFunction:InvokeServer("Collect Cash")
            end)
        end

        task.wait(1)
    end
end)