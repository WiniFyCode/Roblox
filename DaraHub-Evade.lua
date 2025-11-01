-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Localization setup
local Localization = WindUI:Localization({
    Enabled = true,
    Prefix = "loc:",
    DefaultLanguage = "en",
    Translations = {
        ["en"] = {
            ["SCRIPT_TITLE"] = "Evade",
            ["WELCOME"] = "Welcome: ",
            ["FEATURES"] = "Features",
            ["Player_TAB"] = "Player",
            ["AUTO_TAB"] = "Auto",
            ["VISUALS_TAB"] = "Visuals",
            ["ESP_TAB"] = "ESP",
            ["SETTINGS_TAB"] = "Settings",
            ["AUTO_JUMP"] = "Auto Jump",
            ["INFINITE_JUMP"] = "Infinite Jump",
            ["JUMP_METHOD"] = "Infinite Jump Method",
            ["FLY"] = "Fly",
            ["FLY_SPEED"] = "Fly Speed",
            ["SPEED_HACK"] = "Speed",
            ["SPEED_HACK_VALUE"] = "Speed",
            ["JUMP_HEIGHT"] = "Jump Height",
            ["JUMP_POWER"] = "Jump Height",
            ["ANTI_AFK"] = "Anti AFK",
            ["FULL_BRIGHT"] = "FullBright",
            ["NO_FOG"] = "Remove Fog",
            ["FOV"] = "Field of View",
            ["PLAYER_NAME_ESP"] = "Player Name ESP",
            ["PLAYER_BOX_ESP"] = "Player Box ESP",
            ["PLAYER_TRACER"] = "Player Tracer",
            ["PLAYER_DISTANCE_ESP"] = "Player Distance ESP",
            ["PLAYER_RAINBOW_BOXES"] = "Player Rainbow Boxes",
            ["PLAYER_RAINBOW_TRACERS"] = "Player Rainbow Tracers",
            ["PLAYER_NAME_MODE"] = "Player Name Display",
            ["NEXTBOT_ESP"] = "Nextbot ESP",
            ["NEXTBOT_NAME_ESP"] = "Nextbot Name ESP",
            ["DOWNED_BOX_ESP"] = "Downed Player Box ESP",
            ["DOWNED_TRACER"] = "Downed Player Tracer",
            ["DOWNED_NAME_ESP"] = "Downed Player Name ESP",
            ["DOWNED_DISTANCE_ESP"] = "Downed Player Distance ESP",
            ["AUTO_CARRY"] = "Auto Carry",
            ["AUTO_REVIVE"] = "Auto Revive",
            ["AUTO_VOTE"] = "Auto Vote",
            ["AUTO_VOTE_MAP"] = "Auto Vote Map",
            ["AUTO_SELF_REVIVE"] = "Auto Self Revive",
            ["MANUAL_REVIVE"] = "Manual Revive",
            ["AUTO_WIN"] = "Auto Win",
            ["AUTO_MONEY_FARM"] = "Auto Money Farm",
            ["SAVE_CONFIG"] = "Save Configuration",
            ["LOAD_CONFIG"] = "Load Configuration",
            ["THEME_SELECT"] = "Select Theme",
            ["TRANSPARENCY"] = "Window Transparency"
        }
    }
})

-- Set WindUI properties
WindUI.TransparencyValue = 0.2
WindUI:SetTheme("Dark")

-- Create WindUI window
local Window = WindUI:CreateWindow({
    Title = "loc:SCRIPT_TITLE",
    Icon = "swords",
    Author = "loc:WELCOME",
    Folder = "GameHackUI",
    Size = UDim2.fromOffset(580, 490),
    Theme = "Dark",
    HidePanelBackground = false,
    Acrylic = false,
    HideSearchBar = false,
    SideBarWidth = 200,
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function()
        end
    },
    --       remove this all, 
    -- !  ↓  if you DON'T need the key system
    -- KeySystem = { 
    --     -- ↓ Optional. You can remove it.
    --     Key = { "1234", "5678" },
    --     Note = "Example Key System.",
    --     -- ↓ Optional. You can remove it.
    --     Thumbnail = {
    --         Image = "rbxassetid://",
    --         Title = "Thumbnail",
    --     },
    --     -- ↓ Optional. You can remove it.
    --     URL = "YOUR LINK TO GET KEY (Discord, Linkvertise, Pastebin, etc.)",
    --     -- ↓ Optional. You can remove it.
    --     SaveKey = false, -- automatically save and load the key.
    --     API = {                                                                 
    --         { -- PlatoBoost
    --             --[[ Here you can write your title, description, and icon --]]
    --             Title = "Platoboost",-- optional . you can remove it
    --             Desc = "Click to copy.", -- optional . you can remove it
    --             Icon = "rbxassetid://", -- optional . you can remove it
    --             Type = "platoboost", -- type
    --             ServiceId = 1234, -- service id
    --             Secret = "platoboost-secret", -- platoboost secret
    --         },                                                                  
    --         { -- Panda development
    --             Type = "pandadevelopment", -- type
    --             ServiceId = "myServiceId", -- service id
    --         },                                                                  
    --     },        
    -- },
})
-- Track window open state robustly
local isWindowOpen = false
local function updateWindowOpenState()
    -- Try calling Window:IsOpen() if available
    if Window and type(Window.IsOpen) == "function" then
        local ok, val = pcall(function() return Window:IsOpen() end)
        if ok and type(val) == "boolean" then
            isWindowOpen = val
            return
        end
    end
    -- Fallback to property if present
    if Window and Window.Opened ~= nil then
        isWindowOpen = Window.Opened
        return
    end
    -- Default fallback (safe)
    isWindowOpen = isWindowOpen or false
end

-- Try initial update (non-fatal)
pcall(updateWindowOpenState)

-- Key system variables
local currentKey = Enum.KeyCode.RightControl -- Default key
local keyConnection = nil
local isListeningForInput = false
local keyInputConnection = nil

-- Manual Revive key variables
local manualReviveKey = Enum.KeyCode.C -- Default key for manual revive
local manualReviveKeyConnection = nil
local isListeningForManualRevive = false
local manualReviveKeyInputConnection = nil

-- Expose keyBindButton variable so we can update its description later
local keyBindButton = nil
local manualReviveKeyBindButton = nil

-- File path for saving keybind
local keybindFile = "keybind_config.txt"
local manualReviveKeybindFile = "manual_revive_keybind_config.txt"

-- Function to get clean key name (remove "Enum.KeyCode." prefix)
local function getCleanKeyName(keyCode)
    local keyString = tostring(keyCode)
    -- Remove "Enum.KeyCode." prefix if it exists
    return keyString:gsub("Enum%.KeyCode%.", "")
end

-- Function to save keybind to file
local function saveKeybind()
    local keyString = tostring(currentKey)
    writefile(keybindFile, keyString)
end

-- Function to load keybind from file
local function loadKeybind()
    if isfile(keybindFile) then
        local savedKey = readfile(keybindFile)
        -- Convert string back to KeyCode
        for _, key in pairs(Enum.KeyCode:GetEnumItems()) do
            if tostring(key) == savedKey then
                currentKey = key
                return true
            end
        end
    end
    return false
end

-- Function to save manual revive keybind to file
local function saveManualReviveKeybind()
    local keyString = tostring(manualReviveKey)
    writefile(manualReviveKeybindFile, keyString)
end

-- Function to load manual revive keybind from file
local function loadManualReviveKeybind()
    if isfile(manualReviveKeybindFile) then
        local savedKey = readfile(manualReviveKeybindFile)
        -- Convert string back to KeyCode
        for _, key in pairs(Enum.KeyCode:GetEnumItems()) do
            if tostring(key) == savedKey then
                manualReviveKey = key
                return true
            end
        end
    end
    return false
end

-- Load keybinds when script starts
loadKeybind()
loadManualReviveKeybind()

-- Helper: robustly update the keybind button description (tries several APIs)
local function updateKeybindButtonDesc()
    if not keyBindButton then return false end
    local desc = "Current Key: " .. getCleanKeyName(currentKey)
    local success = false

    local methods = {
        function() -- common SetDesc
            if type(keyBindButton.SetDesc) == "function" then
                keyBindButton:SetDesc(desc)
            else
                error("no SetDesc")
            end
        end,
        function() -- some widgets use :Set("Desc", value)
            if type(keyBindButton.Set) == "function" then
                keyBindButton:Set("Desc", desc)
            else
                error("no Set")
            end
        end,
        function() -- direct property set
            if keyBindButton.Desc ~= nil then
                keyBindButton.Desc = desc
            else
                error("no Desc property")
            end
        end,
        function() -- alternate name
            if type(keyBindButton.SetDescription) == "function" then
                keyBindButton:SetDescription(desc)
            else
                error("no SetDescription")
            end
        end,
        function() -- fallback: attempt to call SetValue (some libs)
            if type(keyBindButton.SetValue) == "function" then
                keyBindButton:SetValue(desc)
            else
                error("no SetValue")
            end
        end
    }

    for _, fn in ipairs(methods) do
        local ok = pcall(fn)
        if ok then
            success = true
            break
        end
    end

    -- If none of methods worked, try updating the WindUI tooltip via a notify workaround:
    if not success then
        pcall(function()
            WindUI:Notify({
                Title = "Keybind",
                Content = desc,
                Duration = 2
            })
        end)
    end

    return success
end

-- Helper: robustly update the manual revive keybind button description
local function updateManualReviveKeybindButtonDesc()
    if not manualReviveKeyBindButton then return false end
    local desc = "Current Key: " .. getCleanKeyName(manualReviveKey)
    local success = false

    local methods = {
        function() -- common SetDesc
            if type(manualReviveKeyBindButton.SetDesc) == "function" then
                manualReviveKeyBindButton:SetDesc(desc)
            else
                error("no SetDesc")
            end
        end,
        function() -- some widgets use :Set("Desc", value)
            if type(manualReviveKeyBindButton.Set) == "function" then
                manualReviveKeyBindButton:Set("Desc", desc)
            else
                error("no Set")
            end
        end,
        function() -- direct property set
            if manualReviveKeyBindButton.Desc ~= nil then
                manualReviveKeyBindButton.Desc = desc
            else
                error("no Desc property")
            end
        end,
        function() -- alternate name
            if type(manualReviveKeyBindButton.SetDescription) == "function" then
                manualReviveKeyBindButton:SetDescription(desc)
            else
                error("no SetDescription")
            end
        end,
        function() -- fallback: attempt to call SetValue (some libs)
            if type(manualReviveKeyBindButton.SetValue) == "function" then
                manualReviveKeyBindButton:SetValue(desc)
            else
                error("no SetValue")
            end
        end
    }

    for _, fn in ipairs(methods) do
        local ok = pcall(fn)
        if ok then
            success = true
            break
        end
    end

    if not success then
        pcall(function()
            WindUI:Notify({
                Title = "Manual Revive Keybind",
                Content = desc,
                Duration = 2
            })
        end)
    end

    return success
end

-- Function to handle key binding
local function bindKey(keyBindButtonParam)
    -- Prefer parameter if provided
    local targetButton = keyBindButtonParam or keyBindButton

    if isListeningForInput then 
        -- If already listening, cancel it
        isListeningForInput = false
        if keyConnection then
            keyConnection:Disconnect()
            keyConnection = nil
        end
        WindUI:Notify({
            Title = "Keybind",
            Content = "Key binding cancelled",
            Duration = 2
        })
        return
    end
    
    isListeningForInput = true
    WindUI:Notify({
        Title = "Keybind",
        Content = "Press any key to bind...",
        Duration = 3
    })
    
    -- Listen for key input
    keyConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.Keyboard then
            currentKey = input.KeyCode
            isListeningForInput = false
            if keyConnection then
                keyConnection:Disconnect()
                keyConnection = nil
            end
            
            -- Save the new keybind
            saveKeybind()
            
            WindUI:Notify({
                Title = "Keybind",
                Content = "Key bound to: " .. getCleanKeyName(currentKey),
                Duration = 3
            })
            -- Try to update the displayed description on the button
            pcall(function()
                -- updateKeybindButtonDesc uses the global keyBindButton if present
                updateKeybindButtonDesc()
            end)
        end
    end)
end

-- Function to handle manual revive key binding
local function bindManualReviveKey(keyBindButtonParam)
    local targetButton = keyBindButtonParam or manualReviveKeyBindButton

    if isListeningForManualRevive then 
        -- If already listening, cancel it
        isListeningForManualRevive = false
        if manualReviveKeyConnection then
            manualReviveKeyConnection:Disconnect()
            manualReviveKeyConnection = nil
        end
        WindUI:Notify({
            Title = "Manual Revive Keybind",
            Content = "Key binding cancelled",
            Duration = 2
        })
        return
    end
    
    isListeningForManualRevive = true
    WindUI:Notify({
        Title = "Manual Revive Keybind",
        Content = "Press any key to bind...",
        Duration = 3
    })
    
    -- Listen for key input
    manualReviveKeyConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.Keyboard then
            manualReviveKey = input.KeyCode
            isListeningForManualRevive = false
            if manualReviveKeyConnection then
                manualReviveKeyConnection:Disconnect()
                manualReviveKeyConnection = nil
            end
            
            -- Save the new keybind
            saveManualReviveKeybind()
            
            WindUI:Notify({
                Title = "Manual Revive Keybind",
                Content = "Key bound to: " .. getCleanKeyName(manualReviveKey),
                Duration = 3
            })
            -- Try to update the displayed description on the button
            pcall(function()
                updateManualReviveKeybindButtonDesc()
            end)
        end
    end)
end

-- Function to handle key press functionality (robust against missing IsOpen)
local function handleKeyPress(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == currentKey then
        -- Determine visibility robustly
        local success, isVisible = pcall(function()
            if Window and type(Window.IsOpen) == "function" then
                return Window:IsOpen()
            elseif Window and Window.Opened ~= nil then
                return Window.Opened
            else
                return isWindowOpen
            end
        end)
        if not success then
            isVisible = isWindowOpen
        end

        if isVisible then
            if Window and type(Window.Close) == "function" then
                pcall(function() Window:Close() end)
            else
                -- Fallback: mark state and call OnClose callback if available
                isWindowOpen = false
                if Window and type(Window.OnClose) == "function" then
                    pcall(function() Window:OnClose() end)
                end
            end
        else
            if Window and type(Window.Open) == "function" then
                pcall(function() Window:Open() end)
            else
                isWindowOpen = true
                if Window and type(Window.OnOpen) == "function" then
                    pcall(function() Window:OnOpen() end)
                end
            end
        end
    end
end

-- Connect the key functionality
keyInputConnection = game:GetService("UserInputService").InputBegan:Connect(handleKeyPress)

-- Add tags and time tag
Window:SetIconSize(48)
Window:Tag({
    Title = "v1.0.0",
    Color = Color3.fromHex("#30ff6a")
})
Window:Tag({
    Title = "Beta",
    Color = Color3.fromHex("#315dff")
})

-- Theme switcher button
Window:CreateTopbarButton("theme-switcher", "moon", function()
    WindUI:SetTheme(WindUI:GetCurrentTheme() == "Dark" and "Light" or "Dark")
end, 990)

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
-- Player reference
local player = Players.LocalPlayer
local placeId = game.PlaceId
local jobId = game.JobId
local PlayerGui = player:WaitForChild("PlayerGui", 5)
-- Feature states
local featureStates = {
    InfiniteJump = false,
    AutoJump = false,
    Fly = false,
    SpeedHack = false,
    JumpBoost = false,
    AntiAFK = false,             -- Bật sẵn Anti AFK
    AutoCarry = false,
    FullBright = false,          -- Bật sẵn FullBright
    NoFog = false,               -- Bật sẵn No Fog
    GameTimerDisplay = false,
    TimerDisplay = false,
    AutoVote = false,
    AutoSelfRevive = false,
    AutoWin = false,
    AutoMoneyFarm = false,
    AutoRevive = false,
    AutoTicketFarm = false,
    PlayerESP = {
        boxes = false,
        tracers = false,
        names = false,
        distance = false,
        rainbowBoxes = false,
        rainbowTracers = false,
        boxType = "3D",
        nameMode = "Username",
        highlight = false,
    },
    NextbotESP = {
        boxes = false,
        tracers = false,
        names = false,
        distance = false,
        rainbowBoxes = false,
        rainbowTracers = false,
        boxType = "3D",
    },
    DownedBoxESP = false,
    DownedTracer = false,
    DownedNameESP = false,
    DownedDistanceESP = false,
    DownedBoxType = "3D",
    DownedHighlight = false,
    TicketESP = {
        enabled = false,
        showTracers = true,
        showNames = true,
        showHighlight = true,
        tracerColor = Color3.fromRGB(255, 0, 0),
        nameColor = Color3.fromRGB(255, 100, 100), -- Màu đỏ nhạt
        highlightColor = Color3.fromRGB(255, 255, 0)
    },
    FlySpeed = 5,
    TpwalkValue = 1,
    JumpPower = 5,
    JumpMethod = "Hold",
    SelectedMap = 1,
    ClickTP = false
}

-- Character references
local character, humanoid, rootPart
local isJumpHeld = false

-- Fly Variables
local flying = false
local bodyVelocity, bodyGyro

-- Speed Hack Variables
local ToggleTpwalk = false
local TpwalkConnection

-- Jump Boost Variables
local jumpCount = 0
local MAX_JUMPS = math.huge

-- Auto Jump Variables
local AutoJumpConnection

-- Anti AFK Variables
local AntiAFKConnection

-- Auto Carry Variables
local AutoCarryConnection

-- Auto Revive Variables
local reviveRange = 5
local reviveDelay = 0.5
local reviveLoopHandle = nil
local interactEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("Interact")

-- Auto Carry Variables
local carryRange = 10
local carryDelay = 0.1

-- Auto Ticket Farm Variables
local ticketFarmDelay = 0.5
local autoTicketFarmConnection = nil

-- Click TP Variables
local clickTPConnection

-- Notify Variables
local lastCarriedPlayer = nil

-- ESP Variables
local playerEspElements = {}
local playerEspConnection = nil
local nextbotESPThread = nil
local downedTracerConnection
local downedNameESPConnection
local downedTracerLines = {}
local downedNameESPLabels = {}

-- Highlight Variables
local playerHighlights = {}
local downedHighlights = {}

-- Ticket ESP Variables
local ticketEspObjects = {}
local ticketEspConnection = nil
local ticketConnections = {}

-- Utility to safely clean up Drawing or Instance objects
local function safeCleanupObject(obj)
    if not obj then return end

    if typeof(obj) == "table" then
        for key, value in pairs(obj) do
            safeCleanupObject(value)
            obj[key] = nil
        end
        return
    end

    if typeof(obj) == "Instance" then
        obj:Destroy()
        return
    end

    local removed = false
    local valueType = typeof(obj)
    if valueType ~= "nil" then
        local ok = pcall(function()
            if obj.Remove then
                obj:Remove()
            elseif obj.Destroy then
                obj:Destroy()
            end
        end)
        removed = ok
    end

    if not removed and valueType == "table" then
        return
    end

    if not removed then
        pcall(function()
            obj.Visible = false
        end)
    end
end

-- Function to create highlight for player
local function createPlayerHighlight(character)
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "PlayerESP_Highlight"
    highlight.Adornee = character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = Color3.fromRGB(0, 255, 0) -- Green for players
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255) -- White outline
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = character
    
    return highlight
end

-- Function to create highlight for downed player
local function createDownedHighlight(character)
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "DownedESP_Highlight"
    highlight.Adornee = character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = Color3.fromRGB(255, 165, 0) -- Orange for downed players
    highlight.OutlineColor = Color3.fromRGB(255, 255, 0) -- Yellow outline
    highlight.FillTransparency = 0.3
    highlight.OutlineTransparency = 0
    highlight.Parent = character
    
    return highlight
end

-- Function to cleanup highlight
local function cleanupHighlight(highlight)
    if highlight and highlight.Parent then
        highlight:Destroy()
    end
end

-- Ticket ESP Functions
-- Get object position helper function for tickets
local function getTicketPosition(object)
    if object:IsA("BasePart") then
        return object.Position
    elseif object:IsA("Model") then
        local primaryPart = object.PrimaryPart
        if primaryPart then
            return primaryPart.Position
        else
            local humanoidRoot = object:FindFirstChild("HumanoidRootPart")
            if humanoidRoot then
                return humanoidRoot.Position
            else
                for _, child in pairs(object:GetChildren()) do
                    if child:IsA("BasePart") then
                        return child.Position
                    end
                end
            end
        end
    end
    return nil
end

-- Create ESP for a ticket
local function createTicketESP(object)
    if not object or not object.Parent then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Get object position
    local objectPosition = getTicketPosition(object)
    if not objectPosition then return end
    
    -- Calculate distance
    local distance = (humanoidRootPart.Position - objectPosition).Magnitude
    
    -- Create GUI for name
    local nameGui = nil
    if featureStates.TicketESP.showNames then
        nameGui = Instance.new("BillboardGui")
        nameGui.Name = "TicketESP_Name"
        nameGui.Size = UDim2.new(0, 200, 0, 50)
        nameGui.StudsOffset = Vector3.new(0, 2, 0)
        nameGui.AlwaysOnTop = true
        nameGui.Parent = object
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = "Ticket [" .. math.floor(distance) .. " m]"
        nameLabel.TextColor3 = Color3.fromRGB(255, 100, 100) -- Màu đỏ nhạt
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        nameLabel.TextScaled = false
        nameLabel.TextSize = 14 -- Cỡ chữ nhỏ như ESP player
        nameLabel.Font = Enum.Font.SourceSansBold
        nameLabel.Parent = nameGui
    end
    
    -- Create tracer
    local tracer = nil
    if featureStates.TicketESP.showTracers then
        tracer = Drawing.new("Line")
        tracer.Visible = true
        tracer.Color = featureStates.TicketESP.tracerColor
        tracer.Thickness = 2
        tracer.Transparency = 0.8
    end
    
    -- Create highlight
    local highlight = nil
    if featureStates.TicketESP.showHighlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "TicketESP_Highlight"
        highlight.FillColor = featureStates.TicketESP.highlightColor
        highlight.OutlineColor = featureStates.TicketESP.highlightColor
        highlight.FillTransparency = 0.3
        highlight.OutlineTransparency = 0
        highlight.Parent = object
    end
    
    -- Store ESP objects
    ticketEspObjects[object] = {
        nameGui = nameGui,
        tracer = tracer,
        highlight = highlight,
        object = object
    }
end

-- Remove ESP from a ticket
local function removeTicketESP(object)
    local espData = ticketEspObjects[object]
    if espData then
        if espData.nameGui then
            espData.nameGui:Destroy()
        end
        if espData.tracer then
            espData.tracer:Remove()
        end
        if espData.highlight then
            espData.highlight:Destroy()
        end
        ticketEspObjects[object] = nil
    end
end

-- Update Ticket ESP
local function updateTicketESP()
    if not featureStates.TicketESP.enabled then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    for object, espData in pairs(ticketEspObjects) do
        if object and object.Parent then
            local objectPosition = getTicketPosition(object)
            if not objectPosition then
                removeTicketESP(object)
            else
            
            -- Update tracer
            if espData.tracer and featureStates.TicketESP.showTracers then
                local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(objectPosition)
                if onScreen then
                    local screenCenter = workspace.CurrentCamera.ViewportSize / 2
                    espData.tracer.From = Vector2.new(screenCenter.X, screenCenter.Y)
                    espData.tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                    espData.tracer.Visible = true
                else
                    espData.tracer.Visible = false
                end
            end
            
            -- Update name (no distance)
            if espData.nameGui and espData.nameGui.Parent then
                local distance = (humanoidRootPart.Position - objectPosition).Magnitude
                local nameLabel = espData.nameGui:FindFirstChild("NameLabel")
                if nameLabel then
                    nameLabel.Text = "Ticket [" .. math.floor(distance) .. "m ]"
                end
            end
            end
        else
            -- Object no longer exists, remove ESP
            removeTicketESP(object)
        end
    end
end

-- Find and create ESP for all tickets
local function findTickets()
    local ticketsFolder = workspace:FindFirstChild("Game")
    if ticketsFolder then
        ticketsFolder = ticketsFolder:FindFirstChild("Effects")
        if ticketsFolder then
            ticketsFolder = ticketsFolder:FindFirstChild("Tickets")
            if ticketsFolder then
                for _, ticket in pairs(ticketsFolder:GetChildren()) do
                    if ticket:IsA("BasePart") or ticket:IsA("Model") then
                        createTicketESP(ticket)
                    end
                end
            end
        end
    end
end

-- Monitor for new tickets
local function monitorTickets()
    local ticketsFolder = workspace:FindFirstChild("Game")
    if ticketsFolder then
        ticketsFolder = ticketsFolder:FindFirstChild("Effects")
        if ticketsFolder then
            ticketsFolder = ticketsFolder:FindFirstChild("Tickets")
            if ticketsFolder then
                -- Connect to child added
                local connection = ticketsFolder.ChildAdded:Connect(function(child)
                    task.wait(0.1) -- Small delay to ensure object is fully loaded
                    if child:IsA("BasePart") or child:IsA("Model") then
                        createTicketESP(child)
                    end
                end)
                
                -- Connect to child removed
                local connection2 = ticketsFolder.ChildRemoved:Connect(function(child)
                    removeTicketESP(child)
                end)
                
                table.insert(ticketConnections, connection)
                table.insert(ticketConnections, connection2)
            end
        end
    end
end

-- Start Ticket ESP
local function startTicketESP()
    if ticketEspConnection then return end
    findTickets()
    monitorTickets()
    ticketEspConnection = RunService.Heartbeat:Connect(updateTicketESP)
end

-- Stop Ticket ESP
local function stopTicketESP()
    if ticketEspConnection then
        ticketEspConnection:Disconnect()
        ticketEspConnection = nil
    end
    
    for _, connection in pairs(ticketConnections) do
        connection:Disconnect()
    end
    ticketConnections = {}
    
    for object, espData in pairs(ticketEspObjects) do
        removeTicketESP(object)
    end
    ticketEspObjects = {}
end

-- Function to draw 3D box
local function draw3DBox(esp, hrp, camera, boxColor)
    local size = Vector3.new(3, 5, 2)
    local offsets = {
        Vector3.new( size.X/2,  size.Y/2,  size.Z/2),
        Vector3.new( size.X/2,  size.Y/2, -size.Z/2),
        Vector3.new( size.X/2, -size.Y/2,  size.Z/2),
        Vector3.new( size.X/2, -size.Y/2, -size.Z/2),
        Vector3.new(-size.X/2,  size.Y/2,  size.Z/2),
        Vector3.new(-size.X/2,  size.Y/2, -size.Z/2),
        Vector3.new(-size.X/2, -size.Y/2,  size.Z/2),
        Vector3.new(-size.X/2, -size.Y/2, -size.Z/2),
    }
    local screenPoints = {}
    for i, offset in ipairs(offsets) do
        local worldPos = hrp.CFrame * offset
        local vec, onScreen = camera:WorldToViewportPoint(worldPos)
        screenPoints[i] = {pos = Vector2.new(vec.X, vec.Y), depth = vec.Z, onScreen = onScreen}
    end
    if not esp.boxLines then
        esp.boxLines = {}
        for i = 1, 12 do
            local line = Drawing.new("Line")
            line.Thickness = 2
            table.insert(esp.boxLines, line)
        end
    end
    local edges = {
        {1,2}, {1,3}, {1,5},
        {2,4}, {2,6},
        {3,4}, {3,7},
        {5,6}, {5,7},
        {4,8}, {6,8}, {7,8}
    }
    local lineIndex = 1
    for _, edge in ipairs(edges) do
        local p1 = screenPoints[edge[1]]
        local p2 = screenPoints[edge[2]]
        local line = esp.boxLines[lineIndex]
        line.Color = boxColor
        if p1.depth > 0 and p2.depth > 0 then
            line.From = p1.pos
            line.To = p2.pos
            line.Visible = true
        else
            line.Visible = false
        end
        lineIndex = lineIndex + 1
    end
end

-- Player ESP Module
local function updatePlayerESP()
    if not camera then camera = workspace.CurrentCamera end
    local screenBottomCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
    local currentTargets = {}

    if workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players") then
        for _, model in pairs(workspace.Game.Players:GetChildren()) do
            if model:IsA("Model") and model:FindFirstChild("HumanoidRootPart") then
                local isPlayer = Players:GetPlayerFromCharacter(model) ~= nil
                local humanoid = model:FindFirstChild("Humanoid")
                if isPlayer and model.Name ~= player.Name and humanoid and humanoid.Health > 0 then
                    currentTargets[model] = true
                    if not playerEspElements[model] then
                        playerEspElements[model] = {
                            box = Drawing.new("Square"),
                            tracer = Drawing.new("Line"),
                            name = Drawing.new("Text"),
                            distance = Drawing.new("Text"),
                            downedConnection = nil,
                            highlight = nil
                        }
                        playerEspElements[model].box.Thickness = 2
                        playerEspElements[model].box.Filled = false
                        playerEspElements[model].tracer.Thickness = 1
                        playerEspElements[model].name.Size = 14
                        playerEspElements[model].name.Center = true
                        playerEspElements[model].name.Outline = true
                        playerEspElements[model].distance.Size = 14
                        playerEspElements[model].distance.Center = true
                        playerEspElements[model].distance.Outline = true
                    end

                    local esp = playerEspElements[model]
                    local hrp = model.HumanoidRootPart
                    local vector, onScreen = camera:WorldToViewportPoint(hrp.Position)

                    if onScreen then
                        local topY = camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0)).Y
                        local bottomY = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0)).Y
                        local size = (bottomY - topY) / 2
                        local toggles = featureStates.PlayerESP

                        if toggles.boxes then
                            local boxColor
                            if toggles.rainbowBoxes then
                                local hue = (tick() % 5) / 5
                                boxColor = Color3.fromHSV(hue, 1, 1)
                            else
                                boxColor = Color3.fromRGB(0, 255, 0)
                            end
                            if toggles.boxType == "2D" then
                                -- Show 2D box and hide 3D box lines
                                esp.box.Visible = true
                                esp.box.Size = Vector2.new(size * 2, size * 3)
                                esp.box.Position = Vector2.new(vector.X - size, vector.Y - size * 1.5)
                                esp.box.Color = boxColor
                                if esp.boxLines then
                                    for _, line in ipairs(esp.boxLines) do
                                        line.Visible = false
                                    end
                                end
                            else
                                -- Show 3D box and hide 2D box
                                esp.box.Visible = false
                                draw3DBox(esp, hrp, camera, boxColor)
                            end
                        else
                            esp.box.Visible = false
                            if esp.boxLines then
                                for _, line in ipairs(esp.boxLines) do
                                    line.Visible = false
                                end
                            end
                        end

                    if toggles.tracers then
                        esp.tracer.Visible = true
                        esp.tracer.From = screenBottomCenter
                        esp.tracer.To = Vector2.new(vector.X, vector.Y)
                        if toggles.rainbowTracers then
                            local hue = (tick() % 5) / 5
                            esp.tracer.Color = Color3.fromHSV(hue, 1, 1)
                        else
                            esp.tracer.Color = Color3.fromRGB(0, 255, 0)
                        end
                    else
                        esp.tracer.Visible = false
                    end

                    if toggles.names then
                        esp.name.Visible = true
                        local plr = Players:GetPlayerFromCharacter(model)
                        local username = model.Name
                        local displayName = plr and plr.DisplayName or username
                        if toggles.nameMode == "Display Name" then
                            esp.name.Text = displayName
                        elseif toggles.nameMode == "Username + Display" then
                            if displayName ~= username then
                                esp.name.Text = string.format("%s (%s)", displayName, username)
                            else
                                esp.name.Text = username
                            end
                        else
                            esp.name.Text = username
                        end
                        esp.name.Position = Vector2.new(vector.X, vector.Y - size * 1.5 - 20)
                        esp.name.Color = Color3.fromRGB(255, 255, 255)
                    else
                        esp.name.Visible = false
                    end

                        if toggles.distance then
                            local distance = (Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (Players.LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude) or 0
                            esp.distance.Visible = true
                            esp.distance.Text = string.format("%.1f", distance)
                            esp.distance.Position = Vector2.new(vector.X, vector.Y + size * 1.5 + 5)
                            esp.distance.Color = Color3.fromRGB(255, 255, 255)
                        else
                            esp.distance.Visible = false
                        end

                        -- Handle Player Highlight
                        if toggles.highlight then
                            if not esp.highlight then
                                esp.highlight = createPlayerHighlight(model)
                            end
                            if esp.highlight then
                                esp.highlight.Enabled = true
                            end
                        else
                            if esp.highlight then
                                esp.highlight.Enabled = false
                            end
                        end
                    else
                        esp.box.Visible = false
                        esp.tracer.Visible = false
                        esp.name.Visible = false
                        esp.distance.Visible = false
                        if esp.boxLines then
                            for _, line in ipairs(esp.boxLines) do
                                line.Visible = false
                            end
                        end
                        if esp.highlight then
                            esp.highlight.Enabled = false
                        end
                    end
                end
            end
        end
    end

    for target, esp in pairs(playerEspElements) do
        if not currentTargets[target] then
            for _, drawing in pairs(esp) do
                safeCleanupObject(drawing)
            end
        if esp.boxLines then
            for _, line in ipairs(esp.boxLines) do
                safeCleanupObject(line)
            end
        end
        -- Cleanup highlight
        if esp.highlight then
            cleanupHighlight(esp.highlight)
        end
        -- Disconnect downed state listener
        if esp.downedConnection then
            esp.downedConnection:Disconnect()
            esp.downedConnection = nil
        end
            playerEspElements[target] = nil
        end
    end
end

local function startPlayerESP()
if playerEspConnection then return end
playerEspConnection = RunService.RenderStepped:Connect(updatePlayerESP)
-- Force update ESP immediately to catch any existing players
updatePlayerESP()
end

local function stopPlayerESP()
    if playerEspConnection then
        playerEspConnection:Disconnect()
        playerEspConnection = nil
    end
    for model, esp in pairs(playerEspElements) do
        for _, drawing in pairs(esp) do
            safeCleanupObject(drawing)
        end
        if esp.boxLines then
            for _, line in ipairs(esp.boxLines) do
                safeCleanupObject(line)
            end
        end
        -- Cleanup highlight
        if esp.highlight then
            cleanupHighlight(esp.highlight)
        end
        -- Disconnect downed state listener
        if esp.downedConnection then
            esp.downedConnection:Disconnect()
            esp.downedConnection = nil
        end
    end
    playerEspElements = {}
end

-- Nextbot Name ESP (Standalone Version)
local nextBotNames = {}
if ReplicatedStorage:FindFirstChild("NPCs") then
    for _, npc in ipairs(ReplicatedStorage.NPCs:GetChildren()) do
        table.insert(nextBotNames, npc.Name)
    end
end

local function isNextbotModel(model)
    if not model or not model.Name then return false end
    for _, name in ipairs(nextBotNames) do
        if model.Name == name then return true end
    end
    return false
end

-- Nextbot ESP Variables
local nextbotEspElements = {}
local nextbotEspConnection = nil

-- Nextbot Name ESP Function
local function updateNextbotESP()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local currentTargets = {}

    local function processModel(model)
        if not model or not model:IsA("Model") or not model:FindFirstChild("HumanoidRootPart") then return end
        if not isNextbotModel(model) then return end
        currentTargets[model] = true

        if not nextbotEspElements[model] then
            nextbotEspElements[model] = {
                name = Drawing.new("Text"),
                distance = Drawing.new("Text"),
                box = Drawing.new("Square"),
                boxLines = nil,
                tracer = Drawing.new("Line")
            }
            nextbotEspElements[model].name.Size = 14
            nextbotEspElements[model].name.Center = true
            nextbotEspElements[model].name.Outline = true
            nextbotEspElements[model].name.Color = Color3.fromRGB(255, 0, 0) -- Red color for nextbots
            nextbotEspElements[model].distance.Size = 14
            nextbotEspElements[model].distance.Center = true
            nextbotEspElements[model].distance.Outline = true
            nextbotEspElements[model].distance.Color = Color3.fromRGB(255, 255, 255)
            nextbotEspElements[model].box.Thickness = 2
            nextbotEspElements[model].box.Filled = false
            nextbotEspElements[model].tracer.Thickness = 1
        end

        local esp = nextbotEspElements[model]
        local hrp = model.HumanoidRootPart
        local vector, onScreen = camera:WorldToViewportPoint(hrp.Position)

        if onScreen then
            -- Show name ESP
            esp.name.Visible = true
            esp.name.Text = model.Name
            esp.name.Position = Vector2.new(vector.X, vector.Y - 40) -- Position above head
            
            -- Add distance if wanted
            local distance = (player.Character and player.Character:FindFirstChild("HumanoidRootPart") and 
                (player.Character.HumanoidRootPart.Position - hrp.Position).Magnitude) or 0
            esp.name.Text = model.Name .. " (" .. math.floor(distance) .. ")"
            esp.distance.Visible = featureStates.NextbotESP.distance
            if esp.distance.Visible then
                esp.distance.Text = string.format("%.1f", distance)
                esp.distance.Position = Vector2.new(vector.X, vector.Y + 35)
            end

            local toggles = featureStates.NextbotESP
            if toggles.boxes then
                local boxColor
                if toggles.rainbowBoxes then
                    local hue = (tick() % 5) / 5
                    boxColor = Color3.fromHSV(hue, 1, 1)
                else
                    boxColor = Color3.fromRGB(255, 0, 0)
                end
                if toggles.boxType == "2D" then
                    esp.box.Visible = true
                    local topY = camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0)).Y
                    local bottomY = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0)).Y
                    local size = (bottomY - topY) / 2
                    esp.box.Size = Vector2.new(size * 2, size * 3)
                    esp.box.Position = Vector2.new(vector.X - size, vector.Y - size * 1.5)
                    esp.box.Color = boxColor
                    if esp.boxLines then
                        for _, line in ipairs(esp.boxLines) do
                            line.Visible = false
                        end
                    end
                else
                    esp.box.Visible = false
                    draw3DBox(esp, hrp, camera, boxColor)
                end
            else
                esp.box.Visible = false
                if esp.boxLines then
                    for _, line in ipairs(esp.boxLines) do
                        line.Visible = false
                    end
                end
            end

            if toggles.tracers then
                esp.tracer.Visible = true
                esp.tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                esp.tracer.To = Vector2.new(vector.X, vector.Y)
                if toggles.rainbowTracers then
                    local hue = (tick() % 5) / 5
                    esp.tracer.Color = Color3.fromHSV(hue, 1, 1)
                else
                    esp.tracer.Color = Color3.fromRGB(255, 0, 0)
                end
            else
                esp.tracer.Visible = false
            end
        else
            esp.name.Visible = false
            esp.distance.Visible = false
            esp.box.Visible = false
            esp.tracer.Visible = false
            if esp.boxLines then
                for _, line in ipairs(esp.boxLines) do
                    line.Visible = false
                end
            end
        end
    end

    -- Check in Game.Players folder
    if workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players") then
        for _, model in pairs(workspace.Game.Players:GetChildren()) do
            processModel(model)
        end
    end

    -- Check in NPCs folder
    if workspace:FindFirstChild("NPCs") then
        for _, model in pairs(workspace.NPCs:GetChildren()) do
            processModel(model)
        end
    end

    -- Clean up removed nextbots
    for target, esp in pairs(nextbotEspElements) do
        if not currentTargets[target] then
            for _, drawing in pairs(esp) do
                safeCleanupObject(drawing)
            end
        nextbotEspElements[target] = nil
        end
    end
end

-- Start Nextbot Name ESP
local function startNextbotNameESP()
    if nextbotEspConnection then 
        nextbotEspConnection:Disconnect()
    end
    nextbotEspConnection = RunService.RenderStepped:Connect(updateNextbotESP)
    
    -- Initial scan
    updateNextbotESP()
end

-- Stop Nextbot Name ESP
local function stopNextbotNameESP()
    if nextbotEspConnection then
        nextbotEspConnection:Disconnect()
        nextbotEspConnection = nil
    end
    
    for _, esp in pairs(nextbotEspElements) do
        for _, drawing in pairs(esp) do
            safeCleanupObject(drawing)
        end
    end
    nextbotEspElements = {}
end

-- Auto-detect when new nextbots spawn
local function setupNextbotDetection()
    -- Monitor Game.Players folder
    if workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players") then
        workspace.Game.Players.ChildAdded:Connect(function(child)
            if child:IsA("Model") then
                task.wait(0.5) -- Wait for model to fully load
                if isNextbotModel(child) and nextbotEspConnection then
                end
            end
        end)
    end
    
    -- Monitor NPCs folder
    if workspace:FindFirstChild("NPCs") then
        workspace.NPCs.ChildAdded:Connect(function(child)
            if child:IsA("Model") then
                task.wait(0.5) -- Wait for model to fully load
                if isNextbotModel(child) and nextbotEspConnection then
                end
            end
        end)
    end
end

-- Simple toggle system
local espEnabled = false

-- Function to toggle ESP on/off
local function toggleNextbotNameESP()
    if espEnabled then
        stopNextbotNameESP()
        espEnabled = false
    else
        startNextbotNameESP()
        setupNextbotDetection()
        espEnabled = true
    end
end

-- Auto-stop when player leaves (safety)
game:GetService("Players").PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        stopNextbotNameESP()
    end
end)

-- Visual Variables
local originalBrightness = Lighting.Brightness
local originalFogEnd = Lighting.FogEnd
local originalOutdoorAmbient = Lighting.OutdoorAmbient
local originalAmbient = Lighting.Ambient
local originalGlobalShadows = Lighting.GlobalShadows
local originalFOV = workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70
local originalAtmospheres = {}

-- Store existing Atmosphere objects
for _, v in pairs(Lighting:GetDescendants()) do
    if v:IsA("Atmosphere") then
        table.insert(originalAtmospheres, v)
    end
end
local function startNoFog()
    originalFogEnd = Lighting.FogEnd
    Lighting.FogEnd = 1000000
    for _, v in pairs(Lighting:GetDescendants()) do
        if v:IsA("Atmosphere") then
            v:Destroy()
        end
    end
end
-- Function to check if player is grounded
local function isPlayerGrounded()
    if not character or not humanoid or not rootPart then
        return false
    end
    local rayOrigin = rootPart.Position
    local rayDirection = Vector3.new(0, -3, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    return raycastResult ~= nil
end

-- Function to make player jump
local function bouncePlayer()
    if character and humanoid and rootPart and humanoid.Health > 0 then
        if not isPlayerGrounded() then
            humanoid.Jump = true
            local jumpVelocity = math.sqrt(1.5 * humanoid.JumpHeight * workspace.Gravity) * 1.5
            rootPart.Velocity = Vector3.new(rootPart.Velocity.X, jumpVelocity * humanoid.JumpPower / 50, rootPart.Velocity.Z)
        end
    end
end

-- Function to get distance from local player
local function getDistanceFromPlayer(targetPosition)
    if not character or not rootPart then return 0 end
    return (targetPosition - rootPart.Position).Magnitude
end

-- Auto Jump Functions
local function startAutoJump()
    AutoJumpConnection = RunService.Heartbeat:Connect(function()
        if featureStates.AutoJump and character and humanoid and rootPart and humanoid.Health > 0 then
            humanoid.Jump = true
        end
    end)
end

local function stopAutoJump()
    if AutoJumpConnection then
        AutoJumpConnection:Disconnect()
        AutoJumpConnection = nil
    end
end

-- Auto Revive Functions
local function isPlayerDowned(pl)
    if not pl or not pl.Character then return false end
    local char = pl.Character
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid and humanoid.Health <= 0 then
        return true
    end
    if char.GetAttribute and char:GetAttribute("Downed") == true then
        return true
    end
    return false
end

local function startAutoRevive()
    if reviveLoopHandle then return end
    reviveLoopHandle = task.spawn(function()
        while featureStates.AutoRevive do
            local LocalPlayer = Players.LocalPlayer
            if LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local myHRP = LocalPlayer.Character.HumanoidRootPart
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl ~= LocalPlayer then
                        local char = pl.Character
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            if isPlayerDowned(pl) then
                                local hrp = char.HumanoidRootPart
                                local success, dist = pcall(function()
                                    return (myHRP.Position - hrp.Position).Magnitude
                                end)
                                if success and dist and dist <= reviveRange then
                                    pcall(function()
                                        interactEvent:FireServer("Revive", true, pl.Name)
                                        WindUI:Notify({
                                            Title = "Auto Revive" .. pl.Name,
                                            Content = "Reviving " .. pl.Name,
                                            Duration = 2
                                        })
                                    end)
                                end
                            end
                        end
                    end
                end
            end
            task.wait(reviveDelay)
        end
        reviveLoopHandle = nil
    end)
end

local function stopAutoRevive()
    featureStates.AutoRevive = false
    if reviveLoopHandle then
        task.cancel(reviveLoopHandle)
        reviveLoopHandle = nil
    end
end

-- Fly Functions
local function startFlying()
    if not character or not humanoid or not rootPart then return end
    flying = true
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = rootPart
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.CFrame = rootPart.CFrame
    bodyGyro.Parent = rootPart
    humanoid.PlatformStand = true
end

local function stopFlying()
    flying = false
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end
    if humanoid then
        humanoid.PlatformStand = false
    end
end

local function updateFly()
    if not flying or not bodyVelocity or not bodyGyro then return end
    local camera = workspace.CurrentCamera
    local cameraCFrame = camera.CFrame
    local direction = Vector3.new(0, 0, 0)
    local moveDirection = humanoid.MoveDirection
    if moveDirection.Magnitude > 0 then
        local forwardVector = cameraCFrame.LookVector
        local rightVector = cameraCFrame.RightVector
        local forwardComponent = moveDirection:Dot(forwardVector) * forwardVector
        local rightComponent = moveDirection:Dot(rightVector) * rightVector
        direction = direction + (forwardComponent + rightComponent).Unit * moveDirection.Magnitude
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) or humanoid.Jump then
        direction = direction + Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        direction = direction - Vector3.new(0, 1, 0)
    end
    bodyVelocity.Velocity = direction.Magnitude > 0 and direction.Unit * (featureStates.FlySpeed * 2) or Vector3.new(0, 0, 0)
    bodyGyro.CFrame = cameraCFrame
end

-- Speed Hack (TP Walk) Functions
local function Tpwalking()
    if ToggleTpwalk and character and humanoid and rootPart then
        local moveDirection = humanoid.MoveDirection
        local moveDistance = featureStates.TpwalkValue
        local origin = rootPart.Position
        local direction = moveDirection * moveDistance
        local targetPosition = origin + direction
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {character}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        local raycastResult = workspace:Raycast(origin, direction, raycastParams)
        if raycastResult then
            local hitPosition = raycastResult.Position
            local distanceToHit = (hitPosition - origin).Magnitude
            if distanceToHit < math.abs(moveDistance) then
                targetPosition = origin + (direction.Unit * (distanceToHit - 0.1))
            end
        end
        rootPart.CFrame = CFrame.new(targetPosition) * rootPart.CFrame.Rotation
        rootPart.CanCollide = true
    end
end

local function startTpwalk()
    ToggleTpwalk = true
    if TpwalkConnection then
        TpwalkConnection:Disconnect()
    end
    TpwalkConnection = RunService.Heartbeat:Connect(Tpwalking)
end

local function stopTpwalk()
    ToggleTpwalk = false
    if TpwalkConnection then
        TpwalkConnection:Disconnect()
        TpwalkConnection = nil
    end
    if rootPart then
        rootPart.CanCollide = false
    end
end

-- Jump Boost Functions
-- Define critical functions at the top
local function setupJumpBoost()
    if not character or not humanoid then return end
    humanoid.StateChanged:Connect(function(oldState, newState)
        if newState == Enum.HumanoidStateType.Landed then
            jumpCount = 0
        end
    end)
    humanoid.Jumping:Connect(function(isJumping)
        if isJumping and featureStates.JumpBoost and jumpCount < MAX_JUMPS then
            jumpCount = jumpCount + 1
            humanoid.JumpHeight = featureStates.JumpPower
            if jumpCount > 1 then
                rootPart:ApplyImpulse(Vector3.new(0, featureStates.JumpPower * rootPart.Mass, 0))
            end
        end
    end)
end

local function reapplyFeatures()
    if featureStates.Fly then
        if flying then stopFlying() end
        startFlying()
    end
end

local function startJumpBoost()
    if humanoid then
        humanoid.JumpPower = featureStates.JumpPower
    end
end

local function stopJumpBoost()
    jumpCount = 0
    if humanoid then
        humanoid.JumpPower = 50
    end
end

-- Anti AFK Functions
local function startAntiAFK()
    AntiAFKConnection = player.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end

local function stopAntiAFK()
    if AntiAFKConnection then
        AntiAFKConnection:Disconnect()
        AntiAFKConnection = nil
    end
end

-- Auto Carry Functions
-- Function to check if player is currently carrying someone
local function isPlayerCarrying()
    local char = player.Character
    if not char or not char.GetAttribute then
        return false
    end
    return char:GetAttribute("Carrying") == true
end

-- Function to get the name of the player being carried (if any)
local function getCarriedPlayerName()
    local char = player.Character
    if not char or not char.GetAttribute then
        return nil
    end
    return char:GetAttribute("CarriedPlayer") or "Unknown"
end

local function startAutoCarry()
    if AutoCarryConnection then return end
    AutoCarryConnection = task.spawn(function()
        while featureStates.AutoCarry do
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            -- Check if player is already carrying someone
            local isAlreadyCarrying = isPlayerCarrying()
            
            -- Notify if currently carrying someone (only once per player)
            if isAlreadyCarrying and isAlreadyCarrying ~= "Unknown" and isAlreadyCarrying ~= lastCarriedPlayer then
                WindUI:Notify({
                    Title = "Auto Carry",
                    Content = "Carrying " .. isAlreadyCarrying,
                    Duration = 2
                })
                lastCarriedPlayer = isAlreadyCarrying
            elseif not isAlreadyCarrying then
                lastCarriedPlayer = nil
            end
            
            -- Only try to carry if not already carrying someone
            if hrp and not isAlreadyCarrying then
                for _, other in ipairs(Players:GetPlayers()) do
                    if other ~= player and other.Character and other.Character:FindFirstChild("HumanoidRootPart") then
                        local dist = (hrp.Position - other.Character.HumanoidRootPart.Position).Magnitude
                        if dist <= carryRange then
                            local args = { "Carry", [3] = other.Name }
                            pcall(function()
                                game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Character"):WaitForChild("Interact"):FireServer(unpack(args))
                            end)
                            -- Break after attempting to carry one person
                            break
                        end
                    end
                end
            end
            task.wait(carryDelay)
        end
        AutoCarryConnection = nil
    end)
end

local function stopAutoCarry()
    featureStates.AutoCarry = false
    if AutoCarryConnection then
        task.cancel(AutoCarryConnection)
        AutoCarryConnection = nil
    end
end

-- FullBright Functions
local function startFullBright()
    originalBrightness = Lighting.Brightness
    originalOutdoorAmbient = Lighting.OutdoorAmbient
    originalAmbient = Lighting.Ambient
    originalGlobalShadows = Lighting.GlobalShadows
    Lighting.Brightness = 2
    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    Lighting.GlobalShadows = false
end

local function stopFullBright()
    Lighting.Brightness = originalBrightness
    Lighting.OutdoorAmbient = originalOutdoorAmbient
    Lighting.Ambient = originalAmbient
    Lighting.GlobalShadows = originalGlobalShadows
end

-- Click TP Functions
local function startClickTP()
    if not clickTPConnection then
        clickTPConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 and featureStates.ClickTP then
                local camera = workspace.CurrentCamera
                local mouse = player:GetMouse()
                local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
                
                local raycastParams = RaycastParams.new()
                raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                raycastParams.FilterDescendantsInstances = {character}
                
                local raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, raycastParams)
                
                if raycastResult and rootPart then
                    local hitPosition = raycastResult.Position
                    local hitNormal = raycastResult.Normal
                    
                    -- Teleport to the hit position with a small offset
                    local teleportPosition = hitPosition + hitNormal * 2
                    rootPart.CFrame = CFrame.new(teleportPosition, teleportPosition + camera.CFrame.LookVector)
                end
            end
        end)
    end
end

local function stopClickTP()
    if clickTPConnection then
        clickTPConnection:Disconnect()
        clickTPConnection = nil
    end
end

-- Game Timer UI Variables
local function getServerLink()
    local placeId = game.PlaceId
    local jobId = game.JobId
    return string.format("https://www.roblox.com/games/start?placeId=%d&jobId=%s", placeId, jobId)
end

local function stopNoFog()
    Lighting.FogEnd = originalFogEnd
    for _, atmosphere in pairs(originalAtmospheres) do
        if not atmosphere.Parent then
            local newAtmosphere = Instance.new("Atmosphere")
            for _, prop in pairs({"Density", "Offset", "Color", "Decay", "Glare", "Haze"}) do
                if atmosphere[prop] then
                    newAtmosphere[prop] = atmosphere[prop]
                end
            end
            newAtmosphere.Parent = Lighting
        end
    end
end
-- Auto Vote Functions
local function fireVoteServer(mapNumber)
    local eventsFolder = ReplicatedStorage:WaitForChild("Events", 10)
    if eventsFolder then
        local playerFolder = eventsFolder:WaitForChild("Player", 10)
        if playerFolder then
            local voteEvent = playerFolder:WaitForChild("Vote", 10)
            if voteEvent and typeof(voteEvent) == "Instance" and voteEvent:IsA("RemoteEvent") then
                local args = {[1] = mapNumber}
                voteEvent:FireServer(unpack(args))
            end
        end
    end
end

local function startAutoVote()
    AutoVoteConnection = RunService.Heartbeat:Connect(function()
        fireVoteServer(featureStates.SelectedMap)
    end)
end

local function stopAutoVote()
    if AutoVoteConnection then
        AutoVoteConnection:Disconnect()
        AutoVoteConnection = nil
    end
end

-- Auto Self Revive Functions
local function startAutoSelfRevive()
    AutoSelfReviveConnection = RunService.Heartbeat:Connect(function()
        if character and character:GetAttribute("Downed") then
            ReplicatedStorage.Events.Player.ChangePlayerMode:FireServer(true)
        end
    end)
end

local function stopAutoSelfRevive()
    if AutoSelfReviveConnection then
        AutoSelfReviveConnection:Disconnect()
        AutoSelfReviveConnection = nil
    end
end

-- Auto Win Functions
local function startAutoWin()
    AutoWinConnection = RunService.Heartbeat:Connect(function()
        if character and rootPart then
            if character:GetAttribute("Downed") then
                ReplicatedStorage.Events.Player.ChangePlayerMode:FireServer(true)
                task.wait(0.5)
            end
            if not character:GetAttribute("Downed") then
                local securityPart = Instance.new("Part")
                securityPart.Name = "SecurityPartTemp"
                securityPart.Size = Vector3.new(10, 1, 10)
                securityPart.Position = Vector3.new(0, 500, 0)
                securityPart.Anchored = true
                securityPart.Transparency = 1
                securityPart.CanCollide = true
                securityPart.Parent = workspace
                rootPart.CFrame = securityPart.CFrame + Vector3.new(0, 3, 0)
                task.wait(0.5)
                securityPart:Destroy()
            end
        end
    end)
end

local function stopAutoWin()
    if AutoWinConnection then
        AutoWinConnection:Disconnect()
        AutoWinConnection = nil
    end
end

-- Auto Money Farm Functions
local function startAutoMoneyFarm()
    AutoMoneyFarmConnection = RunService.Heartbeat:Connect(function()
        if character and rootPart then
            if character:GetAttribute("Downed") then
                ReplicatedStorage.Events.Player.ChangePlayerMode:FireServer(true)
                task.wait(0.5)
            end
            local downedPlayerFound = false
            local playersInGame = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
            if playersInGame then
                for _, v in pairs(playersInGame:GetChildren()) do
                    if v:IsA("Model") and v:GetAttribute("Downed") then
                        rootPart.CFrame = v.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                        ReplicatedStorage.Events.Character.Interact:FireServer("Revive", true, v)
                        task.wait(0.5)
                        downedPlayerFound = true
                        break
                    end
                end
            end
            local securityPart = Instance.new("Part")
            securityPart.Name = "SecurityPartTemp"
            securityPart.Size = Vector3.new(10, 1, 10)
            securityPart.Position = Vector3.new(0, 500, 0)
            securityPart.Anchored = true
            securityPart.Transparency = 1
            securityPart.CanCollide = true
            securityPart.Parent = workspace
            rootPart.CFrame = securityPart.CFrame + Vector3.new(0, 3, 0)
        end
    end)
end

local function stopAutoMoneyFarm()
    if AutoMoneyFarmConnection then
        AutoMoneyFarmConnection:Disconnect()
        AutoMoneyFarmConnection = nil
    end
end

-- Auto Ticket Farm Functions
local function startAutoTicketFarm()
    if autoTicketFarmConnection then return end
    autoTicketFarmConnection = task.spawn(function()
        while featureStates.AutoTicketFarm do
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                -- Find tickets in workspace.Game.Effects.Tickets
                local ticketsFolder = workspace:FindFirstChild("Game")
                if ticketsFolder then
                    ticketsFolder = ticketsFolder:FindFirstChild("Effects")
                    if ticketsFolder then
                        ticketsFolder = ticketsFolder:FindFirstChild("Tickets")
                        if ticketsFolder then
                            local nearestTicket = nil
                            local nearestDistance = math.huge
                            
                            -- Find nearest ticket
                            for _, ticket in pairs(ticketsFolder:GetChildren()) do
                                if ticket:IsA("BasePart") or ticket:IsA("Model") then
                                    local ticketPosition = getTicketPosition(ticket)
                                    if ticketPosition then
                                        local distance = (hrp.Position - ticketPosition).Magnitude
                                        if distance < nearestDistance then
                                            nearestTicket = ticket
                                            nearestDistance = distance
                                        end
                                    end
                                end
                            end
                            
                            -- Teleport ticket to player if found
                            if nearestTicket then
                                pcall(function()
                                    if nearestTicket:IsA("BasePart") then
                                        -- If ticket is a BasePart, teleport it directly
                                        nearestTicket.CFrame = hrp.CFrame + Vector3.new(0, 2, 0)
                                    elseif nearestTicket:IsA("Model") then
                                        -- If ticket is a Model, try to teleport its PrimaryPart or HumanoidRootPart
                                        local targetPart = nearestTicket.PrimaryPart
                                        if not targetPart then
                                            targetPart = nearestTicket:FindFirstChild("HumanoidRootPart")
                                        end
                                        if not targetPart then
                                            -- Try to find any BasePart in the model
                                            for _, part in pairs(nearestTicket:GetChildren()) do
                                                if part:IsA("BasePart") then
                                                    targetPart = part
                                                    break
                                                end
                                            end
                                        end
                                        if targetPart then
                                            nearestTicket:SetPrimaryPartCFrame(CFrame.new(hrp.Position + Vector3.new(0, 2, 0)))
                                        end
                                    end
                                    
                                    WindUI:Notify({
                                        Title = "Auto Ticket Farm",
                                        Content = "Teleported ticket to player: " .. nearestTicket.Name,
                                        Duration = 2
                                    })
                                end)
                            end
                        end
                    end
                end
            end
            task.wait(ticketFarmDelay)
        end
        autoTicketFarmConnection = nil
    end)
end

local function stopAutoTicketFarm()
    featureStates.AutoTicketFarm = false
    if autoTicketFarmConnection then
        task.cancel(autoTicketFarmConnection)
        autoTicketFarmConnection = nil
    end
end

-- Manual Revive Function
local function manualRevive()
    pcall(function()
        ReplicatedStorage.Events.Player.ChangePlayerMode:FireServer(true)
    end)
end

-- Downed Tracer and Box ESP Functions
local function cleanupTracers(tracerTable)
    for _, drawing in ipairs(tracerTable) do
        safeCleanupObject(drawing)
    end
    tracerTable = {}
end

local function startDownedTracer()
    downedTracerConnection = RunService.Heartbeat:Connect(function()
        cleanupTracers(downedTracerLines)
        downedTracerLines = {}
        
        -- Cleanup old highlights
        for _, highlight in pairs(downedHighlights) do
            cleanupHighlight(highlight)
        end
        downedHighlights = {}
        
        local folder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
        if folder then
            for _, char in ipairs(folder:GetChildren()) do
                if char:IsA("Model") then
                    local team = char:GetAttribute("Team")
                    local downed = char:GetAttribute("Downed")
                    if team ~= "Nextbot" and char.Name ~= player.Name and downed == true then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp and workspace.CurrentCamera then
                            local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
                            
                            -- Handle Downed Highlight
                            if featureStates.DownedHighlight then
                                local highlight = createDownedHighlight(char)
                                if highlight then
                                    table.insert(downedHighlights, highlight)
                                end
                            end
                            
                            -- Process tracer and box ESP only if on screen
                            if onScreen then
                                -- Tracer
                                if featureStates.DownedTracer then
                                    local tracer = Drawing.new("Line")
                                    tracer.Color = Color3.fromRGB(255, 165, 0)
                                    tracer.Thickness = 2
                                    tracer.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y)
                                    tracer.To = Vector2.new(pos.X, pos.Y)
                                    tracer.ZIndex = 1
                                    tracer.Visible = true
                                    table.insert(downedTracerLines, tracer)
                                end
                                -- Box
                                if featureStates.DownedBoxESP then
                                    local boxColor = Color3.fromRGB(255, 255, 0)
                                    if featureStates.DownedBoxType == "2D" then
                                        local topY = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0)).Y
                                        local bottomY = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0)).Y
                                        local size = (bottomY - topY) / 2
                                        local box = Drawing.new("Square")
                                        box.Thickness = 2
                                        box.Filled = false
                                        box.Color = boxColor
                                        box.Size = Vector2.new(size * 2, size * 3)
                                        box.Position = Vector2.new(pos.X - size, pos.Y - size * 1.5)
                                        box.ZIndex = 1
                                        box.Visible = true
                                        table.insert(downedTracerLines, box)
                                    else
                                        -- 3D Box
                                        local size = Vector3.new(3, 5, 2)
                                        local offsets = {
                                            Vector3.new( size.X/2,  size.Y/2,  size.Z/2),
                                            Vector3.new( size.X/2,  size.Y/2, -size.Z/2),
                                            Vector3.new( size.X/2, -size.Y/2,  size.Z/2),
                                            Vector3.new( size.X/2, -size.Y/2, -size.Z/2),
                                            Vector3.new(-size.X/2,  size.Y/2,  size.Z/2),
                                            Vector3.new(-size.X/2,  size.Y/2, -size.Z/2),
                                            Vector3.new(-size.X/2, -size.Y/2,  size.Z/2),
                                            Vector3.new(-size.X/2, -size.Y/2, -size.Z/2),
                                        }
                                        local screenPoints = {}
                                        for i, offset in ipairs(offsets) do
                                            local worldPos = hrp.CFrame * offset
                                            local vec, _ = workspace.CurrentCamera:WorldToViewportPoint(worldPos)
                                            screenPoints[i] = {pos = Vector2.new(vec.X, vec.Y), depth = vec.Z}
                                        end
                                        local edges = {
                                            {1,2}, {1,3}, {1,5},
                                            {2,4}, {2,6},
                                            {3,4}, {3,7},
                                            {5,6}, {5,7},
                                            {4,8}, {6,8}, {7,8}
                                        }
                                        for _, edge in ipairs(edges) do
                                            local p1 = screenPoints[edge[1]]
                                            p2 = screenPoints[edge[2]]
                                            if p1.depth > 0 and p2.depth > 0 then
                                                local line = Drawing.new("Line")
                                                line.Thickness = 2
                                                line.Color = boxColor
                                                line.From = p1.pos
                                                line.To = p2.pos
                                                line.Visible = true
                                                table.insert(downedTracerLines, line)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

local function stopDownedTracer()
    if downedTracerConnection then
        downedTracerConnection:Disconnect()
        downedTracerConnection = nil
    end
    cleanupTracers(downedTracerLines)
    downedTracerLines = {}
    
    -- Cleanup highlights
    for _, highlight in pairs(downedHighlights) do
        cleanupHighlight(highlight)
    end
    downedHighlights = {}
end

-- Downed Name ESP Functions
local function cleanupNameESPLabels(labelTable)
    for _, label in ipairs(labelTable) do
        safeCleanupObject(label)
    end
    labelTable = {}
end

local function startDownedNameESP()
    downedNameESPConnection = RunService.Heartbeat:Connect(function()
        cleanupNameESPLabels(downedNameESPLabels)
        downedNameESPLabels = {}
        local folder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
        if folder then
            for _, char in ipairs(folder:GetChildren()) do
                if char:IsA("Model") then
                    local team = char:GetAttribute("Team")
                    local downed = char:GetAttribute("Downed")
                    if team ~= "Nextbot" and char.Name ~= player.Name and downed == true then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp and workspace.CurrentCamera then
                            local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
                            if onScreen then
                                local distance = getDistanceFromPlayer(hrp.Position)
                                local displayText = char.Name
                                if featureStates.DownedDistanceESP then
                                    displayText = displayText .. "\n" .. math.floor(distance) .. " studs"
                                end
                                local label = Drawing.new("Text")
                                label.Text = displayText
                                label.Size = 16
                                label.Center = true
                                label.Outline = true
                                label.OutlineColor = Color3.new(0, 0, 0)
                                label.Color = Color3.fromRGB(255, 165, 0)
                                label.Position = Vector2.new(pos.X, pos.Y - 50)
                                label.Visible = true
                                table.insert(downedNameESPLabels, label)
                            end
                        end
                    end
                end
            end
        end
    end)
end

local function stopDownedNameESP()
    if downedNameESPConnection then
        downedNameESPConnection:Disconnect()
        downedNameESPConnection = nil
    end
    cleanupNameESPLabels(downedNameESPLabels)
    downedNameESPLabels = {}
end

-- Function to handle character loading
local function onCharacterAdded(newCharacter, plr)
    if plr == player then
        character = newCharacter
        humanoid = character:WaitForChild("Humanoid", 5)
        rootPart = character:WaitForChild("HumanoidRootPart", 5)
        if not humanoid or not rootPart then
            warn("Failed to find Humanoid or HumanoidRootPart")
            return
        end
        if type(setupJumpBoost) == "function" then
            setupJumpBoost()
        else
            warn("setupJumpBoost is not a function")
        end
        if type(reapplyFeatures) == "function" then
            reapplyFeatures()
        else
            warn("reapplyFeatures is not a function")
        end
    end
end
-- Function to reapply all active features after respawn
local function reapplyFeatures()
    if featureStates.Fly then
        if flying then stopFlying() end
        startFlying()
    end
    if featureStates.AutoJump then
        if AutoJumpConnection then stopAutoJump() end
        startAutoJump()
    end
    if featureStates.SpeedHack then
        if ToggleTpwalk then stopTpwalk() end
        startTpwalk()
    end
    if featureStates.JumpBoost then
        startJumpBoost()
    end
    if featureStates.AntiAFK then
        if AntiAFKConnection then stopAntiAFK() end
        startAntiAFK()
    end
    if featureStates.AutoCarry then
        stopAutoCarry()
        startAutoCarry()
    end
    if featureStates.AutoRevive then
        stopAutoRevive()
        startAutoRevive()
    end
    if featureStates.FullBright then
        startFullBright()
    else
        stopFullBright()
    end
    if featureStates.ClickTP then
        if clickTPConnection then stopClickTP() end
        startClickTP()
    end
    if featureStates.NoFog then
    startNoFog()
else
    stopNoFog()
end
    if featureStates.AutoVote then
        if AutoVoteConnection then stopAutoVote() end
        startAutoVote()
    end
    if featureStates.AutoSelfRevive then
        if AutoSelfReviveConnection then stopAutoSelfRevive() end
        startAutoSelfRevive()
    end
    if featureStates.AutoWin then
        if AutoWinConnection then stopAutoWin() end
        startAutoWin()
    end
    if featureStates.AutoMoneyFarm then
        if AutoMoneyFarmConnection then stopAutoMoneyFarm() end
        startAutoMoneyFarm()
    end
    if featureStates.AutoTicketFarm then
        if autoTicketFarmConnection then stopAutoTicketFarm() end
        startAutoTicketFarm()
    end
    if featureStates.PlayerESP.boxes or featureStates.PlayerESP.tracers or featureStates.PlayerESP.names or featureStates.PlayerESP.distance or featureStates.PlayerESP.highlight then
        stopPlayerESP()
        startPlayerESP()
    end
    if featureStates.NextbotESP.names or featureStates.NextbotESP.boxes or featureStates.NextbotESP.tracers or featureStates.NextbotESP.distance then
        stopNextbotNameESP()
        startNextbotNameESP()
    end
    if featureStates.DownedBoxESP or featureStates.DownedTracer or featureStates.DownedHighlight then
        if downedTracerConnection then stopDownedTracer() end
        startDownedTracer()
    end
    if featureStates.DownedNameESP then
        if downedNameESPConnection then stopDownedNameESP() end
        startDownedNameESP()
    end
    if featureStates.TicketESP.enabled then
        if ticketEspConnection then stopTicketESP() end
        startTicketESP()
    end
    if featureStates.DesiredFOV and workspace.CurrentCamera then
        workspace.CurrentCamera.FieldOfView = featureStates.DesiredFOV
    end
    if featureStates.TimerDisplay then
        TimerDisplayToggle:Set(true)
    end
end

-- Function to handle player joining
local function onPlayerAdded(plr)
    plr.CharacterAdded:Connect(function(newCharacter)
        onCharacterAdded(newCharacter, plr)
        -- Force update ESP for new character if any ESP is enabled
        if featureStates.PlayerESP and (featureStates.PlayerESP.boxes or featureStates.PlayerESP.tracers or featureStates.PlayerESP.names or featureStates.PlayerESP.distance or featureStates.PlayerESP.highlight) then
            task.wait(1) -- Wait a bit for character to fully load
            updatePlayerESP()
        end
    end)
    if plr.Character then
        onCharacterAdded(plr.Character, plr)
    end
end

-- Connect player added event
Players.PlayerAdded:Connect(onPlayerAdded)

-- Handle existing players
for _, plr in ipairs(Players:GetPlayers()) do
    onPlayerAdded(plr)
end

-- Input handling for infinite jump (keyboard)
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if not gameProcessedEvent and input.KeyCode == Enum.KeyCode.Space then
        if featureStates.InfiniteJump then
            if featureStates.JumpMethod == "Hold" then
                isJumpHeld = true
                bouncePlayer()
                task.spawn(function()
                    while isJumpHeld and featureStates.InfiniteJump and featureStates.JumpMethod == "Hold" do
                        bouncePlayer()
                        task.wait(0.1)
                    end
                end)
            elseif featureStates.JumpMethod == "Spam" then
                if not isJumpHeld then
                    isJumpHeld = true
                    bouncePlayer()
                end
            end
        end
    end
    
end)

UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
    if not gameProcessedEvent and input.KeyCode == Enum.KeyCode.Space then
        isJumpHeld = false
    end
end)

-- Handle mobile jump button tap and hold
local function setupMobileJumpButton()
    local success, result = pcall(function()
        local touchGui = player.PlayerGui:WaitForChild("TouchGui", 5)
        local touchControlFrame = touchGui:WaitForChild("TouchControlFrame", 5)
        local jumpButton = touchControlFrame:WaitForChild("JumpButton", 5)
        
        jumpButton.Activated:Connect(function()
            if featureStates.InfiniteJump then
                if featureStates.JumpMethod == "Spam" then
                    -- Trigger a single jump on tap
                    bouncePlayer()
                elseif featureStates.JumpMethod == "Hold" then
                    -- Trigger a single jump on tap for consistency
                    bouncePlayer()
                end
            end
        end)

        jumpButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                isJumpHeld = true
                if featureStates.InfiniteJump and featureStates.JumpMethod == "Hold" then
                    while isJumpHeld and featureStates.InfiniteJump and featureStates.JumpMethod == "Hold" do
                        bouncePlayer()
                        task.wait(0.1)
                    end
                end
            end
        end)

        jumpButton.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                isJumpHeld = false
            end
        end)
    end)
    if not success then
        warn("Failed to set up mobile jump button: " .. tostring(result))
    end
end

-- Initialize character
if player.Character then
    onCharacterAdded(player.Character, player)
else
    player.CharacterAdded:Connect(function(newCharacter)
        onCharacterAdded(newCharacter, player)
    end)
end

-- Connect fly update
RunService.RenderStepped:Connect(updateFly)

-- Connect FOV enforcement
RunService.Heartbeat:Connect(function()
    if workspace.CurrentCamera and featureStates.DesiredFOV then
        workspace.CurrentCamera.FieldOfView = featureStates.DesiredFOV
    end
end)
RunService.Heartbeat:Connect(function()
    if workspace.CurrentCamera and featureStates.DesiredFOV then
        workspace.CurrentCamera.FieldOfView = featureStates.DesiredFOV
    end
end)
-- UI Setup with WindUI
local function setupGui()

-- Function to fetch a list of public servers
local function getServers()
    local request = request({
        Url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Desc&limit=100",
        Method = "GET",
    })

    if request.StatusCode == 200 then
        local serverData = HttpService:JSONDecode(request.Body)
        local serverList = {}

        for _, server in pairs(serverData.data) do
            if server.id ~= jobId and server.playing < server.maxPlayers then
                local serverInfo = {
                    serverId = server.id or "N/A",
                    players = server.playing or 0,
                    maxPlayers = server.maxPlayers or 0,
                    ping = server.ping or "N/A",
                }
                table.insert(serverList, serverInfo)
            end
        end
        return serverList
    else
        return {}
    end
end

-- Function for random server hop
local function serverHop()

local AllIDs = {}
local foundAnything = ""
local actualHour = os.date("!*t").hour
local Deleted = false
local S_T = game:GetService("TeleportService")
local S_H = game:GetService("HttpService")

local File = pcall(function()
    AllIDs = S_H:JSONDecode(readfile("server-hop-temp.json"))
end)
if not File then
    table.insert(AllIDs, actualHour)
    pcall(function()
        writefile("server-hop-temp.json", S_H:JSONEncode(AllIDs))
    end)

end
local function TPReturner(placeId)
    local Site;
    if foundAnything == "" then
        Site = S_H:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. placeId .. '/servers/Public?sortOrder=Asc&limit=100'))
    else
        Site = S_H:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. placeId .. '/servers/Public?sortOrder=Asc&limit=100&cursor=' .. foundAnything))
    end
    local ID = ""
    if Site.nextPageCursor and Site.nextPageCursor ~= "null" and Site.nextPageCursor ~= nil then
        foundAnything = Site.nextPageCursor
    end
    local num = 0;
    for i,v in pairs(Site.data) do
        local Possible = true
        ID = tostring(v.id)
        if tonumber(v.maxPlayers) > tonumber(v.playing) then
            for _,Existing in pairs(AllIDs) do
                if num ~= 0 then
                    if ID == tostring(Existing) then
                        Possible = false
                    end
                else
                    if tonumber(actualHour) ~= tonumber(Existing) then
                        local delFile = pcall(function()
                            delfile("server-hop-temp.json")
                            AllIDs = {}
                            table.insert(AllIDs, actualHour)
                        end)
                    end
                end
                num = num + 1
            end
            if Possible == true then
                table.insert(AllIDs, ID)
                wait()
                pcall(function()
                    writefile("server-hop-temp.json", S_H:JSONEncode(AllIDs))
                    wait()
                    S_T:TeleportToPlaceInstance(placeId, ID, game.Players.LocalPlayer)
                end)
                wait(4)
            end
        end
    end
end
local module = {}
function module:Teleport(placeId)
    while wait() do
        pcall(function()
            TPReturner(placeId)
            if foundAnything ~= "" then
                TPReturner(placeId)
            end
        end)
    end
end
module:Teleport(game.PlaceId)
return module
end

-- Function to hop to a server with a specific player count (or closest)
local function hopToServerWithPlayerCount(targetCount)
    local servers = getServers()
    if servers and #servers > 0 then
        table.sort(servers, function(a, b)
            return math.abs(a.players - targetCount) < math.abs(b.players - targetCount)
        end)
        local targetServer = servers[1]
        TeleportService:TeleportToPlaceInstance(placeId, targetServer.serverId, player)
    else
        Window:Notify({
            Title = "Error",
            Desc = "No servers found with approximately " .. targetCount .. " players.",
            Duration = 4
        })
    end
end
-- Function to hop to a server with a specific player count (or closest)
local function hopToServerWithPlayerCount(targetCount)
    local servers = getServers()
    if #servers > 0 then
        table.sort(servers, function(a, b)
            return math.abs(a.playing - targetCount) < math.abs(b.playing - targetCount)
        end)
        local targetServer = servers[1]
        TeleportService:TeleportToPlaceInstance(placeId, targetServer.id)
    else
        warn("No servers found with approximately " .. targetCount .. " players.")
    end
end

-- Function to rejoin current server
local function rejoinServer()
    TeleportService:TeleportToPlaceInstance(placeId, jobId)
end

    local FeatureSection = Window:Section({ Title = "loc:FEATURES", Opened = true })

    local Tabs = {
    Main = FeatureSection:Tab({ Title = "Main", Icon = "home" }),  -- New Main tab
    Player = FeatureSection:Tab({ Title = "loc:Player_TAB", Icon = "user" }),
    Auto = FeatureSection:Tab({ Title = "loc:AUTO_TAB", Icon = "zap" }),
    Visuals = FeatureSection:Tab({ Title = "loc:VISUALS_TAB", Icon = "eye" }),
    ESP = FeatureSection:Tab({ Title = "loc:ESP_TAB", Icon = "scan" }),
    Settings = FeatureSection:Tab({ Title = "loc:SETTINGS_TAB", Icon = "settings" })
}


-- Main Tab
Tabs.Main:Section({ Title = "Server Info", TextSize = 20 })
Tabs.Main:Divider()

-- Get Place Name
local placeName = "Unknown"
local success, productInfo = pcall(function()
    return MarketplaceService:GetProductInfo(placeId)
end)
if success and productInfo then
    placeName = productInfo.Name
end

Tabs.Main:Paragraph({
    Title = "Game Mode",
    Desc = placeName
})

Tabs.Main:Button({
    Title = "Copy Server Link",
    Desc = "Copy the current server's join link",
    Icon = "link",
    Callback = function()
        local serverLink = getServerLink()
        pcall(function()
            setclipboard(serverLink)
        end)
        -- Optional: Notify user
        WindUI:Notify({
                Icon = "link",
                Title = "Link Copied",
                Content = "The server invite link has been copied to your clipborad",
                Duration = 3
        })
    end
})

-- Existing Server Info
local numPlayers = #Players:GetPlayers()
local maxPlayers = Players.MaxPlayers

Tabs.Main:Paragraph({
    Title = "Current Players",
    Desc = numPlayers .. " / " .. maxPlayers
})

Tabs.Main:Paragraph({
    Title = "Server ID",
    Desc = jobId
})

Tabs.Main:Paragraph({
    Title = "Place ID",
    Desc = tostring(placeId)
})

-- Server Tools Section
Tabs.Main:Section({ Title = "Server Tools", TextSize = 20 })
Tabs.Main:Divider()

Tabs.Main:Button({
    Title = "Rejoin",
    Desc = "Rejoin the current server",
    Icon = "refresh-cw",
    Callback = function()
        rejoinServer()
    end
})

Tabs.Main:Button({
    Title = "Server Hop",
    Desc = "Hop to a random server",
    Icon = "shuffle",
    Callback = function()
        serverHop()
    end
})

Tabs.Main:Button({
    Title = "Hop to Small Server",
    Desc = "Hop to the smallest available server",
    Icon = "minimize",
    Callback = function()
        hopToSmallServer()
    end
})

local targetPlayerCount = 1
Tabs.Main:Input({
    Title = "Target Player Count",
    Value = "1",
    Callback = function(value)
        targetPlayerCount = tonumber(value) or 1
    end
})

Tabs.Main:Button({
    Title = "Hop to Server with X Players",
    Desc = "Hop to a server with approximately this many players",
    Icon = "users",
    Callback = function()
        hopToServerWithPlayerCount(targetPlayerCount)
    end
})
    -- Player Tab
    Tabs.Player:Section({ Title = "Player", TextSize = 40 })
    Tabs.Player:Divider()
    local AutoJumpToggle = Tabs.Player:Toggle({
        Title = "loc:AUTO_JUMP",
        Value = featureStates.AutoJump,
        Callback = function(state)
            featureStates.AutoJump = state
            if state then
                startAutoJump()
            else
                stopAutoJump()
            end
        end
    })

    local InfiniteJumpToggle = Tabs.Player:Toggle({
        Title = "loc:INFINITE_JUMP",
        Value = featureStates.InfiniteJump,
        Callback = function(state)
            featureStates.InfiniteJump = state
        end
    })

    local JumpMethodDropdown = Tabs.Player:Dropdown({
        Title = "loc:JUMP_METHOD",
        Values = {"Hold", "Spam"},
        Value = "Hold",
        Callback = function(value)
            featureStates.JumpMethod = value
        end
    })


    local FlyToggle = Tabs.Player:Toggle({
        Title = "loc:FLY",
        Value = featureStates.Fly,
        Callback = function(state)
            featureStates.Fly = state
            if state then
                startFlying()
            else
                stopFlying()
            end
        end
    })

    local FlySpeedSlider = Tabs.Player:Slider({
        Title = "loc:FLY_SPEED",
        Value = { Min = 1, Max = 200, Default = 5, Step = 1 },
                Desc = "Adjust fly speed",
        Callback = function(value)
            featureStates.FlySpeed = value
        end
    })

    local SpeedHackToggle = Tabs.Player:Toggle({
        Title = "loc:SPEED_HACK",
        Value = featureStates.SpeedHack,
        Callback = function(state)
            featureStates.SpeedHack = state
            if state then
                startTpwalk()
            else
                stopTpwalk()
            end
        end
    })

    local SpeedHackSlider = Tabs.Player:Slider({
        Title = "loc:SPEED_HACK_VALUE",
        Desc = "Adjust speed",
        Value = { Min = 1, Max = 200, Default = 1, Step = 1 },
        Callback = function(value)
            featureStates.TpwalkValue = value
        end
    })

    local JumpBoostToggle = Tabs.Player:Toggle({
        Title = "loc:JUMP_HEIGHT",
        Value = featureStates.JumpBoost,
        Callback = function(state)
            featureStates.JumpBoost = state
            if state then
                startJumpBoost()
            else
                stopJumpBoost()
            end
        end
    })

    local JumpBoostSlider = Tabs.Player:Slider({
        Title = "loc:JUMP_POWER",
        Desc = "Adjust jump height",
        Value = { Min = 1, Max = 200, Default = 5, Step = 1 },
        Callback = function(value)
            featureStates.JumpPower = value
            if featureStates.JumpBoost then
                if humanoid then
                    humanoid.JumpPower = featureStates.JumpPower
                end
            end
        end
    })

    local AntiAFKToggle = Tabs.Player:Toggle({
        Title = "loc:ANTI_AFK",
        Value = featureStates.AntiAFK,
        Callback = function(state)
            featureStates.AntiAFK = state
            if state then
                startAntiAFK()
            else
                stopAntiAFK()
            end
        end
    })

    local ClickTPToggle = Tabs.Player:Toggle({
        Title = "Click Teleport",
        Value = featureStates.ClickTP,
        Callback = function(state)
            featureStates.ClickTP = state
            if state then
                if clickTPConnection then stopClickTP() end
                startClickTP()
            else
                stopClickTP()
            end
        end
    })

    -- Visuals Tab
    Tabs.Visuals:Section({ Title = "Visual", TextSize = 20 })
    Tabs.Visuals:Divider()

    local FullBrightToggle = Tabs.Visuals:Toggle({
        Title = "loc:FULL_BRIGHT",
        Value = featureStates.FullBright,
        Callback = function(state)
            featureStates.FullBright = state
            if state then
                startFullBright()
            else
                stopFullBright()
            end
        end
    })
local NoFogToggle = Tabs.Visuals:Toggle({
    Title = "loc:NO_FOG",
    Value = featureStates.NoFog,
    Callback = function(state)
        featureStates.NoFog = state
        if state then
            startNoFog()
        else
            stopNoFog()
        end
    end
})

    local FOVSlider = Tabs.Visuals:Slider({
    Title = "loc:FOV",
    Value = { Min = 10, Max = 120, Default = 70, Step = 1 },
    Callback = function(value)
        featureStates.DesiredFOV = value
        local camera = workspace.CurrentCamera or game:GetService("Workspace"):WaitForChild("CurrentCamera", 5)
        if camera then
            camera.FieldOfView = value
        end
    end
})

local TimerDisplayToggle = Tabs.Visuals:Toggle({
    Title = "Timer Display",
    Value = featureStates.TimerDisplay,
    Callback = function(state)
        featureStates.TimerDisplay = state
        if state then
            -- Show TimerContainer
            pcall(function()
                local Players = game:GetService("Players")
                local LocalPlayer = Players.LocalPlayer
                local PlayerGui = LocalPlayer.PlayerGui
                local MainInterface = PlayerGui:WaitForChild("MainInterface")
                local TimerContainer = MainInterface:WaitForChild("TimerContainer")
                TimerContainer.Visible = true
            end)
            
            -- Start the loop to hide roundTimer (runs while featureStates.TimerDisplay is true)
            task.spawn(function()
                while featureStates.TimerDisplay do
                    local success, result = pcall(function()
                        local Players = game:GetService("Players")
                        local player = Players.LocalPlayer
                        
                        if not player then
                            return false
                        end
                        
                        local playerGui = player:FindFirstChild("PlayerGui")
                        if not playerGui then
                            return false
                        end
                        
                        local shared = playerGui:WaitForChild("Shared", 1)
                        if not shared then
                            return false
                        end
                        
                        local hud = shared:WaitForChild("HUD", 1)
                        if not hud then
                            return false
                        end
                        
                        local overlay = hud:WaitForChild("Overlay", 1)
                        if not overlay then
                            return false
                        end
                        
                        local default = overlay:WaitForChild("Default", 1)
                        if not default then
                            return false
                        end
                        
                        local roundOverlay = default:WaitForChild("RoundOverlay", 1)
                        if not roundOverlay then
                            return false
                        end
                        
                        local round = roundOverlay:WaitForChild("Round", 1)
                        if not round then
                            return false
                        end
                        
                        local roundTimer = round:WaitForChild("RoundTimer", 1)
                        if not roundTimer then
                            return false
                        end
                        
                        roundTimer.Visible = false
                        return true
                    end)
                    
                    if not success or not result then
                        task.wait(0)
                    else
                        task.wait(0)
                    end
                end
            end)
        else
            -- Hide TimerContainer
            pcall(function()
                local Players = game:GetService("Players")
                local LocalPlayer = Players.LocalPlayer
                local PlayerGui = LocalPlayer.PlayerGui
                local MainInterface = PlayerGui:WaitForChild("MainInterface")
                local TimerContainer = MainInterface:WaitForChild("TimerContainer")
                TimerContainer.Visible = false
            end)
        end
    end
})


    -- ESP Tab
    Tabs.ESP:Section({ Title = "ESP", TextSize = 40 })
    Tabs.ESP:Divider()
    Tabs.ESP:Section({ Title = "Player ESP" })
local PlayerNameESPToggle = Tabs.ESP:Toggle({
    Title = "loc:PLAYER_NAME_ESP",
    Value = featureStates.PlayerESP.names,
    Callback = function(state)
        featureStates.PlayerESP.names = state
        if state or featureStates.PlayerESP.boxes or featureStates.PlayerESP.tracers or featureStates.PlayerESP.distance or featureStates.PlayerESP.highlight then
            startPlayerESP()
        elseif not (featureStates.PlayerESP.tracers or featureStates.PlayerESP.boxes or featureStates.PlayerESP.names or featureStates.PlayerESP.distance or featureStates.PlayerESP.highlight) then
            stopPlayerESP()
        end
    end
})

local PlayerNameModeDropdown = Tabs.ESP:Dropdown({
    Title = "loc:PLAYER_NAME_MODE",
    Values = {"Username", "Display Name", "Username + Display"},
    Value = featureStates.PlayerESP.nameMode,
    Callback = function(value)
        featureStates.PlayerESP.nameMode = value
    end
})

    local PlayerBoxESPToggle = Tabs.ESP:Toggle({
        Title = "loc:PLAYER_BOX_ESP",
        Value = featureStates.PlayerESP.distance,
        Callback = function(state)
            featureStates.PlayerESP.boxes = state
            if state or featureStates.PlayerESP.tracers or featureStates.PlayerESP.names or featureStates.PlayerESP.distance or featureStates.PlayerESP.highlight then
                startPlayerESP()
            else
                stopPlayerESP()
            end
        end
    })

    local PlayerBoxTypeDropdown = Tabs.ESP:Dropdown({
        Title = "Player Box Type",
        Values = {"2D", "3D"},
        Value = "2D",
        Callback = function(value)
            featureStates.PlayerESP.boxType = value
        end
    })

    local PlayerRainbowBoxesToggle = Tabs.ESP:Toggle({
        Title = "loc:PLAYER_RAINBOW_BOXES",
        Value = featureStates.PlayerESP.rainbowBoxes,
        Callback = function(state)
            featureStates.PlayerESP.rainbowBoxes = state
            if featureStates.PlayerESP.boxes then
                stopPlayerESP()
                startPlayerESP()
            end
        end
    })

    local PlayerTracerToggle = Tabs.ESP:Toggle({
        Title = "loc:PLAYER_TRACER",
        Value = featureStates.PlayerESP.tracers,
        Callback = function(state)
            featureStates.PlayerESP.tracers = state
            if state or featureStates.PlayerESP.boxes or featureStates.PlayerESP.names or featureStates.PlayerESP.distance or featureStates.PlayerESP.highlight then
                startPlayerESP()
            else
                stopPlayerESP()
            end
        end
    })
    local PlayerRainbowTracersToggle = Tabs.ESP:Toggle({
        Title = "loc:PLAYER_RAINBOW_TRACERS",
        Value = featureStates.PlayerESP.rainbowTracers,
        Callback = function(state)
            featureStates.PlayerESP.rainbowTracers = state
            if featureStates.PlayerESP.tracers then
                stopPlayerESP()
                startPlayerESP()
            end
        end
    })

    local PlayerDistanceESPToggle = Tabs.ESP:Toggle({
        Title = "loc:PLAYER_DISTANCE_ESP",
        Value = featureStates.PlayerESP.distance,
        Callback = function(state)
            featureStates.PlayerESP.distance = state
            if state or featureStates.PlayerESP.boxes or featureStates.PlayerESP.tracers or featureStates.PlayerESP.names or featureStates.PlayerESP.highlight then
                startPlayerESP()
            else
                stopPlayerESP()
            end
        end
    })

    local PlayerHighlightToggle = Tabs.ESP:Toggle({
        Title = "Player Highlight",
        Desc = "Highlight players with colored outline",
        Value = featureStates.PlayerESP.highlight,
        Callback = function(state)
            featureStates.PlayerESP.highlight = state
            if state or featureStates.PlayerESP.boxes or featureStates.PlayerESP.tracers or featureStates.PlayerESP.names or featureStates.PlayerESP.distance then
                startPlayerESP()
            else
                stopPlayerESP()
            end
        end
    })

    Tabs.ESP:Section({ Title = "Nextbot Name ESP" })

local NextbotESPToggle = Tabs.ESP:Toggle({
    Title = "loc:NEXTBOT_NAME_ESP",
    Value = featureStates.NextbotESP.names,
    Callback = function(state)
        featureStates.NextbotESP.names = state
        if state then
            startNextbotNameESP()
            setupNextbotDetection()
        else
            stopNextbotNameESP()
        end
    end
})

local NextbotBoxESPToggle = Tabs.ESP:Toggle({
    Title = "Nextbot Box ESP",
    Value = featureStates.NextbotESP.boxes,
    Callback = function(state)
    featureStates.NextbotESP.boxes = state
    if state or featureStates.NextbotESP.names or featureStates.NextbotESP.tracers or featureStates.NextbotESP.distance then
        startNextbotNameESP()
    else
        stopNextbotNameESP()
    end
    end
})

local NextbotBoxTypeDropdown = Tabs.ESP:Dropdown({
    Title = "Nextbot Box Type",
    Values = {"2D", "3D"},
    Value = "2D",
    Callback = function(value)
        featureStates.NextbotESP.boxType = value
    end
})
local NextbotRainbowBoxesToggle = Tabs.ESP:Toggle({
    Title = "Nextbot Rainbow Boxes",
    Value = featureStates.NextbotESP.rainbowBoxes,
    Callback = function(state)
        featureStates.NextbotESP.rainbowBoxes = state
        if featureStates.NextbotESP.boxes then
            stopNextbotNameESP()
            startNextbotNameESP()
        end
    end
})
local NextbotTracerToggle = Tabs.ESP:Toggle({
    Title = "Nextbot Tracer",
    Value = featureStates.NextbotESP.tracers,
    Callback = function(state)
    featureStates.NextbotESP.tracers = state
    if state or featureStates.NextbotESP.names or featureStates.NextbotESP.boxes or featureStates.NextbotESP.distance then
        startNextbotNameESP()
    else
        stopNextbotNameESP()
    end
    end
})
local NextbotRainbowTracersToggle = Tabs.ESP:Toggle({
    Title = "Nextbot Rainbow Tracers",
    Value = featureStates.NextbotESP.rainbowTracers,
    Callback = function(state)
        featureStates.NextbotESP.rainbowTracers = state
        if featureStates.NextbotESP.tracers then
            stopNextbotNameESP()
            startNextbotNameESP()
        end
    end
})
local NextbotDistanceESPToggle = Tabs.ESP:Toggle({
    Title = "Nextbot Distance ESP",
    Value = featureStates.NextbotESP.distance,
    Callback = function(state)
        featureStates.NextbotESP.distance = state
        if state or featureStates.NextbotESP.names or featureStates.NextbotESP.boxes or featureStates.NextbotESP.tracers then
            startNextbotNameESP()
        else
            stopNextbotNameESP()
        end
    end
})


    Tabs.ESP:Section({ Title = "Downed Player ESP" })

local DownedBoxESPToggle = Tabs.ESP:Toggle({
        Title = "loc:DOWNED_BOX_ESP",
        Value = featureStates.DownedBoxESP,
        Callback = function(state)
            featureStates.DownedBoxESP = state
            if state or featureStates.DownedTracer or featureStates.DownedHighlight then
                if downedTracerConnection then stopDownedTracer() end
                startDownedTracer()
            else
                stopDownedTracer()
            end
        end
    })

    local DownedBoxTypeDropdown = Tabs.ESP:Dropdown({
        Title = "Downed Box Type",
        Values = {"2D", "3D"},
        Value = "2D",
        Callback = function(value)
            featureStates.DownedBoxType = value
        end
    })

local DownedTracerToggle = Tabs.ESP:Toggle({
        Title = "loc:DOWNED_TRACER",
        Value = featureStates.DownedTracer,
        Callback = function(state)
            featureStates.DownedTracer = state
            if state or featureStates.DownedBoxESP or featureStates.DownedHighlight then
                if downedTracerConnection then stopDownedTracer() end
                startDownedTracer()
            else
                stopDownedTracer()
            end
        end
    })

    local DownedNameESPToggle = Tabs.ESP:Toggle({
        Title = "loc:DOWNED_NAME_ESP",
        Value = featureStates.DownedNameESP,
        Callback = function(state)
            featureStates.DownedNameESP = state
            if state then
                startDownedNameESP()
            else
                stopDownedNameESP()
            end
        end
    })

    local DownedDistanceESPToggle = Tabs.ESP:Toggle({
        Title = "loc:DOWNED_DISTANCE_ESP",
        Value = featureStates.DownedDistanceESP,
        Callback = function(state)
            featureStates.DownedDistanceESP = state
            if featureStates.DownedNameESP then
                stopDownedNameESP()
                startDownedNameESP()
            end
        end
    })

    local DownedHighlightToggle = Tabs.ESP:Toggle({
        Title = "Downed Player Highlight",
        Desc = "Highlight downed players with colored outline",
        Value = featureStates.DownedHighlight,
        Callback = function(state)
            featureStates.DownedHighlight = state
            if state or featureStates.DownedBoxESP or featureStates.DownedTracer then
                if downedTracerConnection then stopDownedTracer() end
                startDownedTracer()
            else
                stopDownedTracer()
            end
        end
    })

    Tabs.ESP:Section({ Title = "Ticket ESP" })

    local TicketESPToggle = Tabs.ESP:Toggle({
        Title = "Ticket ESP",
        Desc = "ESP for tickets in workspace.Game.Effects.Tickets",
        Value = featureStates.TicketESP.enabled,
        Callback = function(state)
            featureStates.TicketESP.enabled = state
            if state then
                startTicketESP()
            else
                stopTicketESP()
            end
        end
    })

    local TicketTracerToggle = Tabs.ESP:Toggle({
        Title = "Ticket Tracer",
        Desc = "Show tracer lines to tickets",
        Value = featureStates.TicketESP.showTracers,
        Callback = function(state)
            featureStates.TicketESP.showTracers = state
            if featureStates.TicketESP.enabled then
                stopTicketESP()
                startTicketESP()
            end
        end
    })

    local TicketNameToggle = Tabs.ESP:Toggle({
        Title = "Ticket Name ESP",
        Desc = "Show ticket names and distance",
        Value = featureStates.TicketESP.showNames,
        Callback = function(state)
            featureStates.TicketESP.showNames = state
            if featureStates.TicketESP.enabled then
                stopTicketESP()
                startTicketESP()
            end
        end
    })

    local TicketHighlightToggle = Tabs.ESP:Toggle({
        Title = "Ticket Highlight",
        Desc = "Highlight tickets with colored outline",
        Value = featureStates.TicketESP.showHighlight,
        Callback = function(state)
            featureStates.TicketESP.showHighlight = state
            if featureStates.TicketESP.enabled then
                stopTicketESP()
                startTicketESP()
            end
        end
    })


    -- Auto Tab
    Tabs.Auto:Section({ Title = "Auto", TextSize = 40 })
    Tabs.Auto:Divider()

    local AutoCarryToggle = Tabs.Auto:Toggle({
        Title = "loc:AUTO_CARRY",
        Value = featureStates.AutoCarry,
        Callback = function(state)
            featureStates.AutoCarry = state
            if state then
                startAutoCarry()
            else
                stopAutoCarry()
            end
        end
    })


    local CarryRangeInput = Tabs.Auto:Input({
        Title = "Carry Range (Max: 10)",
        Placeholder = "10",
        Value = tostring(carryRange),
        Callback = function(value)
            local num = tonumber(value)
            if num and num > 0 and num <= 10 then
                carryRange = num
            elseif num and num > 10 then
                carryRange = 10
                CarryRangeInput:Set("10")
                WindUI:Notify({
                    Title = "Carry Range",
                    Content = "Maximum range is 10 studs",
                    Duration = 2
                })
            end
        end
    })

    local CarryDelayInput = Tabs.Auto:Input({
        Title = "Carry Delay (seconds)",
        Placeholder = "0.01",
        Value = tostring(carryDelay),
        Callback = function(value)
            local num = tonumber(value)
            if num and num >= 0 then
                carryDelay = num
            end
        end
    })

    local AutoReviveToggle = Tabs.Auto:Toggle({
        Title = "loc:AUTO_REVIVE",
        Value = featureStates.PlayerESP.distance,
        Callback = function(state)
            featureStates.AutoRevive = state
            if state then
                startAutoRevive()
            else
                stopAutoRevive()
            end
        end
    })

    local ReviveRangeInput = Tabs.Auto:Input({
        Title = "Revive Range (Max: 10)",
        Placeholder = "3",
        Value = tostring(reviveRange),
        Callback = function(value)
            local num = tonumber(value)
            if num and num > 0 and num <= 10 then
                reviveRange = num
            elseif num and num > 10 then
                reviveRange = 10
                ReviveRangeInput:Set("10")
                WindUI:Notify({
                    Title = "Revive Range",
                    Content = "Maximum range is 10 studs",
                    Duration = 2
                })
            end
        end
    })

    local ReviveDelayInput = Tabs.Auto:Input({
        Title = "Revive Delay (seconds)",
        Placeholder = "0.75",
        Value = tostring(reviveDelay),
        Callback = function(value)
            local num = tonumber(value)
            if num and num >= 0 then
                reviveDelay = num
            end
        end
    })

    local AutoVoteDropdown = Tabs.Auto:Dropdown({
        Title = "loc:AUTO_VOTE_MAP",
        Values = {"Map 1", "Map 2", "Map 3", "Map 4"},
        Value = "Map 1",
        Callback = function(value)
            if value == "Map 1" then
                featureStates.SelectedMap = 1
            elseif value == "Map 2" then
                featureStates.SelectedMap = 2
            elseif value == "Map 3" then
                featureStates.SelectedMap = 3
            elseif value == "Map 4" then
                featureStates.SelectedMap = 4
            end
        end
    })

    local AutoVoteToggle = Tabs.Auto:Toggle({
        Title = "loc:AUTO_VOTE",
        Value = featureStates.PlayerESP.distance,
        Callback = function(state)
            featureStates.AutoVote = state
            if state then
                startAutoVote()
            else
                stopAutoVote()
            end
        end
    })

    local AutoSelfReviveToggle = Tabs.Auto:Toggle({
        Title = "loc:AUTO_SELF_REVIVE",
        Value = featureStates.PlayerESP.distance,
        Callback = function(state)
            featureStates.AutoSelfRevive = state
            if state then
                startAutoSelfRevive()
            else
                stopAutoSelfRevive()
            end
        end
    })

    Tabs.Auto:Button({
        Title = "loc:MANUAL_REVIVE",
        Desc = "Manually revive yourself",
        Icon = "heart",
        Callback = function()
            manualRevive()
        end
    })

    -- Manual Revive Keybind Section
    Tabs.Auto:Section({ Title = "Manual Revive Keybind", TextSize = 20 })
    Tabs.Auto:Divider()

    -- Manual Revive Key Bind Button
    manualReviveKeyBindButton = Tabs.Auto:Button({
        Title = "Manual Revive Key",
        Desc = "Current Key: " .. getCleanKeyName(manualReviveKey),
        Icon = "key",
        Variant = "Primary",
        Callback = function()
            bindManualReviveKey(manualReviveKeyBindButton)
        end
    })

    -- Ensure the description reflects current loaded key
    pcall(updateManualReviveKeybindButtonDesc)

    local AutoWinToggle = Tabs.Auto:Toggle({
        Title = "loc:AUTO_WIN",
        Value = featureStates.PlayerESP.distance,
        Callback = function(state)
            featureStates.AutoWin = state
            if state then
                startAutoWin()
            else
                stopAutoWin()
            end
        end
    })

    local AutoMoneyFarmToggle = Tabs.Auto:Toggle({
        Title = "loc:AUTO_MONEY_FARM",
        Value = featureStates.PlayerESP.distance,
        Callback = function(state)
            featureStates.AutoMoneyFarm = state
            if state then
                startAutoMoneyFarm()
                featureStates.AutoRevive = true
                AutoReviveToggle:Set(true)
                startAutoRevive()
            else
                stopAutoMoneyFarm()
            end
        end
    })

    local AutoTicketFarmToggle = Tabs.Auto:Toggle({
        Title = "Auto Ticket Farm",
        Desc = "Automatically teleport nearest tickets to player",
        Value = featureStates.AutoTicketFarm,
        Callback = function(state)
            featureStates.AutoTicketFarm = state
            if state then
                startAutoTicketFarm()
            else
                stopAutoTicketFarm()
            end
        end
    })

    local TicketFarmRangeInput = Tabs.Auto:Input({
        Title = "Ticket Farm Delay (seconds)",
        Placeholder = "0.5",
        Value = tostring(ticketFarmDelay),
        Callback = function(value)
            local num = tonumber(value)
            if num and num >= 0 then
                ticketFarmDelay = num
            end
        end
    })


    -- Settings Tab
    Tabs.Settings:Section({ Title = "Settings", TextSize = 40 })
    Tabs.Settings:Section({ Title = "Personalize", TextSize = 20 })
    Tabs.Settings:Divider()

    local themes = {}
    for themeName, _ in pairs(WindUI:GetThemes()) do
        table.insert(themes, themeName)
    end
    table.sort(themes)

    local canChangeTheme = true
    local canChangeDropdown = true

    local ThemeDropdown = Tabs.Settings:Dropdown({
        Title = "loc:THEME_SELECT",
        Values = themes,
        SearchBarEnabled = true,
        MenuWidth = 280,
        Value = "Dark",
        Callback = function(theme)
            if canChangeDropdown then
                canChangeTheme = false
                WindUI:SetTheme(theme)
                canChangeTheme = true
            end
        end
    })

    local TransparencySlider = Tabs.Settings:Slider({
        Title = "loc:TRANSPARENCY",
        Value = { Min = 0, Max = 1, Default = 0.2, Step = 0.1 },
        Callback = function(value)
            WindUI.TransparencyValue = tonumber(value)
            Window:ToggleTransparency(tonumber(value) > 0)
        end
    })

    local ThemeToggle = Tabs.Settings:Toggle({
        Title = "Enable Dark Mode",
        Desc = "Use dark color scheme",
        Value = true,
        Callback = function(state)
            if canChangeTheme then
                local newTheme = state and "Dark" or "Light"
                WindUI:SetTheme(newTheme)
                if canChangeDropdown then
                    ThemeDropdown:Select(newTheme)
                end
            end
        end
    })

    WindUI:OnThemeChange(function(theme)
        canChangeTheme = false
        ThemeToggle:Set(theme == "Dark")
        canChangeTheme = true
    end)

    -- Configuration Manager
    local configName = "default"
    local configFile = nil
    local MyPlayerData = {
        name = player.Name,
        level = 1,
        inventory = {}
    }

    Tabs.Settings:Section({ Title = "Configuration Manager", TextSize = 20 })
    Tabs.Settings:Section({ Title = "Save and load your settings", TextSize = 16, TextTransparency = 0.25 })
    Tabs.Settings:Divider()

    Tabs.Settings:Input({
        Title = "Config Name",
        Value = configName,
        Callback = function(value)
            configName = value or "default"
        end
    })

    local ConfigManager = Window.ConfigManager
    if ConfigManager then
        ConfigManager:Init(Window)
        
        Tabs.Settings:Button({
            Title = "loc:SAVE_CONFIG",
            Icon = "save",
            Variant = "Primary",
            Callback = function()
                configFile = ConfigManager:CreateConfig(configName)
                configFile:Register("InfiniteJumpToggle", InfiniteJumpToggle)
                configFile:Register("AutoJumpToggle", AutoJumpToggle)
                configFile:Register("JumpMethodDropdown", JumpMethodDropdown)
                configFile:Register("FlyToggle", FlyToggle)
                configFile:Register("FlySpeedSlider", FlySpeedSlider)
                configFile:Register("SpeedHackToggle", SpeedHackToggle)
                configFile:Register("SpeedHackSlider", SpeedHackSlider)
                configFile:Register("JumpBoostToggle", JumpBoostToggle)
                configFile:Register("JumpBoostSlider", JumpBoostSlider)
                configFile:Register("AntiAFKToggle", AntiAFKToggle)
                configFile:Register("FullBrightToggle", FullBrightToggle)
                configFile:Register("NoFogToggle", NoFogToggle)
                configFile:Register("FOVSlider", FOVSlider)
                configFile:Register("PlayerBoxESPToggle", PlayerBoxESPToggle)
                configFile:Register("PlayerBoxTypeDropdown", PlayerBoxTypeDropdown)
                configFile:Register("PlayerTracerToggle", PlayerTracerToggle)
                configFile:Register("PlayerNameESPToggle", PlayerNameESPToggle)
                configFile:Register("PlayerDistanceESPToggle", PlayerDistanceESPToggle)
                configFile:Register("PlayerRainbowBoxesToggle", PlayerRainbowBoxesToggle)
                configFile:Register("PlayerRainbowTracersToggle", PlayerRainbowTracersToggle)
                configFile:Register("NextbotESPToggle", NextbotESPToggle)
                configFile:Register("NextbotBoxESPToggle", NextbotBoxESPToggle)
                configFile:Register("NextbotBoxTypeDropdown", NextbotBoxTypeDropdown)
                configFile:Register("NextbotTracerToggle", NextbotTracerToggle)
                configFile:Register("NextbotDistanceESPToggle", NextbotDistanceESPToggle)
                configFile:Register("NextbotRainbowBoxesToggle", NextbotRainbowBoxesToggle)
                configFile:Register("NextbotRainbowTracersToggle", NextbotRainbowTracersToggle)
                configFile:Register("DownedBoxESPToggle", DownedBoxESPToggle)
                configFile:Register("DownedBoxTypeDropdown", DownedBoxTypeDropdown)
                configFile:Register("NoFogToggle", NoFogToggle)
                configFile:Register("DownedTracerToggle", DownedTracerToggle)
                configFile:Register("DownedNameESPToggle", DownedNameESPToggle)
                configFile:Register("DownedDistanceESPToggle", DownedDistanceESPToggle)
                configFile:Register("TicketESPToggle", TicketESPToggle)
                configFile:Register("TicketTracerToggle", TicketTracerToggle)
                configFile:Register("TicketNameToggle", TicketNameToggle)
                configFile:Register("TicketHighlightToggle", TicketHighlightToggle)
                configFile:Register("AutoCarryToggle", AutoCarryToggle)
                configFile:Register("CarryRangeInput", CarryRangeInput)
                configFile:Register("CarryDelayInput", CarryDelayInput)
                configFile:Register("AutoReviveToggle", AutoReviveToggle)
                configFile:Register("ReviveRangeInput", ReviveRangeInput)
                configFile:Register("ReviveDelayInput", ReviveDelayInput)
                configFile:Register("ManualReviveKeyBindButton", manualReviveKeyBindButton)
                configFile:Register("AutoVoteDropdown", AutoVoteDropdown)
                configFile:Register("AutoVoteToggle", AutoVoteToggle)
                configFile:Register("AutoSelfReviveToggle", AutoSelfReviveToggle)
                configFile:Register("AutoWinToggle", AutoWinToggle)
                configFile:Register("AutoMoneyFarmToggle", AutoMoneyFarmToggle)
                configFile:Register("AutoTicketFarmToggle", AutoTicketFarmToggle)
                configFile:Register("TicketFarmDelayInput", TicketFarmDelayInput)
                configFile:Register("TimerDisplayToggle", TimerDisplayToggle)
                configFile:Register("ThemeDropdown", ThemeDropdown)
                configFile:Register("TransparencySlider", TransparencySlider)
                configFile:Register("ThemeToggle", ThemeToggle)
                configFile:Set("playerData", MyPlayerData)
                configFile:Set("lastSave", os.date("%Y-%m-%d %H:%M:%S"))
                configFile:Save()
            end
        })

        Tabs.Settings:Button({
            Title = "loc:LOAD_CONFIG",
            Icon = "folder",
            Callback = function()
                configFile = ConfigManager:CreateConfig(configName)
                local loadedData = configFile:Load()
                if loadedData then
                    if loadedData.playerData then
                        MyPlayerData = loadedData.playerData
                    end
                    local lastSave = loadedData.lastSave or "Unknown"
                    Tabs.Settings:Paragraph({
                        Title = "Player Data",
                        Desc = string.format("Name: %s\nLevel: %d\nInventory: %s", 
                            MyPlayerData.name, 
                            MyPlayerData.level, 
                            table.concat(MyPlayerData.inventory, ", "))
                    })
                    if loadedData.TimerDisplayToggle then
                        TimerDisplayToggle:Set(loadedData.TimerDisplayToggle)
                    end
                    if loadedData.CarryRangeInput then
                        CarryRangeInput:Set(loadedData.CarryRangeInput)
                        carryRange = tonumber(loadedData.CarryRangeInput) or 10
                    end
                    if loadedData.CarryDelayInput then
                        CarryDelayInput:Set(loadedData.CarryDelayInput)
                        carryDelay = tonumber(loadedData.CarryDelayInput) or 0.01
                    end
                    if loadedData.ReviveRangeInput then
                        ReviveRangeInput:Set(loadedData.ReviveRangeInput)
                        reviveRange = tonumber(loadedData.ReviveRangeInput) or 3
                    end
                    if loadedData.ReviveDelayInput then
                        ReviveDelayInput:Set(loadedData.ReviveDelayInput)
                        reviveDelay = tonumber(loadedData.ReviveDelayInput) or 0.75
                    end
                    if loadedData.ManualReviveKeyBindButton then
                        manualReviveKeyBindButton:Set(loadedData.ManualReviveKeyBindButton)
                    end
                end
            end
        })

        Tabs.Settings:Button({
            Title = "Reset All Config",
            Desc = "Reset all settings to default values",
            Icon = "refresh-cw",
            Variant = "Destructive",
            Callback = function()
                -- Reset all feature states to default
                featureStates = {
                    InfiniteJump = false,
                    AutoJump = false,
                    Fly = false,
                    SpeedHack = false,
                    JumpBoost = false,
                    AntiAFK = false,
                    AutoCarry = false,
                    FullBright = false,
                    NoFog = false,
                    GameTimerDisplay = false,
                    TimerDisplay = false,
                    AutoVote = false,
                    AutoSelfRevive = false,
                    AutoWin = false,
                    AutoMoneyFarm = false,
                    AutoRevive = false,
                    AutoTicketFarm = false,
                    PlayerESP = {
                        boxes = false,
                        tracers = false,
                        names = false,
                        distance = false,
                        rainbowBoxes = false,
                        rainbowTracers = false,
                        boxType = "3D",
                        nameMode = "Username",
                        highlight = false,
                    },
                    NextbotESP = {
                        boxes = false,
                        tracers = false,
                        names = false,
                        distance = false,
                        rainbowBoxes = false,
                        rainbowTracers = false,
                        boxType = "3D",
                    },
                    DownedBoxESP = false,
                    DownedTracer = false,
                    DownedNameESP = false,
                    DownedDistanceESP = false,
                    DownedBoxType = "3D",
                    DownedHighlight = false,
                    TicketESP = {
                        enabled = false,
                        showTracers = true,
                        showNames = true,
                        showHighlight = true,
                        tracerColor = Color3.fromRGB(255, 0, 0),
                        nameColor = Color3.fromRGB(255, 100, 100), -- Màu đỏ nhạt
                        highlightColor = Color3.fromRGB(255, 255, 0)
                    },
                    FlySpeed = 5,
                    TpwalkValue = 1,
                    JumpPower = 5,
                    JumpMethod = "Hold",
                    SelectedMap = 1,
                    ClickTP = false
                }
                
                -- Reset all UI toggles to default values
                if InfiniteJumpToggle then InfiniteJumpToggle:Set(false) end
                if AutoJumpToggle then AutoJumpToggle:Set(false) end
                if JumpMethodDropdown then JumpMethodDropdown:Select("Hold") end
                if FlyToggle then FlyToggle:Set(false) end
                if FlySpeedSlider then FlySpeedSlider:Set(5) end
                if SpeedHackToggle then SpeedHackToggle:Set(false) end
                if SpeedHackSlider then SpeedHackSlider:Set(1) end
                if JumpBoostToggle then JumpBoostToggle:Set(false) end
                if JumpBoostSlider then JumpBoostSlider:Set(5) end
                if AntiAFKToggle then AntiAFKToggle:Set(false) end
                if ClickTPToggle then ClickTPToggle:Set(false) end
                if FullBrightToggle then FullBrightToggle:Set(false) end
                if NoFogToggle then NoFogToggle:Set(false) end
                if FOVSlider then FOVSlider:Set(70) end
                if TimerDisplayToggle then TimerDisplayToggle:Set(false) end
                
                -- Reset Player ESP
                if PlayerNameESPToggle then PlayerNameESPToggle:Set(false) end
                if PlayerNameModeDropdown then PlayerNameModeDropdown:Select("Username") end
                if PlayerBoxESPToggle then PlayerBoxESPToggle:Set(false) end
                if PlayerBoxTypeDropdown then PlayerBoxTypeDropdown:Select("2D") end
                if PlayerRainbowBoxesToggle then PlayerRainbowBoxesToggle:Set(false) end
                if PlayerTracerToggle then PlayerTracerToggle:Set(false) end
                if PlayerRainbowTracersToggle then PlayerRainbowTracersToggle:Set(false) end
                if PlayerDistanceESPToggle then PlayerDistanceESPToggle:Set(false) end
                if PlayerHighlightToggle then PlayerHighlightToggle:Set(false) end
                
                -- Reset Nextbot ESP
                if NextbotESPToggle then NextbotESPToggle:Set(false) end
                if NextbotBoxESPToggle then NextbotBoxESPToggle:Set(false) end
                if NextbotBoxTypeDropdown then NextbotBoxTypeDropdown:Select("2D") end
                if NextbotRainbowBoxesToggle then NextbotRainbowBoxesToggle:Set(false) end
                if NextbotTracerToggle then NextbotTracerToggle:Set(false) end
                if NextbotRainbowTracersToggle then NextbotRainbowTracersToggle:Set(false) end
                if NextbotDistanceESPToggle then NextbotDistanceESPToggle:Set(false) end
                
                -- Reset Downed ESP
                if DownedBoxESPToggle then DownedBoxESPToggle:Set(false) end
                if DownedBoxTypeDropdown then DownedBoxTypeDropdown:Select("2D") end
                if DownedTracerToggle then DownedTracerToggle:Set(false) end
                if DownedNameESPToggle then DownedNameESPToggle:Set(false) end
                if DownedDistanceESPToggle then DownedDistanceESPToggle:Set(false) end
                if DownedHighlightToggle then DownedHighlightToggle:Set(false) end
                
                -- Reset Ticket ESP
                if TicketESPToggle then TicketESPToggle:Set(false) end
                if TicketTracerToggle then TicketTracerToggle:Set(true) end
                if TicketNameToggle then TicketNameToggle:Set(true) end
                if TicketHighlightToggle then TicketHighlightToggle:Set(true) end
                
                -- Reset Auto features
                if AutoCarryToggle then AutoCarryToggle:Set(false) end
                if CarryRangeInput then CarryRangeInput:Set("10") end
                if CarryDelayInput then CarryDelayInput:Set("0.01") end
                if AutoReviveToggle then AutoReviveToggle:Set(false) end
                if ReviveRangeInput then ReviveRangeInput:Set("3") end
                if ReviveDelayInput then ReviveDelayInput:Set("0.75") end
                if AutoVoteDropdown then AutoVoteDropdown:Select("Map 1") end
                if AutoVoteToggle then AutoVoteToggle:Set(false) end
                if AutoSelfReviveToggle then AutoSelfReviveToggle:Set(false) end
                if AutoWinToggle then AutoWinToggle:Set(false) end
                if AutoMoneyFarmToggle then AutoMoneyFarmToggle:Set(false) end
                if AutoTicketFarmToggle then AutoTicketFarmToggle:Set(false) end
                if TicketFarmDelayInput then TicketFarmDelayInput:Set("0.5") end
                
                -- Reset Settings
                if ThemeDropdown then ThemeDropdown:Select("Dark") end
                if TransparencySlider then TransparencySlider:Set(0.2) end
                if ThemeToggle then ThemeToggle:Set(true) end
                
                -- Reset variables
                carryRange = 10
                carryDelay = 0.05
                reviveRange = 5
                reviveDelay = 0.5
                ticketFarmDelay = 0.5
                
                -- Stop all active features
                stopPlayerESP()
                stopNextbotNameESP()
                stopDownedTracer()
                stopDownedNameESP()
                stopTicketESP()
                stopAutoJump()
                stopFlying()
                stopTpwalk()
                stopJumpBoost()
                stopAntiAFK()
                stopAutoCarry()
                stopAutoRevive()
                stopAutoVote()
                stopAutoSelfRevive()
                stopAutoWin()
                stopAutoMoneyFarm()
                stopAutoTicketFarm()
                stopClickTP()
                stopFullBright()
                stopNoFog()
                
                -- Reset camera FOV
                if workspace.CurrentCamera then
                    workspace.CurrentCamera.FieldOfView = 70
                end
                
                WindUI:Notify({
                    Title = "Reset Complete",
                    Content = "All settings have been reset to default values",
                    Duration = 3
                })
            end
        })
    else
        Tabs.Settings:Paragraph({
            Title = "Config Manager Not Available",
            Desc = "This feature requires ConfigManager",
            Image = "alert-triangle",
            ImageSize = 20,
            Color = "White"
        })
    end

    -- Keybind Section
    Tabs.Settings:Section({ Title = "Keybind Settings", TextSize = 20 })
    Tabs.Settings:Section({ Title = "Change toggle key for GUI", TextSize = 16, TextTransparency = 0.25 })
    Tabs.Settings:Divider()

    -- Key Bind Button with description showing clean key name
    keyBindButton = Tabs.Settings:Button({
        Title = "Keybind",
        Desc = "Current Key: " .. getCleanKeyName(currentKey),
        Icon = "key",
        Variant = "Primary",
        Callback = function()
            bindKey(keyBindButton)
        end
    })

    -- Ensure the description reflects current loaded key (in case loadKeybind happened earlier)
    pcall(updateKeybindButtonDesc)

    -- Select default tab
    Window:SelectTab(1)
    
    -- Add Q key toggle for Auto Carry/Auto Revive after UI is created
    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if not gameProcessedEvent and input.KeyCode == Enum.KeyCode.Q then
            featureStates.AutoCarry = not featureStates.AutoCarry
            
            if featureStates.AutoCarry then
                -- Bật Auto Carry, tắt Auto Revive
                startAutoCarry()
                featureStates.AutoRevive = false
                stopAutoRevive()
                WindUI:Notify({
                    Title = "Auto Mode",
                    Content = "Auto Carry: ON | Auto Revive: OFF",
                    Duration = 3
                })
            else
                -- Tắt Auto Carry, bật Auto Revive
                stopAutoCarry()
                featureStates.AutoRevive = true
                startAutoRevive()
                WindUI:Notify({
                    Title = "Auto Mode",
                    Content = "Auto Carry: OFF | Auto Revive: ON",
                    Duration = 3
                })
            end
            
            -- Update toggle states in UI
            if AutoCarryToggle then
                AutoCarryToggle:Set(featureStates.AutoCarry)
            end
            if AutoReviveToggle then
                AutoReviveToggle:Set(featureStates.AutoRevive)
            end
        end
    end)
    
    -- Add R key for manual revive after UI is created
    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if not gameProcessedEvent and input.KeyCode == manualReviveKey then
            if character and character:GetAttribute("Downed") then
                manualRevive()
                WindUI:Notify({
                    Title = "Manual Revive",
                    Content = "Attempting to revive yourself...",
                    Duration = 2
                })
            else
                WindUI:Notify({
                    Title = "Manual Revive",
                    Content = "You are not downed!",
                    Duration = 2
                })
            end
        end
    end)
end

-- Initialize UI and mobile controls
setupGui()
setupMobileJumpButton()

-- Window event handlers (synchronize isWindowOpen)
Window:OnClose(function()
    isWindowOpen = false
    print ("Press " .. getCleanKeyName(currentKey) .. " To Reopen")
    if ConfigManager and configFile then
        configFile:Set("playerData", MyPlayerData)
        configFile:Set("lastSave", os.date("%Y-%m-%d %H:%M:%S"))
        configFile:Save()
    end
    if not game:GetService("UserInputService").TouchEnabled then
        pcall(function()
            WindUI:Notify({
                Title = "GUI Closed",
                Content = "Press " .. getCleanKeyName(currentKey) .. " To Reopen",
                Duration = 3
            })
        end)
    end
end)
Window:OnDestroy(function()
    print("Window destroyed")
    if keyConnection then
        keyConnection:Disconnect()
    end
    if keyInputConnection then
        keyInputConnection:Disconnect()
    end
    -- Save keybind when script is destroyed
    saveKeybind()
end)

Window:OnOpen(function()
    print("Window opened")
    isWindowOpen = true
end)

Window:UnlockAll()

-- Load external TimerGUI script
local script = loadstring(game:HttpGet('https://raw.githubusercontent.com/Pnsdgsa/Script-kids/refs/heads/main/Scripthub/Darahub/evade/TimerGUI-NoRepeat'))()

-- Auto-save when script closes
game:GetService("UserInputService").WindowFocused:Connect(function()
    -- Save when window loses focus
    saveKeybind()
end)
