--[[
    Zombie Hyperloot - Main Entry Point
    by WiniFy

    Modular version - Load từng modules để giảm lag
]]

----------------------------------------------------------
-- 🔹 Load Modules
local Config, Visuals, Combat, ESP, Movement, Map, Farm, HUD, UI, Character, Loader

-- 1. Load & Start Loader
Loader = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/loader.lua"))()
Loader.start()
Loader.update(0.1, "Loading Config...")
Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/config.lua"))()

Loader.update(0.2, "Loading Visuals...")
Visuals = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/visuals.lua"))()
Visuals.init(Config)

Loader.update(0.3, "Loading Combat...")
Combat = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/combat.lua"))()
Combat.init(Config, Visuals)

Loader.update(0.4, "Loading ESP...")
ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/esp.lua"))()
ESP.init(Config)

Loader.update(0.5, "Loading Movement...")
Movement = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/movement.lua"))()
Movement.init(Config)

Loader.update(0.6, "Loading Map...")
Map = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/map.lua"))()
Map.init(Config)
    
Loader.update(0.7, "Loading Farm...")
Farm = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/farm.lua"))()
Farm.init(Config, ESP)

Loader.update(0.8, "Loading HUD & Character...")
HUD = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/hud.lua"))()
HUD.init(Config)

Character = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/character.lua"))()
Character.init(Config)

Loader.update(0.9, "Starting UI...")
UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/ui.lua"))()
UI.init(Config, Combat, ESP, Movement, Map, Farm, HUD, Visuals, Character)

-- Stop Loader
Loader.stop()

----------------------------------------------------------
-- 🔹 Cleanup Function
local inputBeganConnection = nil

local function cleanupScript()
    if Config.scriptUnloaded then return end
    Config.scriptUnloaded = true

    -- Tắt các toggle chính
    Config.aimbotEnabled = false
    Config.espPlayerEnabled = false
    Config.espZombieEnabled = false
    Config.espChestEnabled = false
    Config.hitboxEnabled = false
    Config.teleportEnabled = true
    Config.cameraTeleportEnabled = false
    Config.cameraTeleportActive = false
    Config.autoBulletBoxEnabled = false
    Config.autoSkillEnabled = false
    Config.speedEnabled = false
    Config.supplyESPEnabled = false
    Config.espBobEnabled = true
    Config.autoDoorEnabled = false
    Config.autoBuyChristmasGiftBoxEnabled = false
    Config.autoBuySantaClausGiftEnabled = false

    -- Disconnect only main-level connections
    if inputBeganConnection then
        inputBeganConnection:Disconnect()
        inputBeganConnection = nil
    end

    -- Cleanup modules
    Combat.cleanup()
    ESP.cleanup()
    Movement.cleanup()
    Map.cleanup()
    HUD.cleanup()
    Visuals.cleanup()
    Character.cleanup()
    UI.cleanup()

    -- Khôi phục hitbox
    for _, zombie in ipairs(Config.entityFolder:GetChildren()) do
        Combat.restoreHitbox(zombie)
    end

    -- Reset camera và nhân vật
    local char = Config.localPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.Anchored = false end

    local camera = Config.Workspace.CurrentCamera
    if camera and char then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            camera.CameraSubject = humanoid
            camera.CameraType = Enum.CameraType.Custom
        end
    end
end



----------------------------------------------------------
-- 🔹 Setup ESP
ESP.initializePlayerESP()
ESP.watchChestDescendants()
if Config.espChestEnabled then
    ESP.applyChestESP()
end
-- 🔹 Start ESP runtime loop (ESP tự quản lý mọi thứ)
ESP.start()



----------------------------------------------------------
-- 🔹 Start runtime systems (modules tự quản lý loop/connections)
Combat.initFOVCircle()
Combat.setRotationSmoothness(Config.autoRotateSmoothness)
Combat.start()

Movement.start()

-- HUD runtime + character hook vẫn ở HUD module (sẽ refactor tiếp)
HUD.start()

-- Farm/Map sẽ được refactor tiếp theo hướng start()/stop()
Farm.start()
Map.start()

-- Character skill loops (sẽ refactor tiếp)
Character.startAllSkillLoops()


----------------------------------------------------------
-- 🔹 End key - Cleanup (only)
inputBeganConnection = Config.UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or Config.scriptUnloaded then return end
    if input.KeyCode == Enum.KeyCode.End then
        cleanupScript()
    end
end)

----------------------------------------------------------
-- 🔹 Load UI
UI.loadLibraries()
UI.createWindow()
UI.buildAllTabs(cleanupScript)

-- Success notification
if Config.UI and Config.UI.Library then
    Config.UI.Library:Notify({
        Title = "Zombie Hyperloot",
        Description = "Script loaded successfully!\nPress Right Ctrl to open menu.",
        Time = 6
    })
end

print("[ZombieHyperloot] Script loaded successfully!")
print("[ZombieHyperloot] Press Right Ctrl to open menu")
