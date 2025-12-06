--[[
    HUD Module - Zombie Hyperloot
    Customize Player HUD (Title, PlayerName, Class, Level)
]]

local HUD = {}
local Config = nil

-- HUD Settings
HUD.customHUDEnabled = false
HUD.customTitle = ""
HUD.customPlayerName = "WiniFy"
HUD.customClass = ""
HUD.customLevel = ""

-- Visibility Settings
HUD.titleVisible = true
HUD.playerNameVisible = true
HUD.classVisible = true
HUD.levelVisible = true
HUD.lobbyPlayerInfoVisible = true
HUD.clonePlayerInfoEnabled = false

-- Cloned PlayerInfo
HUD.clonedPlayerInfo = nil
HUD.clonedScreenGui = nil
HUD.playerInfoUpdateConnection = nil

-- Gradient Colors (sẽ được set từ original values)
HUD.titleGradientColor1 = nil
HUD.titleGradientColor2 = nil
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
function HUD.getHUDElements()
    local char = Config.localPlayer.Character
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
            -- Set default colors nếu chưa có
            if not HUD.titleGradientColor1 then
                HUD.titleGradientColor1 = HUD.originalValues.title.gradientColor1
                HUD.titleGradientColor2 = HUD.originalValues.title.gradientColor2
            end
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
-- 🔹 Apply Custom HUD
function HUD.applyCustomHUD()
    local elements = HUD.getHUDElements()
    if not elements then return end
    
    -- Backup original values first
    HUD.backupOriginalValues()
    
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
-- 🔹 Character Respawn Handler
function HUD.onCharacterAdded(character)
    task.wait(1) -- Đợi HUD load
    HUD.originalValues = {} -- Reset backup
    
    if HUD.customHUDEnabled then
        HUD.applyCustomHUD()
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
-- 🔹 Clone PlayerInfo Functions
function HUD.createClonedPlayerInfo()
    -- Xóa clone cũ nếu có
    HUD.removeClonedPlayerInfo()
    
    -- Lấy PlayerInfo gốc từ Lobby
    local originalPlayerInfo = HUD.getLobbyPlayerInfo()
    if not originalPlayerInfo then
        warn("[HUD] Không tìm thấy PlayerInfo trong Lobby")
        return
    end
    
    -- Tạo ScreenGui mới
    HUD.clonedScreenGui = Instance.new("ScreenGui")
    HUD.clonedScreenGui.Name = "ClonedPlayerInfo"
    HUD.clonedScreenGui.ResetOnSpawn = false
    HUD.clonedScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    HUD.clonedScreenGui.DisplayOrder = 100 -- Hiển thị trên cùng
    
    -- Clone PlayerInfo
    HUD.clonedPlayerInfo = originalPlayerInfo:Clone()
    HUD.clonedPlayerInfo.Name = "PlayerInfo_Cloned"
    HUD.clonedPlayerInfo.Visible = true
    
    -- Đặt vị trí (góc trên bên trái)
    HUD.clonedPlayerInfo.Position = UDim2.new(0, 10, 0, 10)
    HUD.clonedPlayerInfo.AnchorPoint = Vector2.new(0, 0)
    
    HUD.clonedPlayerInfo.Parent = HUD.clonedScreenGui
    HUD.clonedScreenGui.Parent = Config.localPlayer.PlayerGui
    
    -- Update data realtime
    HUD.startPlayerInfoUpdate()
end

function HUD.removeClonedPlayerInfo()
    if HUD.clonedScreenGui then
        HUD.clonedScreenGui:Destroy()
        HUD.clonedScreenGui = nil
        HUD.clonedPlayerInfo = nil
    end
    
    HUD.stopPlayerInfoUpdate()
end

function HUD.updateClonedPlayerInfo()
    if not HUD.clonedPlayerInfo or not HUD.clonedScreenGui then return end
    
    -- Lấy data từ PlayerInfo gốc
    local originalPlayerInfo = HUD.getLobbyPlayerInfo()
    if not originalPlayerInfo then return end
    
    -- Update các giá trị từ original sang clone
    for _, child in ipairs(originalPlayerInfo:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") then
            local clonedChild = HUD.clonedPlayerInfo:FindFirstChild(child.Name, true)
            if clonedChild and clonedChild:IsA("TextLabel") or clonedChild:IsA("TextButton") then
                clonedChild.Text = child.Text
            end
        end
        
        if child:IsA("ImageLabel") then
            local clonedChild = HUD.clonedPlayerInfo:FindFirstChild(child.Name, true)
            if clonedChild and clonedChild:IsA("ImageLabel") then
                clonedChild.Image = child.Image
            end
        end
    end
end

function HUD.startPlayerInfoUpdate()
    if HUD.playerInfoUpdateConnection then return end
    
    HUD.playerInfoUpdateConnection = Config.RunService.Heartbeat:Connect(function()
        if HUD.clonePlayerInfoEnabled and HUD.clonedPlayerInfo then
            HUD.updateClonedPlayerInfo()
        end
    end)
end

function HUD.stopPlayerInfoUpdate()
    if HUD.playerInfoUpdateConnection then
        HUD.playerInfoUpdateConnection:Disconnect()
        HUD.playerInfoUpdateConnection = nil
    end
end

----------------------------------------------------------
-- 🔹 Cleanup
function HUD.cleanup()
    HUD.restoreOriginalHUD()
    -- Restore lobby player info
    HUD.lobbyPlayerInfoVisible = true
    HUD.applyLobbyPlayerInfoVisibility()
    -- Remove cloned player info
    HUD.removeClonedPlayerInfo()
end

return HUD
