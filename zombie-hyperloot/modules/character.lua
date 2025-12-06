--[[
    Character Module - Zombie Hyperloot
    Copy outfit/appearance từ người chơi khác
]]

local Character = {}
local Config = nil

-- Settings
Character.targetPlayerName = ""
Character.targetUserId = ""
Character.targetUsername = ""
Character.copyOutfitEnabled = false

function Character.init(config)
    Config = config
end

----------------------------------------------------------
-- 🔹 Find Player by Name
function Character.findPlayerByName(name)
    if not name or name == "" then return nil end
    
    local lowerName = string.lower(name)
    
    -- Tìm exact match
    for _, player in ipairs(Config.Players:GetPlayers()) do
        if string.lower(player.Name) == lowerName or string.lower(player.DisplayName) == lowerName then
            return player
        end
    end
    
    -- Tìm partial match
    for _, player in ipairs(Config.Players:GetPlayers()) do
        if string.find(string.lower(player.Name), lowerName) or string.find(string.lower(player.DisplayName), lowerName) then
            return player
        end
    end
    
    return nil
end

----------------------------------------------------------
-- 🔹 Copy Outfit from Player
function Character.copyOutfit(targetPlayer)
    if not targetPlayer then
        warn("[Character] Target player not found")
        return false
    end
    
    local targetChar = targetPlayer.Character
    if not targetChar then
        warn("[Character] Target character not found")
        return false
    end
    
    local localChar = Config.localPlayer.Character
    if not localChar then
        warn("[Character] Local character not found")
        return false
    end
    
    local humanoid = localChar:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        warn("[Character] Humanoid not found")
        return false
    end
    
    -- Lấy HumanoidDescription từ target
    local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
    if not targetHumanoid then
        warn("[Character] Target humanoid not found")
        return false
    end
    
    local success, description = pcall(function()
        return targetHumanoid:GetAppliedDescription()
    end)
    
    if not success or not description then
        warn("[Character] Failed to get target description")
        return false
    end
    
    -- Thử apply với nhiều methods
    local applySuccess = false
    
    -- Method 1: ApplyDescription trực tiếp
    local try1 = pcall(function()
        humanoid:ApplyDescription(description)
    end)
    
    if try1 then
        applySuccess = true
    else
        -- Method 2: Clone và apply
        local try2 = pcall(function()
            local clone = description:Clone()
            humanoid:ApplyDescription(clone)
        end)
        
        if try2 then
            applySuccess = true
        else
            -- Method 3: Apply manually
            local try3 = pcall(function()
                Character.applyDescriptionManually(humanoid, description)
            end)
            
            if try3 then
                applySuccess = true
            end
        end
    end
    
    if applySuccess then
        return true
    else
        warn("[Character] All apply methods failed")
        return false
    end
end

----------------------------------------------------------
-- 🔹 Copy Outfit by Name
function Character.copyOutfitByName(playerName)
    local targetPlayer = Character.findPlayerByName(playerName)
    
    if not targetPlayer then
        return false, "Player not found: " .. playerName
    end
    
    local success = Character.copyOutfit(targetPlayer)
    
    if success then
        return true, "Successfully copied outfit from " .. targetPlayer.DisplayName
    else
        return false, "Failed to copy outfit from " .. targetPlayer.DisplayName
    end
end

----------------------------------------------------------
-- 🔹 Get All Players List
function Character.getAllPlayersNames()
    local names = {}
    for _, player in ipairs(Config.Players:GetPlayers()) do
        if player ~= Config.localPlayer then
            table.insert(names, player.DisplayName .. " (@" .. player.Name .. ")")
        end
    end
    return names
end

----------------------------------------------------------
-- 🔹 Copy Outfit from UserId (không cần player trong server)
function Character.copyOutfitFromUserId(userId)
    if not userId or userId == "" then
        return false, "Invalid UserId"
    end
    
    local userIdNum = tonumber(userId)
    if not userIdNum then
        return false, "UserId must be a number"
    end
    
    local localChar = Config.localPlayer.Character
    if not localChar then
        return false, "Local character not found"
    end
    
    local humanoid = localChar:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false, "Humanoid not found"
    end
    
    -- Method 1: Sử dụng GetHumanoidDescriptionFromUserId
    local success1, description = pcall(function()
        return Config.Players:GetHumanoidDescriptionFromUserId(userIdNum)
    end)
    
    if not success1 or not description then
        return false, "Failed to get description from UserId: " .. userId .. " (User may not exist)"
    end
    
    -- Method 2: Apply description với nhiều cách thử
    local applySuccess = false
    local errorMsg = ""
    
    -- Thử 1: ApplyDescription trực tiếp
    local try1 = pcall(function()
        humanoid:ApplyDescription(description)
    end)
    
    if try1 then
        applySuccess = true
    else
        -- Thử 2: Clone description và apply
        local try2, clonedDesc = pcall(function()
            local clone = description:Clone()
            humanoid:ApplyDescription(clone)
            return clone
        end)
        
        if try2 then
            applySuccess = true
        else
            -- Thử 3: Apply từng property riêng lẻ
            local try3 = pcall(function()
                Character.applyDescriptionManually(humanoid, description)
            end)
            
            if try3 then
                applySuccess = true
            else
                errorMsg = "All apply methods failed. Game may have anti-cheat protection."
            end
        end
    end
    
    if applySuccess then
        -- Lấy username để hiển thị
        local username = "Unknown"
        pcall(function()
            username = Config.Players:GetNameFromUserIdAsync(userIdNum)
        end)
        return true, "Successfully copied outfit from " .. username .. " (ID: " .. userId .. ")"
    else
        return false, errorMsg
    end
end

----------------------------------------------------------
-- 🔹 Apply Description Manually (backup method)
function Character.applyDescriptionManually(humanoid, description)
    -- Apply các properties quan trọng
    pcall(function() humanoid.BodyTypeScale = description.BodyTypeScale end)
    pcall(function() humanoid.DepthScale = description.DepthScale end)
    pcall(function() humanoid.HeadScale = description.HeadScale end)
    pcall(function() humanoid.HeightScale = description.HeightScale end)
    pcall(function() humanoid.ProportionScale = description.ProportionScale end)
    pcall(function() humanoid.WidthScale = description.WidthScale end)
    
    -- Apply accessories
    local char = humanoid.Parent
    if char then
        -- Xóa accessories cũ
        for _, accessory in ipairs(char:GetChildren()) do
            if accessory:IsA("Accessory") then
                pcall(function() accessory:Destroy() end)
            end
        end
        
        -- Thêm accessories mới từ description
        local accessoryIds = {
            description.HatAccessory,
            description.HairAccessory,
            description.FaceAccessory,
            description.NeckAccessory,
            description.ShoulderAccessory,
            description.FrontAccessory,
            description.BackAccessory,
            description.WaistAccessory
        }
        
        for _, accessoryId in ipairs(accessoryIds) do
            if accessoryId and accessoryId ~= "" and accessoryId ~= "0" then
                pcall(function()
                    local accessory = game:GetService("InsertService"):LoadAsset(tonumber(accessoryId))
                    if accessory then
                        local acc = accessory:GetChildren()[1]
                        if acc and acc:IsA("Accessory") then
                            acc.Parent = char
                        end
                    end
                end)
            end
        end
        
        -- Apply clothing
        pcall(function()
            local shirt = char:FindFirstChildOfClass("Shirt")
            if not shirt then
                shirt = Instance.new("Shirt")
                shirt.Parent = char
            end
            if description.Shirt and description.Shirt ~= "" then
                shirt.ShirtTemplate = "rbxassetid://" .. description.Shirt
            end
        end)
        
        pcall(function()
            local pants = char:FindFirstChildOfClass("Pants")
            if not pants then
                pants = Instance.new("Pants")
                pants.Parent = char
            end
            if description.Pants and description.Pants ~= "" then
                pants.PantsTemplate = "rbxassetid://" .. description.Pants
            end
        end)
    end
end

----------------------------------------------------------
-- 🔹 Copy Outfit from Username (không cần trong server)
function Character.copyOutfitFromUsername(username)
    if not username or username == "" then
        return false, "Invalid username"
    end
    
    -- Lấy UserId từ username
    local success, userId = pcall(function()
        return Config.Players:GetUserIdFromNameAsync(username)
    end)
    
    if not success or not userId then
        return false, "User not found: " .. username
    end
    
    -- Copy outfit từ UserId
    return Character.copyOutfitFromUserId(tostring(userId))
end

----------------------------------------------------------
-- 🔹 Reset Character Appearance
function Character.resetAppearance()
    local localChar = Config.localPlayer.Character
    if not localChar then return false end
    
    local humanoid = localChar:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    
    -- Lấy description gốc từ UserId
    local success = pcall(function()
        local description = Config.Players:GetHumanoidDescriptionFromUserId(Config.localPlayer.UserId)
        humanoid:ApplyDescription(description)
    end)
    
    return success
end

----------------------------------------------------------
-- 🔹 Copy Specific Items
function Character.copyAccessories(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return false end
    
    local targetChar = targetPlayer.Character
    local localChar = Config.localPlayer.Character
    if not localChar then return false end
    
    -- Xóa accessories cũ
    for _, accessory in ipairs(localChar:GetChildren()) do
        if accessory:IsA("Accessory") then
            accessory:Destroy()
        end
    end
    
    -- Copy accessories mới
    for _, accessory in ipairs(targetChar:GetChildren()) do
        if accessory:IsA("Accessory") then
            local clone = accessory:Clone()
            clone.Parent = localChar
        end
    end
    
    return true
end

function Character.copyClothing(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return false end
    
    local targetChar = targetPlayer.Character
    local localChar = Config.localPlayer.Character
    if not localChar then return false end
    
    -- Copy Shirt
    local targetShirt = targetChar:FindFirstChildOfClass("Shirt")
    local localShirt = localChar:FindFirstChildOfClass("Shirt")
    
    if targetShirt then
        if localShirt then
            localShirt.ShirtTemplate = targetShirt.ShirtTemplate
        else
            local newShirt = Instance.new("Shirt")
            newShirt.ShirtTemplate = targetShirt.ShirtTemplate
            newShirt.Parent = localChar
        end
    end
    
    -- Copy Pants
    local targetPants = targetChar:FindFirstChildOfClass("Pants")
    local localPants = localChar:FindFirstChildOfClass("Pants")
    
    if targetPants then
        if localPants then
            localPants.PantsTemplate = targetPants.PantsTemplate
        else
            local newPants = Instance.new("Pants")
            newPants.PantsTemplate = targetPants.PantsTemplate
            newPants.Parent = localChar
        end
    end
    
    return true
end

----------------------------------------------------------
-- 🔹 Cleanup
function Character.cleanup()
    -- Nothing to cleanup
end

return Character
