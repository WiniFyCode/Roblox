--[[
    HUD Module - Zombie Hyperloot
    Customize Player HUD (Title, PlayerName, Class, Level)
]]

local HUD = {}
local Config = nil

-- HUD Settings
HUD.customHUDEnabled = false
HUD.applyToOtherPlayers = true
HUD.customTitle = "CHEATER"
HUD.customPlayerName = "WiniFy"
HUD.customClass = ""
HUD.customLevel = ""

-- EXP Display Settings
HUD.expDisplayEnabled = true
HUD.expScreenGui = nil
HUD.expLabel = nil
HUD.expUpdateConnection = nil

-- Visibility Settings
HUD.titleVisible = true
HUD.playerNameVisible = true
HUD.classVisible = true
HUD.levelVisible = true
HUD.lobbyPlayerInfoVisible = true

-- Gradient Colors (sẽ được set từ original values)
HUD.titleGradientColor1 = Color3.fromRGB(255, 0, 0) -- Red
HUD.titleGradientColor2 = Color3.fromRGB(255, 255, 255) -- White
HUD.playerNameGradientColor1 = nil
HUD.playerNameGradientColor2 = nil
HUD.classGradientColor1 = nil
HUD.classGradientColor2 = nil
HUD.levelGradientColor1 = nil
HUD.levelGradientColor2 = nil

-- Original values backup
HUD.originalValues = {}

function HUD.init(config)
    Config = config
end

----------------------------------------------------------
-- 🔹 Get HUD Elements
function HUD.getHUDElements(player)
    player = player or Config.localPlayer
    local char = player.Character
    if not char then return nil end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    local hud = hrp:FindFirstChild("HUD")
    if not hud then return nil end
    
    local billboardGui = hud:FindFirstChild("BillboardGui")
    if not billboardGui then return nil end
    
    local main = billboardGui:FindFirstChild("Main")
    if not main then return nil end
    
    return {
        main = main,
        title = main:FindFirstChild("Title"),
        playerName = main:FindFirstChild("PlayerName"),
        class = main:FindFirstChild("Class"),
        level = main:FindFirstChild("Level")
    }
end

----------------------------------------------------------
-- 🔹 Backup Original Values
function HUD.backupOriginalValues()
    local elements = HUD.getHUDElements()
    if not elements then return end
    
    if elements.title and not HUD.originalValues.title then
        HUD.originalValues.title = {
            text = elements.title.Text,
            visible = elements.title.Visible,
            gradient = elements.title:FindFirstChild("UIGradient")
        }
        if HUD.originalValues.title.gradient then
            HUD.originalValues.title.gradientColor1 = HUD.originalValues.title.gradient.Color.Keypoints[1].Value
            HUD.originalValues.title.gradientColor2 = HUD.originalValues.title.gradient.Color.Keypoints[2].Value
            -- Title gradient mặc định là Red -> White, không lấy từ original
        end
    end
    
    if elements.playerName and not HUD.originalValues.playerName then
        HUD.originalValues.playerName = {
            text = elements.playerName.Text,
            visible = elements.playerName.Visible,
            gradient = elements.playerName:FindFirstChild("UIGradient")
        }
        if HUD.originalValues.playerName.gradient then
            HUD.originalValues.playerName.gradientColor1 = HUD.originalValues.playerName.gradient.Color.Keypoints[1].Value
            HUD.originalValues.playerName.gradientColor2 = HUD.originalValues.playerName.gradient.Color.Keypoints[2].Value
            -- Set default colors nếu chưa có
            if not HUD.playerNameGradientColor1 then
                HUD.playerNameGradientColor1 = HUD.originalValues.playerName.gradientColor1
                HUD.playerNameGradientColor2 = HUD.originalValues.playerName.gradientColor2
            end
        end
    end
    
    if elements.class and not HUD.originalValues.class then
        HUD.originalValues.class = {
            text = elements.class.Text,
            visible = elements.class.Visible,
            gradient = elements.class:FindFirstChild("UIGradient")
        }
        if HUD.originalValues.class.gradient then
            HUD.originalValues.class.gradientColor1 = HUD.originalValues.class.gradient.Color.Keypoints[1].Value
            HUD.originalValues.class.gradientColor2 = HUD.originalValues.class.gradient.Color.Keypoints[2].Value
            -- Set default colors nếu chưa có
            if not HUD.classGradientColor1 then
                HUD.classGradientColor1 = HUD.originalValues.class.gradientColor1
                HUD.classGradientColor2 = HUD.originalValues.class.gradientColor2
            end
        end
    end
    
    if elements.level and not HUD.originalValues.level then
        local lvlText = elements.level:FindFirstChild("Lvl")
        if lvlText then
            HUD.originalValues.level = {
                text = lvlText.Text,
                visible = elements.level.Visible,
                gradient = lvlText:FindFirstChild("UIGradient")
            }
            if HUD.originalValues.level.gradient then
                HUD.originalValues.level.gradientColor1 = HUD.originalValues.level.gradient.Color.Keypoints[1].Value
                HUD.originalValues.level.gradientColor2 = HUD.originalValues.level.gradient.Color.Keypoints[2].Value
                -- Set default colors nếu chưa có
                if not HUD.levelGradientColor1 then
                    HUD.levelGradientColor1 = HUD.originalValues.level.gradientColor1
                    HUD.levelGradientColor2 = HUD.originalValues.level.gradientColor2
                end
            end
        end
    end
end

----------------------------------------------------------
-- 🔹 Apply Custom HUD to Single Player
function HUD.applyCustomHUDToPlayer(player)
    local elements = HUD.getHUDElements(player)
    if not elements then return end
    
    -- Apply Title
    if elements.title then
        elements.title.Visible = HUD.titleVisible
        
        if HUD.customTitle ~= "" then
            elements.title.Text = HUD.customTitle
        end
        
        local gradient = elements.title:FindFirstChild("UIGradient")
        if gradient then
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, HUD.titleGradientColor1),
                ColorSequenceKeypoint.new(1, HUD.titleGradientColor2)
            })
        end
    end
    
    -- Apply PlayerName
    if elements.playerName then
        elements.playerName.Visible = HUD.playerNameVisible
        
        if HUD.customPlayerName ~= "" then
            elements.playerName.Text = HUD.customPlayerName
        end
        
        local gradient = elements.playerName:FindFirstChild("UIGradient")
        if gradient then
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, HUD.playerNameGradientColor1),
                ColorSequenceKeypoint.new(1, HUD.playerNameGradientColor2)
            })
        end
    end
    
    -- Apply Class
    if elements.class then
        elements.class.Visible = HUD.classVisible
        
        if HUD.customClass ~= "" then
            elements.class.Text = HUD.customClass
        end
        
        local gradient = elements.class:FindFirstChild("UIGradient")
        if gradient then
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, HUD.classGradientColor1),
                ColorSequenceKeypoint.new(1, HUD.classGradientColor2)
            })
        end
    end
    
    -- Apply Level
    if elements.level then
        elements.level.Visible = HUD.levelVisible
        
        local lvlText = elements.level:FindFirstChild("Lvl")
        if lvlText and HUD.customLevel ~= "" then
            lvlText.Text = HUD.customLevel
        end
        
        if lvlText then
            local gradient = lvlText:FindFirstChild("UIGradient")
            if gradient then
                gradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, HUD.levelGradientColor1),
                    ColorSequenceKeypoint.new(1, HUD.levelGradientColor2)
                })
            end
        end
    end
end

----------------------------------------------------------
-- 🔹 Restore Original HUD
function HUD.restoreOriginalHUD()
    local elements = HUD.getHUDElements()
    if not elements then return end
    
    -- Restore Title
    if elements.title and HUD.originalValues.title then
        elements.title.Text = HUD.originalValues.title.text
        elements.title.Visible = HUD.originalValues.title.visible
        local gradient = elements.title:FindFirstChild("UIGradient")
        if gradient and HUD.originalValues.title.gradientColor1 then
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, HUD.originalValues.title.gradientColor1),
                ColorSequenceKeypoint.new(1, HUD.originalValues.title.gradientColor2)
            })
        end
    end
    
    -- Restore PlayerName
    if elements.playerName and HUD.originalValues.playerName then
        elements.playerName.Text = HUD.originalValues.playerName.text
        elements.playerName.Visible = HUD.originalValues.playerName.visible
        local gradient = elements.playerName:FindFirstChild("UIGradient")
        if gradient and HUD.originalValues.playerName.gradientColor1 then
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, HUD.originalValues.playerName.gradientColor1),
                ColorSequenceKeypoint.new(1, HUD.originalValues.playerName.gradientColor2)
            })
        end
    end
    
    -- Restore Class
    if elements.class and HUD.originalValues.class then
        elements.class.Text = HUD.originalValues.class.text
        elements.class.Visible = HUD.originalValues.class.visible
        local gradient = elements.class:FindFirstChild("UIGradient")
        if gradient and HUD.originalValues.class.gradientColor1 then
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, HUD.originalValues.class.gradientColor1),
                ColorSequenceKeypoint.new(1, HUD.originalValues.class.gradientColor2)
            })
        end
    end
    
    -- Restore Level
    if elements.level and HUD.originalValues.level then
        elements.level.Visible = HUD.originalValues.level.visible
        local lvlText = elements.level:FindFirstChild("Lvl")
        if lvlText then
            lvlText.Text = HUD.originalValues.level.text
            local gradient = lvlText:FindFirstChild("UIGradient")
            if gradient and HUD.originalValues.level.gradientColor1 then
                gradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, HUD.originalValues.level.gradientColor1),
                    ColorSequenceKeypoint.new(1, HUD.originalValues.level.gradientColor2)
                })
            end
        end
    end
end

----------------------------------------------------------
-- 🔹 Apply Custom HUD (Local Player)
function HUD.applyCustomHUD()
    -- Backup original values first
    HUD.backupOriginalValues()
    
    -- Apply to local player
    HUD.applyCustomHUDToPlayer(Config.localPlayer)
    
    -- Apply to other players if enabled
    if HUD.applyToOtherPlayers then
        HUD.applyToAllOtherPlayers()
    end
end

----------------------------------------------------------
-- 🔹 Apply to All Other Players
function HUD.applyToAllOtherPlayers()
    for _, player in ipairs(Config.Players:GetPlayers()) do
        if player ~= Config.localPlayer then
            HUD.applyCustomHUDToPlayer(player)
        end
    end
end

----------------------------------------------------------
-- 🔹 Toggle Custom HUD
function HUD.toggleCustomHUD(enabled)
    HUD.customHUDEnabled = enabled
    
    if enabled then
        HUD.applyCustomHUD()
    else
        HUD.restoreOriginalHUD()
    end
end

----------------------------------------------------------
-- 🔹 Restore HUD for Other Players
function HUD.restoreAllOtherPlayers()
    for _, player in ipairs(Config.Players:GetPlayers()) do
        if player ~= Config.localPlayer then
            HUD.restoreHUDForPlayer(player)
        end
    end
end

function HUD.restoreHUDForPlayer(player)
    local elements = HUD.getHUDElements(player)
    if not elements then return end
    
    -- Restore về tên gốc của player
    if elements.playerName then
        elements.playerName.Text = player.Name
        elements.playerName.Visible = true
    end
    
    -- Restore các elements khác về visible
    if elements.title then
        elements.title.Visible = true
    end
    
    if elements.class then
        elements.class.Visible = true
    end
    
    if elements.level then
        elements.level.Visible = true
    end
end

----------------------------------------------------------
-- 🔹 Toggle Apply to Other Players
function HUD.toggleApplyToOtherPlayers(enabled)
    HUD.applyToOtherPlayers = enabled
    
    if enabled and HUD.customHUDEnabled then
        HUD.applyToAllOtherPlayers()
    else
        -- Restore lại HUD cho tất cả players khác
        HUD.restoreAllOtherPlayers()
    end
end

----------------------------------------------------------
-- 🔹 Character Respawn Handler
function HUD.onCharacterAdded(character)
    task.wait(1) -- Đợi HUD load
    HUD.originalValues = {} -- Reset backup
    
    if HUD.customHUDEnabled then
        HUD.applyCustomHUD()
    end
end

----------------------------------------------------------
-- 🔹 EXP Display Functions
function HUD.createExpDisplay()
    -- Xóa UI cũ nếu có
    if HUD.expScreenGui then
        HUD.expScreenGui:Destroy()
        HUD.expScreenGui = nil
    end
    
    -- Tạo ScreenGui
    HUD.expScreenGui = Instance.new("ScreenGui")
    HUD.expScreenGui.Name = "ExpDisplay"
    HUD.expScreenGui.ResetOnSpawn = false
    HUD.expScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Tạo Frame chứa
    local frame = Instance.new("Frame")
    frame.Name = "ExpFrame"
    frame.Size = UDim2.new(0, 150, 0, 40)
    frame.Position = UDim2.new(1, -160, 1, -50) -- Góc phải dưới
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255, 215, 0) -- Gold border
    frame.Parent = HUD.expScreenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    -- Tạo TextLabel hiển thị EXP
    HUD.expLabel = Instance.new("TextLabel")
    HUD.expLabel.Name = "ExpLabel"
    HUD.expLabel.Size = UDim2.new(1, 0, 1, 0)
    HUD.expLabel.Position = UDim2.new(0, 0, 0, 0)
    HUD.expLabel.BackgroundTransparency = 1
    HUD.expLabel.Text = "Exp: 0"
    HUD.expLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    HUD.expLabel.TextSize = 18
    HUD.expLabel.Font = Enum.Font.SourceSansBold
    HUD.expLabel.TextXAlignment = Enum.TextXAlignment.Center
    HUD.expLabel.Parent = frame
    
    -- Gradient cho text
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)), -- Gold
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)) -- White
    })
    gradient.Parent = HUD.expLabel
    
    -- Stroke để text nổi bật
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 0, 0)
    stroke.Thickness = 2
    stroke.Parent = HUD.expLabel
    
    HUD.expScreenGui.Parent = game:GetService("CoreGui")
end

function HUD.updateExpDisplay()
    if not HUD.expLabel then return end
    
    local leaderstats = Config.localPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local exp = leaderstats:FindFirstChild("exp")
        if exp then
            HUD.expLabel.Text = string.format("Exp: %s", tostring(exp.Value))
        else
            HUD.expLabel.Text = "Exp: N/A"
        end
    else
        HUD.expLabel.Text = "Exp: N/A"
    end
end

function HUD.startExpDisplay()
    if HUD.expUpdateConnection then return end
    
    -- Tạo UI
    HUD.createExpDisplay()
    
    -- Update lần đầu
    HUD.updateExpDisplay()
    
    -- Auto update mỗi 1 giây
    HUD.expUpdateConnection = Config.RunService.Heartbeat:Connect(function()
        if not HUD.expDisplayEnabled then return end
        HUD.updateExpDisplay()
    end)
end

function HUD.stopExpDisplay()
    if HUD.expUpdateConnection then
        HUD.expUpdateConnection:Disconnect()
        HUD.expUpdateConnection = nil
    end
    
    if HUD.expScreenGui then
        HUD.expScreenGui:Destroy()
        HUD.expScreenGui = nil
    end
    
    HUD.expLabel = nil
end

function HUD.toggleExpDisplay(enabled)
    HUD.expDisplayEnabled = enabled
    
    if enabled then
        HUD.startExpDisplay()
    else
        HUD.stopExpDisplay()
    end
end

----------------------------------------------------------
-- 🔹 Lobby PlayerInfo Functions
function HUD.getLobbyPlayerInfo()
    local playerGui = Config.localPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    
    local gamePanel = playerGui:FindFirstChild("GamePanel")
    if not gamePanel then return nil end
    
    local lobbyPanel = gamePanel:FindFirstChild("LobbyPanel")
    if not lobbyPanel then return nil end
    
    local main = lobbyPanel:FindFirstChild("Main")
    if not main then return nil end
    
    return main:FindFirstChild("PlayerInfo")
end

function HUD.toggleLobbyPlayerInfo(visible)
    HUD.lobbyPlayerInfoVisible = visible
    
    local playerInfo = HUD.getLobbyPlayerInfo()
    if playerInfo then
        playerInfo.Visible = visible
    end
end

function HUD.applyLobbyPlayerInfoVisibility()
    local playerInfo = HUD.getLobbyPlayerInfo()
    if playerInfo then
        playerInfo.Visible = HUD.lobbyPlayerInfoVisible
    end
end

----------------------------------------------------------
-- 🔹 Cleanup
function HUD.cleanup()
    HUD.restoreOriginalHUD()
    -- Restore lobby player info
    HUD.lobbyPlayerInfoVisible = true
    HUD.applyLobbyPlayerInfoVisibility()
    -- Stop exp display
    HUD.stopExpDisplay()
    -- Restore all other players
    HUD.restoreAllOtherPlayers()
end

return HUD
