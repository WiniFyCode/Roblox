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
function Farm.getBulletBoxPart()
    local fx = Config.Workspace:FindFirstChild("FX")
    local bulletBoxFolder = fx and fx:FindFirstChild("BulletBox")
    local box = bulletBoxFolder and bulletBoxFolder:FindFirstChild("Box")
    if box and box:IsA("BasePart") then
        return box
    end
    return nil
end

function Farm.pullItemsToPlayer(hrp)
    for _, fx in ipairs(Config.fxFolder:GetChildren()) do
        local itemPart = fx:FindFirstChildWhichIsA("BasePart")
        if itemPart and itemPart:IsDescendantOf(Config.fxFolder) then
            itemPart.Anchored = false
            itemPart.CanCollide = false
            itemPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 2, 0))
            itemPart.AssemblyLinearVelocity = Vector3.new()
        end
    end
end

function Farm.startAutoBulletBoxLoop()
    task.spawn(function()
        while task.wait(1) do
            if Config.scriptUnloaded then break end
            local char = Config.localPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                if Config.autoBulletBoxEnabled then
                    local boxPart = Farm.getBulletBoxPart()
                    if boxPart then
                        boxPart.Anchored = false
                        boxPart.CanCollide = false
                        boxPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 2, 0))
                        boxPart.AssemblyLinearVelocity = Vector3.new()
                    end
                    Farm.pullItemsToPlayer(hrp)
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
