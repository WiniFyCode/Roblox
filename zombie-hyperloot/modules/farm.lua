--[[
    Farm Module - Zombie Hyperloot
    Auto BulletBox, Item Magnet, Auto Chest Teleport
]]
local Farm = {}
local Config = nil
function Farm.init(config)
    Config = config
    
    -- Load data from Config
    if Config.Data then
        Farm.potions = Config.Data.Potions or {}
    end
end
-- Runtime lifecycle (moved out of main.lua)
Farm._running = false
Farm._autoBulletThread = nil
Farm._autoGiftThread = nil
Farm._autoSantaThread = nil
Farm._inputConn = nil

function Farm.start()
    if Farm._running then return end
    Farm._running = true

    -- Auto BulletBox + item magnet
    if not Farm._autoBulletThread then
        Farm._autoBulletThread = task.spawn(function()
            while Farm._running do
                task.wait(0.5)
                if Config.scriptUnloaded then break end

                if Config.autoBulletBoxEnabled then
                    local char = Config.localPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")

                    if hrp then
                        local fx = Config.Workspace:FindFirstChild("FX")
                        if fx then
                            for _, child in ipairs(fx:GetChildren()) do
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
            Farm._autoBulletThread = nil
        end)
    end

    -- Auto Buy Christmas Gift Box
    if not Farm._autoGiftThread then
        Farm._autoGiftThread = task.spawn(function()
            while Farm._running do
                task.wait(0.1)
                if Config.scriptUnloaded then break end

                if Config.autoBuyChristmasGiftBoxEnabled then
                    pcall(function()
                        local args = Config.Data and Config.Data.Remotes and Config.Data.Remotes.ChristmasGiftArgs
                        if args then
                            game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
                        end
                    end)
                end
            end
            Farm._autoGiftThread = nil
        end)
    end

    -- Auto Buy Santa Claus Gift
    if not Farm._autoSantaThread then
        Farm._autoSantaThread = task.spawn(function()
            while Farm._running do
                task.wait(0.1)
                if Config.scriptUnloaded then break end

                if Config.autoBuySantaClausGiftEnabled then
                    pcall(function()
                        local args = Config.Data and Config.Data.Remotes and Config.Data.Remotes.SantaGiftArgs
                        if args then
                            game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
                        end
                    end)
                end
            end
            Farm._autoSantaThread = nil
        end)
    end

    -- Input handler for Chest Teleport
    if not Farm._inputConn then
        Farm._inputConn = Config.UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed or Config.scriptUnloaded then return end
            if input.KeyCode == Config.teleportKey and Config.teleportEnabled then
                Farm.teleportToAllChests()
            end
        end)
    end
end

function Farm.stop()
    Farm._running = false

    if Farm._inputConn then
        Farm._inputConn:Disconnect()
        Farm._inputConn = nil
    end

    -- Threads will self-exit due to _running=false
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
    local map = Config.Workspace:FindFirstChild("Map")
    if not map then return end

    local chests = {}
    for _, mapChild in ipairs(map:GetChildren()) do
        local chestFolder = mapChild:FindFirstChild("Chest")
        if chestFolder then
            for _, chestItem in ipairs(chestFolder:GetChildren()) do
                table.insert(chests, chestItem)
            end
        end
    end

    local TweenService = game:GetService("TweenService")

    for _, chestItem in ipairs(chests) do
        if not chestItem or not chestItem.Parent then continue end

        local targetPart = chestItem:FindFirstChildWhichIsA("BasePart", true)
        if not targetPart then continue end

        local targetCFrame = CFrame.new(targetPart.Position + Vector3.new(0, 3, 0))

        if Config.teleportMode == "Tween" then
            -- Chế độ Tween
            local tweenInfo = TweenInfo.new(Config.teleportTweenSpeed or 2, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
            tween:Play()
            tween.Completed:Wait()
        else
            -- Chế độ Instant
            hrp.CFrame = targetCFrame
        end

        task.wait(Config.chestTeleportDelay or 0.5)

        local chestFolder = chestItem:FindFirstChild("Chest")
        if chestFolder then
            local proximityPrompt = chestFolder:FindFirstChild("ProximityPrompt")
            if proximityPrompt then
                pcall(function()
                    if typeof(fireproximityprompt) == "function" then
                        fireproximityprompt(proximityPrompt)
                    end
                end)
                task.wait(0.25)
            end
        end
    end

    -- Return to old position
    if Config.teleportMode == "Tween" then
         local tweenInfo = TweenInfo.new(Config.teleportTweenSpeed or 2, Enum.EasingStyle.Linear)
         local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(oldPos)})
         tween:Play()
         tween.Completed:Wait()
    else
         hrp.CFrame = CFrame.new(oldPos)
    end
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
    
    if Config.Data and Config.Data.Remotes then
        POTION_SHOP_REMOTE_ID = Config.Data.Remotes.PotionShopEvent
    end
    
    if not POTION_SHOP_REMOTE_ID then return end

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

    if Config.Data and Config.Data.Remotes then
        POTION_DRINK_REMOTE_ID = Config.Data.Remotes.PotionDrinkEvent
    end
    
    if not POTION_DRINK_REMOTE_ID then return end

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
                    local args = Config.Data and Config.Data.Remotes and Config.Data.Remotes.ChristmasGiftArgs
                    if args then
                        game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
                    end
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
                    local args = Config.Data and Config.Data.Remotes and Config.Data.Remotes.SantaGiftArgs
                    if args then
                        game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
                    end
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
