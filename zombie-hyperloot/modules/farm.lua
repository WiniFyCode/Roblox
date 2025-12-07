--[[
    Farm Module - Zombie Hyperloot
    Auto BulletBox, Item Magnet, Auto Chest Teleport
]]

local Farm = {}
local Config = nil
local ESP = nil

function Farm.init(config, esp)
    Config = config
    ESP = esp
end

----------------------------------------------------------
-- 🔹 Auto BulletBox + Item Magnet
function Farm.startAutoBulletBoxLoop()
    task.spawn(function()
        while task.wait(0.5) do
            if Config.scriptUnloaded then break end
            
            if Config.autoBulletBoxEnabled then
                local char = Config.localPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                
                if hrp then
                    local fx = Config.Workspace:FindFirstChild("FX")
                    if fx then
                        for _, child in ipairs(fx:GetChildren()) do
                            -- Collect BulletBox
                            if child.Name == "BulletBox" and (child:IsA("Model") or child:IsA("Folder")) then
                                local boxPart = child:FindFirstChild("Box")
                                if boxPart and boxPart:IsA("BasePart") then
                                    pcall(function()
                                        boxPart.Anchored = false
                                        boxPart.CanCollide = false
                                        boxPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 2, 0))
                                        boxPart.AssemblyLinearVelocity = Vector3.new()
                                    end)
                                end
                            end
                            
                            -- Collect items with ItemEff
                            local itemEff = child:FindFirstChild("ItemEff")
                            if itemEff then
                                local itemPart = child:FindFirstChildWhichIsA("BasePart")
                                if itemPart then
                                    pcall(function()
                                        itemPart.Anchored = false
                                        itemPart.CanCollide = false
                                        itemPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 2, 0))
                                        itemPart.AssemblyLinearVelocity = Vector3.new()
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

----------------------------------------------------------
-- 🔹 Auto Teleport Chests
function Farm.teleportToAllChests()
    local char = Config.localPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local oldPos = hrp.Position
    local virtualUser = game:GetService("VirtualUser")
    
    local chests = {}
    ESP.forEachChestPart(function(chestPart)
        table.insert(chests, chestPart)
    end)
    
    for _, chestPart in ipairs(chests) do
        hrp.CFrame = CFrame.new(chestPart.Position + Vector3.new(0, 2, 0))
        task.wait(0.3)
        
        virtualUser:CaptureController()
        virtualUser:ClickButton1(Vector2.new(0, 0))
        task.wait(0.1)
        
        game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.1)
        game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game)
        task.wait(0.2)
    end
    
    hrp.CFrame = CFrame.new(oldPos)
end

----------------------------------------------------------
-- 🔹 Input Handler for Chest Teleport
function Farm.setupChestTeleportInput()
    Config.UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or Config.scriptUnloaded then return end
        if input.KeyCode == Config.teleportKey and Config.teleportEnabled then
            Farm.teleportToAllChests()
        end
    end)
end

return Farm
