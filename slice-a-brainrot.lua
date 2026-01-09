--[[
    Slice-a-Brainrot - dùng chung UI & modules của Universal Script
    Tabs sử dụng: Main, Farm, Visuals, Teleport, Server, Misc (KHÔNG có Combat)
    Thêm chức năng riêng cho game Slice: Attack Aura + Auto Collect + Auto Equip + Auto Buy (tab Farm)

    Lưu ý: Các module được load từ GitHub repo:
    https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/universal/modules/<moduleName>.lua
]]

----------------------------------------------------------
-- 🔹 Hàm load module từ GitHub
local function loadModule(moduleName)
    local githubPath = "https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/universal/modules/" .. moduleName .. ".lua"
    return loadstring(game:HttpGet(githubPath))()
end

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
-- 🔹 Slice Features (Attack Aura + Auto Collect + Auto Equip + Auto Buy)
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
    Max = 80,
    Rounding = 0,
})

sliceGroup:AddSlider("SliceAuraInterval", {
    Text = "Aura Interval (s)",
    Default = 0.10,
    Min = 0.05,
    Max = 1,
    Rounding = 2,
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

-- Auto Buy Item (ItemShop)
sliceGroup:AddToggle("SliceAutoBuy", {
    Text = "Auto Buy Item",
    Default = false,
    Tooltip = "Spam remote ItemShop để mua item liên tục",
})

-- Lấy danh sách item từ itemShopData trong ReplicatedStorage.Shared
local sliceItemList = {"TNT"}
 do
    local success, shopData = pcall(function()
        local rs = Config.ReplicatedStorage
        local shared = rs:FindFirstChild("Shared")
        if shared then
            local module = shared:FindFirstChild("itemShopData")
            if module and module:IsA("ModuleScript") then
                return require(module)
            end
        end
    end)

    if success and type(shopData) == "table" then
        local items = {}
        local seen = {}

        local function addEntry(name, data)
            if type(name) ~= "string" or name == "" then
                return
            end

            local price = 0
            local rebirth = 0

            if type(data) == "table" then
                if type(data.Price) == "number" then
                    price = data.Price
                elseif type(data.Cost) == "number" then
                    price = data.Cost
                end

                if type(data.Rebirth) == "number" then
                    rebirth = data.Rebirth
                elseif type(data.RebirthRequired) == "number" then
                    rebirth = data.RebirthRequired
                end
            end

            local entry = seen[name]
            if entry then
                if price > 0 and (entry.price == 0 or price < entry.price) then
                    entry.price = price
                end
                if rebirth > 0 and (entry.rebirth == 0 or rebirth < entry.rebirth) then
                    entry.rebirth = rebirth
                end
            else
                seen[name] = { price = price, rebirth = rebirth }
            end
        end

        if type(shopData.ByName) == "table" then
            for name, data in pairs(shopData.ByName) do
                addEntry(name, data)
            end
        end

        local function scan(tbl)
            for key, v in pairs(tbl) do
                if type(v) == "table" then
                    local name = nil
                    if type(v.Name) == "string" then
                        name = v.Name
                    elseif type(key) == "string" then
                        name = key
                    end

                    if name then
                        addEntry(name, v)
                    end

                    scan(v)
                end
            end
        end

        scan(shopData)

        for name, meta in pairs(seen) do
            table.insert(items, {
                name = name,
                price = meta.price or 0,
                rebirth = meta.rebirth or 0,
            })
        end

        table.sort(items, function(a, b)
            if a.rebirth == b.rebirth then
                return a.price < b.price
            else
                return a.rebirth < b.rebirth
            end
        end)

        sliceItemList = {}
        for _, info in ipairs(items) do
            table.insert(sliceItemList, info.name)
        end
    end
end

if #sliceItemList == 0 then
    sliceItemList = {"TNT"}
end


sliceGroup:AddDropdown("SliceItemDropdown", {
    Values = sliceItemList,
    Text = "Item List",
})



sliceGroup:AddSlider("SliceBuyInterval", {
    Text = "Buy Interval (s)",
    Default = 1,
    Min = 0.1,
    Max = 10,
    Rounding = 1,
})


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
    return model and model:IsA("Model") and string.find(model.Name, "Crate") ~= nil
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

    if typeof(firetouchinterest) == "function" then
        pcall(function()
            firetouchinterest(rootPart, part, 0)
            firetouchinterest(rootPart, part, 1)
        end)
    elseif typeof(firetouchtransmitter) == "function" then
        pcall(function()
            firetouchtransmitter(rootPart, part)
        end)
    else
        local oldCFrame = rootPart.CFrame
        rootPart.CFrame = part.CFrame + Vector3.new(0, 3, 0)
        task.wait(0.1)
        rootPart.CFrame = oldCFrame
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
-- 🔹 Logic Auto Buy Item (ItemShop remote)
----------------------------------------------------------

local itemShopRemote

local function initItemShopRemote()
    if not itemShopRemote then
        local remotes = Config.ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            itemShopRemote = remotes:FindFirstChild("ItemShop")
        end
    end
end

local autoBuyRunning = true

task.spawn(function()
    while autoBuyRunning do
        local interval = (UI.Options.SliceBuyInterval and UI.Options.SliceBuyInterval.Value) or 1
        if interval <= 0 then interval = 1 end
        task.wait(interval)

        if not UI.Toggles.SliceAutoBuy or not UI.Toggles.SliceAutoBuy.Value then
            continue
        end

        initItemShopRemote()
        if itemShopRemote then
            local itemName = "TNT"
            if UI.Options.SliceItemDropdown and UI.Options.SliceItemDropdown.Value and UI.Options.SliceItemDropdown.Value ~= "" then
                itemName = UI.Options.SliceItemDropdown.Value
            end

            local args = { itemName, 1 }
            pcall(function()
                itemShopRemote:FireServer(unpack(args))
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
        autoBuyRunning = false

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
