--[[
    ESP Module - Zombie Hyperloot
    ESP cho Zombie, Chest, Player (Drawing API)
]]

local ESP = {}
local Config = nil

-- ESP Objects
ESP.playerESPObjects = {}
ESP.zombieESPObjects = {}
ESP.hasPlayerDrawing = false
ESP.chestDescendantConnection = nil
ESP.bobESPConnection = nil
ESP.bobESPObjects = {} -- Lưu các Bob đã tạo ESP
ESP.bobESPRunning = false -- Flag để dừng loop



function ESP.init(config)
    Config = config
end

----------------------------------------------------------
-- 🔹 Drawing Helper
local function newDrawing(t, props)
    local o = Drawing.new(t)
    for k, v in pairs(props) do
        o[k] = v
    end
    return o
end

----------------------------------------------------------
-- 🔹 Box Screen Points
function ESP.getBoxScreenPoints(cf, size)
    local half = size / 2
    local points = {}
    local visible = true

    for x = -1, 1, 2 do
        for y = -1, 1, 2 do
            for z = -1, 1, 2 do
                local corner = cf * Vector3.new(half.X * x, half.Y * y, half.Z * z)
                local screenPos, onScreen = Config.Workspace.CurrentCamera:WorldToViewportPoint(corner)
                if not onScreen then
                    visible = false
                end
                table.insert(points, Vector2.new(screenPos.X, screenPos.Y))
            end
        end
    end

    return points, visible
end

----------------------------------------------------------
-- 🔹 Player ESP
ESP.playerHighlights = {}

function ESP.createPlayerESPElements()
    return {
        Box       = newDrawing("Square", {Visible = false, Thickness = 2, Filled = false, Color = Config.espColorPlayer}),
        Name      = newDrawing("Text",   {Visible = false, Center = true, Outline = true, Size = 14, Font = 2, Color = Color3.new(1,1,1)}),
        Tracer    = newDrawing("Line",   {Visible = false, Thickness = 1, Color = Config.espColorPlayer}),
        HealthBar = newDrawing("Line",   {Visible = false, Thickness = 3, Color = Color3.new(0,1,0)})
    }
end

function ESP.hidePlayerESP(data)
    if not data then return end
    data.Box.Visible = false
    data.Name.Visible = false
    data.Tracer.Visible = false
    data.HealthBar.Visible = false
end

function ESP.addPlayerHighlight(player)
    if not Config.espPlayerHighlight then return end
    local char = player.Character
    if not char or ESP.playerHighlights[player] then return end
    
    local isEnemy = Config.espPlayerTeamCheck and player.Team ~= Config.localPlayer.Team
    local color = isEnemy and Config.espColorEnemy or Config.espColorPlayer
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "PlayerESP_Highlight"
    highlight.Adornee = char
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = char
    
    ESP.playerHighlights[player] = highlight
end

function ESP.removePlayerHighlight(player)
    local highlight = ESP.playerHighlights[player]
    if highlight then
        highlight:Destroy()
        ESP.playerHighlights[player] = nil
    end
end

function ESP.updatePlayerHighlights()
    for _, player in ipairs(Config.Players:GetPlayers()) do
        if player ~= Config.localPlayer then
            local char = player.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            
            if char and humanoid and humanoid.Health > 0 then
                if Config.espPlayerEnabled and Config.espPlayerHighlight then
                    if Config.espPlayerTeamCheck and player.Team == Config.localPlayer.Team then
                        ESP.removePlayerHighlight(player)
                    else
                        ESP.addPlayerHighlight(player)
                    end
                else
                    ESP.removePlayerHighlight(player)
                end
            else
                ESP.removePlayerHighlight(player)
            end
        end
    end
end

function ESP.drawPlayerESP(plr, cf, size, humanoid)
    if not ESP.hasPlayerDrawing or not Config.espPlayerEnabled then
        ESP.hidePlayerESP(ESP.playerESPObjects[plr])
        return
    end

    local points, visible = ESP.getBoxScreenPoints(cf, size)
    if not visible or #points == 0 then
        ESP.hidePlayerESP(ESP.playerESPObjects[plr])
        return
    end

    local data = ESP.playerESPObjects[plr]
    if not data then return end

    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    for _, pt in ipairs(points) do
        minX = math.min(minX, pt.X)
        minY = math.min(minY, pt.Y)
        maxX = math.max(maxX, pt.X)
        maxY = math.max(maxY, pt.Y)
    end

    local boxWidth, boxHeight = maxX - minX, maxY - minY
    if boxWidth <= 3 or boxHeight <= 4 then
        ESP.hidePlayerESP(data)
        return
    end

    local slimWidth = boxWidth * 0.7
    local slimX = minX + (boxWidth - slimWidth) / 2
    local isEnemy = Config.espPlayerTeamCheck and plr.Team ~= Config.localPlayer.Team
    local baseColor = isEnemy and Config.espColorEnemy or Config.espColorPlayer
    local screenCenter = Vector2.new(Config.Workspace.CurrentCamera.ViewportSize.X / 2, Config.Workspace.CurrentCamera.ViewportSize.Y)

    local hp = humanoid and humanoid.Health or 0
    local maxHp = humanoid and humanoid.MaxHealth or 100
    local ratio = math.clamp(maxHp > 0 and hp / maxHp or 0, 0, 1)

    -- Box
    if Config.espPlayerBoxes then
        data.Box.Visible = true
        data.Box.Position = Vector2.new(slimX, minY)
        data.Box.Size = Vector2.new(slimWidth, boxHeight)
        data.Box.Color = baseColor
    else
        data.Box.Visible = false
    end

    -- Name
    if Config.espPlayerNames then
        data.Name.Visible = true
        data.Name.Text = string.format("%s [%d]", plr.Name, math.floor(hp))
        data.Name.Position = Vector2.new(slimX + slimWidth / 2, minY - 18)
        data.Name.Color = baseColor
    else
        data.Name.Visible = false
    end

    -- Tracer
    if Config.espPlayerTracers then
        data.Tracer.Visible = true
        data.Tracer.From = screenCenter
        data.Tracer.To = Vector2.new(slimX + slimWidth / 2, maxY)
        data.Tracer.Color = baseColor
    else
        data.Tracer.Visible = false
    end

    -- Health Bar
    if Config.espPlayerHealth then
        local barHeight = boxHeight * ratio
        data.HealthBar.Visible = true
        data.HealthBar.From = Vector2.new(slimX - 5, maxY)
        data.HealthBar.To = Vector2.new(slimX - 5, maxY - barHeight)
        data.HealthBar.Color = Color3.fromRGB((1 - ratio) * 255, ratio * 255, 0)
    else
        data.HealthBar.Visible = false
    end
end


function ESP.initializePlayerESP()
    local ok, obj = pcall(function()
        return Drawing.new("Square")
    end)
    if ok and obj then
        ESP.hasPlayerDrawing = true
        obj:Remove()
        
        for _, plr in ipairs(Config.Players:GetPlayers()) do
            if plr ~= Config.localPlayer then
                ESP.playerESPObjects[plr] = ESP.createPlayerESPElements()
            end
        end
        
        Config.Players.PlayerAdded:Connect(function(plr)
            if plr ~= Config.localPlayer then
                ESP.playerESPObjects[plr] = ESP.createPlayerESPElements()
            end
        end)
        
        Config.Players.PlayerRemoving:Connect(function(plr)
            if ESP.playerESPObjects[plr] then
                for _, drawing in pairs(ESP.playerESPObjects[plr]) do
                    if drawing.Remove then drawing:Remove() end
                end
                ESP.playerESPObjects[plr] = nil
            end
        end)
        
        return true
    end
    return false
end

----------------------------------------------------------
-- 🔹 Zombie ESP
ESP.zombieHighlights = {}

function ESP.createZombieESPElements()
    return {
        Box       = Drawing.new("Square"),
        Name      = Drawing.new("Text"),
        Tracer    = Drawing.new("Line"),
        HealthBar = Drawing.new("Line"),
    }
end

function ESP.hideZombieESP(data)
    if not data then return end
    data.Box.Visible = false
    data.Name.Visible = false
    data.Tracer.Visible = false
    data.HealthBar.Visible = false
end

function ESP.addZombieHighlight(zombie)
    if not Config.espZombieHighlight then return end
    if ESP.zombieHighlights[zombie] then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ZombieESP_Highlight"
    highlight.Adornee = zombie
    highlight.FillColor = Config.espColorZombie
    highlight.OutlineColor = Config.espColorZombie
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = zombie
    
    ESP.zombieHighlights[zombie] = highlight
end

function ESP.removeZombieHighlight(zombie)
    local highlight = ESP.zombieHighlights[zombie]
    if highlight then
        highlight:Destroy()
        ESP.zombieHighlights[zombie] = nil
    end
end

function ESP.updateZombieHighlights()
    for _, zombie in ipairs(Config.entityFolder:GetChildren()) do
        if zombie:IsA("Model") then
            local humanoid = zombie:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                if Config.espZombieEnabled and Config.espZombieHighlight then
                    ESP.addZombieHighlight(zombie)
                else
                    ESP.removeZombieHighlight(zombie)
                end
            else
                ESP.removeZombieHighlight(zombie)
            end
        end
    end
end

function ESP.drawZombieESP(zombieModel, cf, size, humanoid)
    if not ESP.hasPlayerDrawing or not Config.espZombieEnabled then
        ESP.hideZombieESP(ESP.zombieESPObjects[zombieModel])
        return
    end

    local points, visible = ESP.getBoxScreenPoints(cf, size)
    if not visible or #points == 0 then
        ESP.hideZombieESP(ESP.zombieESPObjects[zombieModel])
        return
    end

    local data = ESP.zombieESPObjects[zombieModel]
    if not data then
        data = ESP.createZombieESPElements()
        -- Setup default properties
        data.Box.Thickness = 2
        data.Box.Filled = false
        data.Name.Center = true
        data.Name.Outline = true
        data.Name.Size = 14
        data.Name.Font = 2
        data.Tracer.Thickness = 1
        data.HealthBar.Thickness = 3
        ESP.zombieESPObjects[zombieModel] = data
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
        ESP.hideZombieESP(data)
        return
    end

    local slimWidth = boxWidth * 0.7
    local slimX = minX + (boxWidth - slimWidth) / 2
    local baseColor = Config.espColorZombie
    local screenCenter = Vector2.new(Config.Workspace.CurrentCamera.ViewportSize.X / 2, Config.Workspace.CurrentCamera.ViewportSize.Y)

    local hp = humanoid and humanoid.Health or 0
    local maxHp = humanoid and humanoid.MaxHealth or 100
    local ratio = math.clamp(maxHp > 0 and hp / maxHp or 0, 0, 1)

    -- Box
    if Config.espZombieBoxes then
        data.Box.Visible = true
        data.Box.Position = Vector2.new(slimX, minY)
        data.Box.Size = Vector2.new(slimWidth, boxHeight)
        data.Box.Color = baseColor
    else
        data.Box.Visible = false
    end

    -- Name
    if Config.espZombieNames then
        data.Name.Visible = true
        data.Name.Text = string.format("%s [%d]", zombieModel.Name, math.floor(hp))
        data.Name.Position = Vector2.new(slimX + slimWidth / 2, minY - 18)
        data.Name.Color = baseColor
    else
        data.Name.Visible = false
    end

    -- Tracer
    if Config.espZombieTracers then
        data.Tracer.Visible = true
        data.Tracer.From = screenCenter
        data.Tracer.To = Vector2.new(slimX + slimWidth / 2, maxY)
        data.Tracer.Color = baseColor
    else
        data.Tracer.Visible = false
    end

    -- Health Bar
    if Config.espZombieHealth then
        local barHeight = boxHeight * ratio
        data.HealthBar.Visible = true
        data.HealthBar.From = Vector2.new(slimX - 5, maxY)
        data.HealthBar.To = Vector2.new(slimX - 5, maxY - barHeight)
        data.HealthBar.Color = Color3.fromRGB((1 - ratio) * 255, ratio * 255, 0)
    else
        data.HealthBar.Visible = false
    end
end

----------------------------------------------------------
-- 🔹 Chest ESP (Billboard)
function ESP.createChestESP(part, color, name)
    if not part or part:FindFirstChild("ESPTag") then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = part.Parent
    highlight.FillColor = color or Config.espColorChest
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.7
    highlight.OutlineTransparency = 0
    highlight.Enabled = true
    highlight.Parent = part.Parent

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESPTag"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.Parent = part
end

function ESP.forEachChestPart(callback)
    local map = Config.Workspace:FindFirstChild("Map")
    if not map then return end
    
    for _, mapChild in ipairs(map:GetChildren()) do
        local chestFolder = mapChild:FindFirstChild("Chest")
        if chestFolder then
            for _, chestModel in ipairs(chestFolder:GetChildren()) do
                if chestModel:IsA("Model") and chestModel:FindFirstChild("Chest") then
                    local chestModelFolder = chestModel.Chest
                    for _, chestType in ipairs(chestModelFolder:GetChildren()) do
                        if chestType:IsA("Model") then
                            local chestPart = chestType:FindFirstChildWhichIsA("BasePart")
                            if chestPart then
                                callback(chestPart)
                            end
                        end
                    end
                end
            end
        end
    end
end

function ESP.applyChestESP()
    if not Config.espChestEnabled then return end
    ESP.forEachChestPart(function(chestPart)
        if not chestPart:FindFirstChild("ESPTag") then
            ESP.createChestESP(chestPart, Config.espColorChest, "Chest")
        end
    end)
end

function ESP.clearChestESP()
    ESP.forEachChestPart(function(chestPart)
        local tag = chestPart:FindFirstChild("ESPTag")
        if tag then tag:Destroy() end
        local parentModel = chestPart.Parent
        if parentModel then
            local highlight = parentModel:FindFirstChild("ESP_Highlight")
            if highlight then highlight:Destroy() end
        end
    end)
end

function ESP.clearZombieESP()
    for _, zombie in ipairs(Config.entityFolder:GetChildren()) do
        local head = zombie:FindFirstChild("Head")
        if head then
            local espTag = head:FindFirstChild("ESPTag")
            if espTag then espTag:Destroy() end
            local highlight = zombie:FindFirstChild("ESP_Highlight")
            if highlight then highlight:Destroy() end
        end
    end
end

function ESP.refreshChestHighlights(color)
    ESP.forEachChestPart(function(chestPart)
        local parentModel = chestPart.Parent
        if parentModel then
            local highlight = parentModel:FindFirstChild("ESP_Highlight")
            if highlight then highlight.FillColor = color end
        end
    end)
end

function ESP.watchChestDescendants()
    if ESP.chestDescendantConnection then
        ESP.chestDescendantConnection:Disconnect()
        ESP.chestDescendantConnection = nil
    end
    local map = Config.Workspace:FindFirstChild("Map")
    if not map then return end
    
    local connections = {}
    for _, mapChild in ipairs(map:GetChildren()) do
        local chestFolder = mapChild:FindFirstChild("Chest")
        if chestFolder then
            local connection = chestFolder.DescendantAdded:Connect(function(desc)
                if Config.espChestEnabled and desc:IsA("BasePart") then
                    task.defer(ESP.applyChestESP)
                end
            end)
            table.insert(connections, connection)
        end
    end
    
    ESP.chestDescendantConnection = {
        Disconnect = function()
            for _, conn in ipairs(connections) do conn:Disconnect() end
        end
    }
end

----------------------------------------------------------
-- 🔹 Bob ESP
function ESP.findAllBobs()
    local bobs = {}
    local map = Config.Workspace:FindFirstChild("Map")
    if not map then return bobs end
    
    -- Duyệt qua tất cả children của Map
    for _, mapChild in ipairs(map:GetChildren()) do
        if mapChild:IsA("Model") then
            local eItem = mapChild:FindFirstChild("EItem")
            if eItem then
                local bob = eItem:FindFirstChild("BOB")
                if bob then
                    local bobModel = bob:FindFirstChild("Bob")
                    if bobModel then
                        local humanoid = bobModel:FindFirstChild("Humanoid")
                        if humanoid then
                            -- Tìm BasePart để làm ESP (có thể là HumanoidRootPart hoặc Head)
                            local hrp = bobModel:FindFirstChild("HumanoidRootPart")
                            local head = bobModel:FindFirstChild("Head")
                            local part = hrp or head or bobModel:FindFirstChildWhichIsA("BasePart")
                            if part then
                                table.insert(bobs, {
                                    model = bobModel,
                                    part = part,
                                    humanoid = humanoid
                                })
                            end
                        end
                    end
                end
            end
        end
    end
    
    return bobs
end

function ESP.createBobESP(bobData)
    if not bobData or not bobData.model or not bobData.part then return end
    
    -- Kiểm tra xem đã có ESP chưa
    if ESP.bobESPObjects[bobData.model] then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "BobESP_Highlight"
    highlight.Adornee = bobData.model
    highlight.FillColor = Config.espColorBob
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Enabled = true
    highlight.Parent = bobData.model
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "BobESP_Tag"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Parent = bobData.part
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "BOB"
    textLabel.TextColor3 = Config.espColorBob
    textLabel.TextSize = 20
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.Parent = billboard
    
    -- Lưu ESP objects
    ESP.bobESPObjects[bobData.model] = {
        highlight = highlight,
        billboard = billboard,
        model = bobData.model
    }
end

function ESP.clearBobESP()
    for model, espData in pairs(ESP.bobESPObjects) do
        if espData.highlight then
            pcall(function() espData.highlight:Destroy() end)
        end
        if espData.billboard then
            pcall(function() espData.billboard:Destroy() end)
        end
    end
    ESP.bobESPObjects = {}
end

function ESP.updateBobESP()
    if not Config.espBobEnabled then
        ESP.clearBobESP()
        return
    end
    
    -- Tìm tất cả Bobs
    local currentBobs = ESP.findAllBobs()
    local foundModels = {}
    
    -- Tạo ESP cho Bobs mới
    for _, bobData in ipairs(currentBobs) do
        foundModels[bobData.model] = true
        if not ESP.bobESPObjects[bobData.model] then
            ESP.createBobESP(bobData)
        end
    end
    
    -- Xóa ESP cho Bobs không còn tồn tại
    for model, espData in pairs(ESP.bobESPObjects) do
        if not foundModels[model] then
            if espData.highlight then
                pcall(function() espData.highlight:Destroy() end)
            end
            if espData.billboard then
                pcall(function() espData.billboard:Destroy() end)
            end
            ESP.bobESPObjects[model] = nil
        end
    end
end

function ESP.startBobESP()
    if ESP.bobESPConnection then return end
    
    ESP.bobESPRunning = true
    
    -- Update lần đầu
    ESP.updateBobESP()
    
    -- Refresh mỗi 5 giây
    ESP.bobESPConnection = task.spawn(function()
        while ESP.bobESPRunning do
            task.wait(5)
            if Config.scriptUnloaded or not Config.espBobEnabled or not ESP.bobESPRunning then
                break
            end
            ESP.updateBobESP()
        end
        ESP.bobESPConnection = nil
    end)
end

function ESP.stopBobESP()
    ESP.bobESPRunning = false
    if ESP.bobESPConnection then
        ESP.bobESPConnection = nil
    end
    ESP.clearBobESP()
end

----------------------------------------------------------
-- 🔹 Cleanup
function ESP.cleanup()
    -- Clear player ESP
    for _, data in pairs(ESP.playerESPObjects) do
        if data.Box and data.Box.Remove then pcall(function() data.Box:Remove() end) end
        if data.Name and data.Name.Remove then pcall(function() data.Name:Remove() end) end
        if data.Tracer and data.Tracer.Remove then pcall(function() data.Tracer:Remove() end) end
        if data.HealthBar and data.HealthBar.Remove then pcall(function() data.HealthBar:Remove() end) end
    end
    ESP.playerESPObjects = {}

    -- Clear zombie ESP
    for _, data in pairs(ESP.zombieESPObjects) do
        if data.Box and data.Box.Remove then pcall(function() data.Box:Remove() end) end
        if data.Name and data.Name.Remove then pcall(function() data.Name:Remove() end) end
        if data.Tracer and data.Tracer.Remove then pcall(function() data.Tracer:Remove() end) end
        if data.HealthBar and data.HealthBar.Remove then pcall(function() data.HealthBar:Remove() end) end
    end
    ESP.zombieESPObjects = {}

    -- Clear highlights
    for _, highlight in pairs(ESP.zombieHighlights) do
        pcall(function() highlight:Destroy() end)
    end
    ESP.zombieHighlights = {}
    
    for _, highlight in pairs(ESP.playerHighlights) do
        pcall(function() highlight:Destroy() end)
    end
    ESP.playerHighlights = {}

    -- Clear chest ESP
    ESP.clearChestESP()
    ESP.clearZombieESP()
    
    -- Clear Bob ESP
    ESP.stopBobESP()

    if ESP.chestDescendantConnection and ESP.chestDescendantConnection.Disconnect then
        ESP.chestDescendantConnection:Disconnect()
        ESP.chestDescendantConnection = nil
    end
end

return ESP
