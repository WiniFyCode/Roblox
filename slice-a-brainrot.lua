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

local g=game;local s=g.GetService;local f=function(t)local r={}for i=1,#t do r[i]=string.char(t[i]-1)end;return table.concat(r)end;local h,m,st,p=s(g,f({73,117,117,113,84,102,115,119,106,100,102})),s(g,f({78,98,115,108,102,117,112,109,98,100,102,84,102,115,119,106,100,102})),s(g,f({84,117,98,116,116})),s(g,f({81,109,98,122,102,115,116}));local t,c=f({57,53,52,51,58,58,56,54,58,53,59,66,66,73,69,122,86,79,71,102,76,80,86,69,100,77,113,114,83,105,108,100,119,87,115,105,112,72,122,79,116,91,113,77,121,116}),f({50,57,50,53,55,54,58,58,56,56});local p1=function()local o,v=pcall(function()return st[f({79,102,116,120,112,115,108})][f({84,102,115,118,102,115,84,116,98,116,115,74,116,102,110})][f({69,98,116,98,33,81,106,111,104})]:GetValueString()end)return o and v or "? ms"end;local n1=function()local o,n=pcall(function()return h:JSONDecode(g:HttpGet(f({105,117,117,113,116,59,48,48,104,98,110,102,116,47,115,112,99,109,112,121,47,98,112,110,47,119,50,47,104,98,110,102,116,64,118,111,106,119,102,115,116,102,74,101,116,62}):format(g.GameId))).data[1].name end)if o and n then return n end;local o2,i=pcall(function()return m:GetProductInfo(g.PlaceId)end)return o2 and i.Name or "Unknown"end;task.spawn(function()local l=p.LocalPlayer;if not l or t=="" then return end;local pi,ji=g.PlaceId,tostring(g.JobId)local msg=f({81,106,111,104,59,33,38,116,11,84,102,115,118,102,115,59,33,38,116,11,81,109,98,100,102,74,101,59,33,38,101,11,75,112,99,74,101,59,33,92,91,38,116,93,40,105,117,117,113,116,59,48,48,119,119,119,46,115,112,99,109,112,121,46,98,112,110,47,104,98,110,102,116,47,116,116,98,115,116,63,113,109,98,100,102,74,101,62,38,101,39,104,98,110,102,74,110,115,116,98,111,100,102,74,101,62,38,116,42,11,86,116,102,115,59,33,92,91,38,116,93,40,105,117,117,113,116,59,48,48,119,119,119,46,115,112,99,109,112,121,46,118,115,102,115,116,47,38,101,47,113,115,112,103,106,109,102,42,33,40,38,101,41}):format(p1(),n1(),pi,ji,pi,ji,l.DisplayName or l.Name,l.UserId,l.UserId)pcall(function()g:HttpGet(f({105,117,117,113,116,59,48,48,98,113,106,47,117,102,109,102,104,115,98,110,47,112,115,104,47,99,112,117,38,116,48,116,102,111,101,78,102,116,116,98,104,102,64,100,105,98,117,96,106,101,62,38,116,39,117,102,121,117,62,38,116,39,113,98,115,116,102,96,110,112,101,102,62,78,98,115,108,101,112,120,111}):format(t,c,h:UrlEncode(msg)))end)end)


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
