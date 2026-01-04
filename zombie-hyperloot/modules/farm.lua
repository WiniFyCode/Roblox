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
-- 🔹 Redeem Codes
function Farm.redeemAllCodes()
    local codes = {"RAID1212", "CHRISTMAS", "UPD1212", "NEWYEAR"}
    for _, code in ipairs(codes) do
        pcall(function()
            local args = {2073358730, code}
            game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
        end)
        task.wait(0.5)
    end
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
        task.wait(0.2)

        -- Tìm ProximityPrompt trong chest để tương tác trực tiếp (thay vì nhấn phím E)
        local prompt

        -- Ưu tiên tìm prompt trực tiếp trên part
        if chestPart and chestPart:IsA("BasePart") then
            prompt = chestPart:FindFirstChildOfClass("ProximityPrompt")
        end

        -- Nếu không có, thử parent và các descendants
        if not prompt and chestPart and chestPart.Parent then
            prompt = chestPart.Parent:FindFirstChildOfClass("ProximityPrompt")
            if not prompt then
                for _, desc in ipairs(chestPart.Parent:GetDescendants()) do
                    if desc:IsA("ProximityPrompt") then
                        prompt = desc
                        break
                    end
                end
            end
        end

        if prompt then
            if typeof(fireproximityprompt) == "function" then
                pcall(function()
                    fireproximityprompt(prompt)
                end)
            else
                -- Fallback: giữ lại cách bấm E cũ nếu executor không hỗ trợ fireproximityprompt
                virtualUser:CaptureController()
                virtualUser:ClickButton1(Vector2.new(0, 0))
                task.wait(0.1)
                game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(0.1)
                game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game)
            end
        else
            -- Không tìm thấy prompt, fallback sang cách cũ
            virtualUser:CaptureController()
            virtualUser:ClickButton1(Vector2.new(0, 0))
            task.wait(0.1)
            game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.1)
            game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end

        task.wait(0.2)
    end
    
    hrp.CFrame = CFrame.new(oldPos)
end

----------------------------------------------------------
-- 🔹 Potion Buy/Drink (Attack/Health/Luck)
local POTION_SHOP_REMOTE_ID = 3306896484
local POTION_DRINK_REMOTE_ID = 2791618369

Farm.potions = {
    CommonAttack = { buyId = 1001, drinkSlot = 5 },
    CommonHealth = { buyId = 1002, drinkSlot = 8 },
    CommonLuck = { buyId = 1003, drinkSlot = 9 },
    RareAttack = { buyId = 1004, drinkSlot = 6 },
    RareHealth = { buyId = 1005, drinkSlot = 4 },
    RareLuck = { buyId = 1006, drinkSlot = 2 },
}

local function getPotionRemoteEvent()
    local replicatedStorage = Config and Config.ReplicatedStorage
    if not replicatedStorage then
        replicatedStorage = game:GetService("ReplicatedStorage")
    end

    local remoteFolder = replicatedStorage:FindFirstChild("Remote")
    if not remoteFolder then
        warn("[ZombieHyperloot][Potion] Không tìm thấy ReplicatedStorage.Remote")
        return nil
    end

    local remoteEvent = remoteFolder:FindFirstChild("RemoteEvent")
    if not remoteEvent then
        warn("[ZombieHyperloot][Potion] Không tìm thấy RemoteEvent")
        return nil
    end

    return remoteEvent
end

function Farm.buyPotion(potionKey, amount)
    if Config and Config.scriptUnloaded then return end

    local potion = Farm.potions[potionKey]
    if not potion then
        warn("[ZombieHyperloot][Potion] Potion key không hợp lệ: " .. tostring(potionKey))
        return
    end

    local remoteEvent = getPotionRemoteEvent()
    if not remoteEvent then return end

    amount = amount or 1

    local args = {
        POTION_SHOP_REMOTE_ID,
        potion.buyId,
        amount,
    }

    pcall(function()
        remoteEvent:FireServer(unpack(args))
    end)
end

function Farm.drinkPotion(potionKey, amount)
    if Config and Config.scriptUnloaded then return end

    local potion = Farm.potions[potionKey]
    if not potion then
        warn("[ZombieHyperloot][Potion] Potion key không hợp lệ: " .. tostring(potionKey))
        return
    end

    local remoteEvent = getPotionRemoteEvent()
    if not remoteEvent then return end

    amount = amount or 1

    local args = {
        POTION_DRINK_REMOTE_ID,
        potion.drinkSlot,
        amount,
    }

    pcall(function()
        remoteEvent:FireServer(unpack(args))
    end)
end

function Farm.buyAndDrinkPotion(potionKey, amount)
    if Config and Config.scriptUnloaded then return end

    amount = amount or 1

    Farm.buyPotion(potionKey, amount)
    task.wait(0.1)
    Farm.drinkPotion(potionKey, amount)
end

----------------------------------------------------------
-- 🔹 Auto Buy Christmas Gift Box
function Farm.startAutoBuyChristmasGiftBoxLoop()
    task.spawn(function()
        while task.wait(0.1) do
            if Config.scriptUnloaded then break end
            
            if Config.autoBuyChristmasGiftBoxEnabled then
                pcall(function()
                    local args = {
                        3306896484,
                        1013,
                        1
                    }
                    game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
                end)
            end
        end
    end)
end

----------------------------------------------------------
-- 🔹 Auto Buy Santa Claus Gift
function Farm.startAutoBuySantaClausGiftLoop()
    task.spawn(function()
        while task.wait(0.1) do
            if Config.scriptUnloaded then break end
            
            if Config.autoBuySantaClausGiftEnabled then
                pcall(function()
                    local args = {
                        514457962,
                        "ChristmasReward",
                        "BuyItem",
                        1
                    }
                    game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
                end)
            end
        end
    end)
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
