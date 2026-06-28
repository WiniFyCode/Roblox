-- Tải Obsidian UI Library.
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

-- Lấy bảng Options và Toggles để đọc giá trị UI.
local Options = Library.Options
local Toggles = Library.Toggles

-- Import các service cần dùng (Players, UserInputService, RunService) để gọn hơn.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Cấu hình mặc định cho script.
local Config = {
    BaseNumber = 5,
    BaseSelectionMode = "Auto",
    CollectDelay = 0.1,
    AutoCollect = false,
    AutoEquip = false,
    AutoCollectBest = false,
    WalkSpeed = 16,
    JumpPower = 50,
    WalkSpeedActive = false,
    JumpPowerActive = false,
    MaxCamDistance = 20,
    InfJump = false,
    FlyEnabled = false,
    FlySpeed = 50,
    NoclipEnabled = false,
    BrainrotRefreshDelay = 0.25,
    BrainrotDropdownRefreshDelay = 1,
    TopBrainrotESPRefreshDelay = 1,
    TopBrainrotESP = false,
    Unloaded = false,
}

-- Tạo cửa sổ chính của Obsidian UI.
local Window = Library:CreateWindow({
    Title = "Lucky Block Auto Collect",
    Footer = "by WiniFy",
    NotifySide = "Right",
    ShowCustomCursor = false,
})

-- Tạo tab chính để điều khiển auto collect.
local Tabs = {
    Main = Window:AddTab("Main", "box"),
    Brainrot = Window:AddTab("Brainrot", "scan-eye"),
    Equip = Window:AddTab("Equip Best", "refresh-cw"),
    Teleport = Window:AddTab("Teleport", "map-pin"),
    Misc = Window:AddTab("Misc", "rocket"),
    Settings = Window:AddTab("UI Settings", "settings"),
}

local CollectGroup = Tabs.Main:AddLeftGroupbox("Auto Collect", "mouse-pointer-click")
local InfoGroup = Tabs.Main:AddRightGroupbox("Info", "info")

-- Lấy HumanoidRootPart của người chơi để mô phỏng chạm nút collect.
local function getHumanoidRootPart()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    return character:WaitForChild("HumanoidRootPart")
end

-- Đọc tên chủ base từ PlayerInfo.BillboardGui.TextLabel.
local function getBaseOwnerName(base)
    local playerInfo = base and base:FindFirstChild("PlayerInfo")
    local billboard = playerInfo and playerInfo:FindFirstChild("BillboardGui")
    local label = billboard and billboard:FindFirstChild("TextLabel")
    if label and label:IsA("TextLabel") then
        return label.Text
    end

    return nil
end

-- Tìm base có PlayerInfo trùng tên hiển thị trong game của người chơi hiện tại.
local function detectOwnedBase()
    local bases = workspace.GameArea and workspace.GameArea:FindFirstChild("Bases")
    if not bases then
        return nil
    end

    local localPlayer = game.Players.LocalPlayer
    local displayName = localPlayer.DisplayName
    local accountName = localPlayer.Name

    for _, base in ipairs(bases:GetChildren()) do
        if base.Name:match("^Base%d+$") then
            local ownerName = getBaseOwnerName(base)
            -- So sánh cả DisplayName và username để chắc chắn khớp.
            if ownerName == displayName or ownerName == accountName then
                return base
            end
        end
    end

    return nil
end

-- Lấy spawn part theo map number (số đầu trong BrainrotSpawns["X"]["Y"]).
-- Số sau anh không quan tâm, cứ lấy BasePart đầu tiên trong group đó.
local function getSpawnByMapNumber(mapNumber)
    mapNumber = tostring(mapNumber)
    local spawns = workspace:FindFirstChild("GameArea")
        and workspace.GameArea:FindFirstChild("Interactables")
        and workspace.GameArea.Interactables:FindFirstChild("BrainrotSpawns")
    if not spawns then
        return nil
    end

    local group = spawns:FindFirstChild(mapNumber)
    if not group then
        return nil
    end

    return group:FindFirstChildWhichIsA("BasePart")
end

-- Quét toàn bộ map numbers có trong BrainrotSpawns (key là số: "1", "2", "3", ...).
-- Trả về danh sách chuỗi đã sort tăng dần vì Obsidian dropdown ổn định hơn với string values.
local function getAvailableMapNumbers()
    local spawns = workspace:FindFirstChild("GameArea")
        and workspace.GameArea:FindFirstChild("Interactables")
        and workspace.GameArea.Interactables:FindFirstChild("BrainrotSpawns")
    if not spawns then
        return { "1" }
    end

    local numbers = {}
    for _, group in ipairs(spawns:GetChildren()) do
        local num = tonumber(group.Name)
        if num then
            table.insert(numbers, group.Name)
        end
    end

    table.sort(numbers, function(left, right)
        return tonumber(left) < tonumber(right)
    end)

    return numbers
end

-- Lấy FinishLine duy nhất trong GameplayZones["1"].
-- FinishLine là Model (không phải BasePart), teleportToPart sẽ tự dùng GetPivot().
local function getFinishLinePart()
    local zones = workspace:FindFirstChild("GameArea")
        and workspace.GameArea:FindFirstChild("GameplayZones")
    if not zones then
        return nil
    end

    local zone1 = zones:FindFirstChild("1")
    return zone1 and zone1:FindFirstChild("FinishLine") or nil
end

-- Teleport player tới 1 instance (BasePart hoặc Model, offset lên 5 studs để không bị stuck).
-- BasePart dùng .CFrame; Model dùng :GetPivot() vì Model không có .CFrame.
local function teleportToPart(target)
    if not target then
        return false, "Không tìm thấy điểm đến."
    end

    local character = game.Players.LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return false, "Không tìm thấy HumanoidRootPart."
    end

    -- Tính CFrame đích: BasePart lấy .CFrame, Model dùng :GetPivot() (Roblox API).
    local targetCFrame
    if target:IsA("BasePart") then
        targetCFrame = target.CFrame
    elseif target:IsA("Model") then
        targetCFrame = target:GetPivot()
    else
        return false, "Điểm đến không phải BasePart/Model."
    end

    hrp.CFrame = targetCFrame + Vector3.new(0, 5, 0)
    return true
end

-- Lấy BrainrotStands theo base được chọn (auto-detect hoặc manual qua dropdown).
local function getBrainrotStands()
    local bases = workspace.GameArea:FindFirstChild("Bases")
    if not bases then
        return nil, "Không tìm thấy workspace.GameArea.Bases."
    end

    local mode = Config.BaseSelectionMode or "Auto"
    local base = nil

    -- Manual mode: dùng đúng base user chọn từ dropdown.
    if mode ~= "Auto" then
        base = bases:FindFirstChild(mode)
        if not base then
            return nil, "Base đã chọn (" .. mode .. ") không tồn tại."
        end
    else
        -- Auto mode: ưu tiên detect theo tên player, fallback Config.BaseNumber.
        base = detectOwnedBase() or bases:FindFirstChild("Base" .. tostring(Config.BaseNumber))
        if not base then
            return nil, "Không tìm thấy base của bạn (PlayerInfo)."
        end
    end

    local stands = base:FindFirstChild("BrainrotStands")
    if not stands then
        return nil, base.Name .. " không có BrainrotStands."
    end

    return stands, nil, base.Name
end

-- Đổi text object của Roblox UI về chuỗi an toàn.
local function readText(instance)
    if instance and instance:IsA("TextLabel") then
        return instance.Text
    end

    return "?"
end

-- Chuyển income dạng $1.2K/s, $3M/s, $5.5Qd/s, ... thành số để so sánh mạnh/yếu.
local function parseIncomeValue(text)
    local cleaned = tostring(text):gsub("[$,%s/]", ""):gsub("s$", "")
    local numberText, suffix = cleaned:match("([%d%.]+)(%a*)")
    local number = tonumber(numberText) or 0

    -- Bảng suffix đầy đủ (short scale) — phủ hầu hết game Roblox hiện nay.
    -- Nếu sau này game thêm suffix mới thì cứ thêm key vào đây.
    local multipliers = {
        K  = 1e3,     -- Thousands
        M  = 1e6,     -- Millions
        B  = 1e9,     -- Billions
        T  = 1e12,    -- Trillion
        Qa = 1e15,    -- Quadrillion
        Qd = 1e15,    -- Quadrillion
        Qi = 1e18,    -- Quintillion
        Qn = 1e18,    -- Quintillion alias
        Sx = 1e21,    -- Sextillion
        Sp = 1e24,    -- Septillion
        Oc = 1e27,    -- Octillion
        No = 1e30,    -- Nonillion
        Dc = 1e33,    -- Decillion
        Ud = 1e36,    -- Undecillion
        Dd = 1e39,    -- Duodecillion
        Td = 1e42,    -- Tredecillion
        Qad = 1e45,   -- Quattuordecillion
        Qid = 1e48,   -- Quindecillion
        Sxd = 1e51,   -- Sexdecillion
        Spd = 1e54,   -- Septendecillion
        Ocd = 1e57,   -- Octodecillion
        Nod = 1e60,   -- Novemdecillion
        Vg  = 1e63,   -- Vigintillion
        Uvg = 1e66,   -- Unvigintillion
        Dvg = 1e69,   -- Duovigintillion
    }

    -- Tìm multiplier: thử nguyên suffix trước, rồi 2 ký tự đầu, rồi 1 ký tự.
    if suffix and suffix ~= "" then
        if multipliers[suffix] then
            return number * multipliers[suffix]
        end
        if #suffix >= 2 and multipliers[suffix:sub(1, 2)] then
            return number * multipliers[suffix:sub(1, 2)]
        end
        if multipliers[suffix:sub(1, 1)] then
            return number * multipliers[suffix:sub(1, 1)]
        end
    end

    return number
end

-- Lấy ProximityPrompt nằm trực tiếp hoặc nằm sâu bên trong Brainrot.
local function findBrainrotPrompt(brainrot)
    if brainrot:IsA("ProximityPrompt") then
        return brainrot
    end

    return brainrot:FindFirstChildWhichIsA("ProximityPrompt", true)
end

-- Fire ProximityPrompt để collect một Brainrot cụ thể.
local function collectBrainrot(brainrot)
    local prompt = brainrot and findBrainrotPrompt(brainrot)
    if not prompt then
        return false
    end

    if typeof(fireproximityprompt) == "function" then
        fireproximityprompt(prompt)
        return true
    end

    return false
end

-- Lấy danh sách container chứa ToolModel1 (game này chỉ có 1 instance duy nhất trong workspace).
local function getPlayerToolModels()
    local results = {}
    local seen = {}

    -- Quét toàn bộ workspace, tìm mọi instance tên "ToolModel1".
    -- Game này chỉ có duy nhất 1 instance, lấy parent của nó là container tool.
    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc.Name == "ToolModel1" and desc.Parent and not seen[desc.Parent] then
            seen[desc.Parent] = true
            table.insert(results, desc.Parent)
        end
    end

    return results
end

-- Debug log: liệt kê tất cả instance trong workspace có tên ToolModel1 để dễ truy vết.
local function debugLogToolContainers()
    local count = 0
    local paths = {}
    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc.Name == "ToolModel1" then
            count += 1
            -- Tạo path tương đối từ workspace.
            local pathParts = { desc.Name }
            local current = desc
            while current.Parent and current.Parent ~= workspace do
                current = current.Parent
                table.insert(pathParts, 1, current.Name)
            end
            table.insert(paths, "workspace." .. table.concat(pathParts, "."))
        end
    end
    if count == 0 then
        warn("[LuckyBlock][Debug] Không tìm thấy ToolModel1 nào trong workspace.")
    else
        warn("[LuckyBlock][Debug] Tìm thấy " .. count .. " ToolModel1 instance(s):")
        for _, p in ipairs(paths) do
            warn("  - " .. p)
        end
    end
end

-- Đọc thông tin từ cấu trúc BrainrotInfo.Frame của tool cầm tay hoặc của stand.
local function readBrainrotInfo(root)
    if not root then
        return nil
    end

    local billboard = root:FindFirstChild("BillboardAttachment", true)
    local info = billboard and billboard:FindFirstChild("BrainrotInfo")
    local frame = info and info:FindFirstChild("Frame")
    if not frame then
        return nil
    end

    local displayName = frame:FindFirstChild("DisplayName")
    local income = frame:FindFirstChild("Income")
    local tier = frame:FindFirstChild("Tier")
    if not income then
        return nil
    end

    local incomeText = readText(income)
    return {
        Name = readText(displayName),
        Tier = readText(tier),
        Income = incomeText,
        IncomeValue = parseIncomeValue(incomeText),
    }
end

-- Lấy root model của tool đang cầm (đi từ ToolModel1 trở vào).
local function getToolModel1Root(tool)
    if not tool then
        return nil
    end

    return tool:FindFirstChild("ToolModel1")
end

-- Lấy ReplacePrompt của một stand.
local function getReplacePrompt(stand)
    local displayStand = stand:FindFirstChild("DisplayStand")
    if not displayStand then
        return nil
    end

    local options = displayStand:FindFirstChild("OptionsAttachment")
    if not options then
        return nil
    end

    return options:FindFirstChild("ReplacePrompt")
end

-- Lấy brainrot hiện tại đứng trên stand (nếu có).
local function getStandBrainrotInfo(stand)
    local displayStand = stand:FindFirstChild("DisplayStand")
    if not displayStand then
        return nil
    end

    local attachment = displayStand:FindFirstChild("BrainrotAttachment")
    if not attachment then
        return nil
    end

    for _, child in ipairs(attachment:GetChildren()) do
        if child:IsA("Model") or child:IsA("Folder") then
            local info = readBrainrotInfo(child)
            if info then
                return info
            end
        end
    end

    return nil
end

-- Quét tất cả stand trong base hiện tại, trả về danh sách.
local function getAllStands()
    local brainrotStands = getBrainrotStands()
    if not brainrotStands then
        return {}
    end

    local stands = {}
    for _, floor in ipairs(brainrotStands:GetChildren()) do
        if floor.Name:match("^Floor%d+$") then
            for _, stand in ipairs(floor:GetChildren()) do
                if getReplacePrompt(stand) then
                    table.insert(stands, { Stand = stand, Floor = floor })
                end
            end
        end
    end

    return stands
end

-- Tìm stand yếu nhất (income nhỏ nhất) để thay thế.
-- Trả về (entry, value) — entry.StandInfo chứa thông tin brainrot hiện đứng trên stand (nếu có).
local function findWeakestStand(stands)
    local weakest = nil
    local weakestValue = math.huge

    for _, entry in ipairs(stands) do
        local info = getStandBrainrotInfo(entry.Stand)
        -- Lưu info lại để caller dùng (hiển thị tên brainrot bị thay).
        entry.StandInfo = info

        if info then
            if info.IncomeValue < weakestValue then
                weakestValue = info.IncomeValue
                weakest = entry
            end
        else
            -- Stand trống cũng ưu tiên thay.
            weakest = entry
            weakestValue = -math.huge
        end
    end

    return weakest, weakestValue
end

-- Thay brainrot cầm tay vào stand nếu mạnh hơn.
-- Trả về (status, message):
--   status = "replaced" → thay thật sự, có thông báo.
--   status = "skipped"  → bỏ qua (tay yếu hơn stand yếu nhất), không notify auto.
--   status = "error"    → lỗi (không tìm thấy base/stand/tool/prompt), không notify auto.
local function equipBestOnce()
    local ownedBase = detectOwnedBase()
    if not ownedBase then
        return "error", "Không tìm thấy base của bạn (PlayerInfo)."
    end

    local tools = getPlayerToolModels()
    local stands = getAllStands()
    if #stands == 0 then
        return "error", "Không tìm thấy stand trong " .. ownedBase.Name .. "."
    end

    if #tools == 0 then
        -- Debug: in ra path thực tế của ToolModel1 để dò lỗi khi user báo không tìm thấy.
        debugLogToolContainers()
        return "error", "Không có Brainrot nào trong tay/Backpack."
    end

    local weakestStand, weakestValue = findWeakestStand(stands)
    if not weakestStand then
        return "error", "Không tìm thấy stand để thay."
    end

    local bestTool = nil
    local bestToolValue = -1
    for _, tool in ipairs(tools) do
        local root = getToolModel1Root(tool)
        local info = readBrainrotInfo(root)
        if info and info.IncomeValue > bestToolValue then
            bestToolValue = info.IncomeValue
            bestTool = info
        end
    end

    if not bestTool then
        return "error", "Không đọc được income của Brainrot cầm tay."
    end

    if bestToolValue <= weakestValue then
        return "skipped", ("Bỏ qua: tay (" .. bestTool.Income .. ") yếu hơn stand yếu nhất (" .. (weakestStand.StandInfo and weakestStand.StandInfo.Income or "trống") .. ").")
    end

    local prompt = getReplacePrompt(weakestStand.Stand)
    if not prompt or not prompt:IsA("ProximityPrompt") then
        return "error", "Stand yếu nhất không có ReplacePrompt."
    end

    if typeof(fireproximityprompt) == "function" then
        fireproximityprompt(prompt)
        local oldInfo = weakestStand.StandInfo
        local oldName = oldInfo and oldInfo.Name or "(trống)"
        local oldIncome = oldInfo and oldInfo.Income or "0"
        -- Notify chi tiết: thay brainrot nào → bằng brainrot nào, ở floor nào.
        return "replaced", ("Đã thay " .. oldName .. " (" .. oldIncome .. ") bằng " .. bestTool.Name .. " (" .. bestTool.Income .. ") ở " .. weakestStand.Floor.Name .. ".")
    end

    return "error", "fireproximityprompt không khả dụng."
end

-- Kiểm tra text timer có hợp lệ không.
-- Timer dạng "00:45" vẫn hợp lệ vì có phần giây > 0; chỉ toàn số 0 mới coi là không timer.
local function hasValidTimer(timeText)
    if not timeText or timeText == "" or timeText == "?" then
        return false
    end

    -- Duyệt mọi cụm số trong timer; nếu có bất kỳ số nào > 0 thì timer còn hiệu lực.
    for numberText in tostring(timeText):gmatch("%d+%.?%d*") do
        local number = tonumber(numberText) or 0
        if number > 0 then
            return true
        end
    end

    return false
end

-- Quét toàn bộ BrainrotContainer rồi sắp xếp theo income giảm dần.
-- includeNoTimer = true dùng cho Brainrot List để hiển thị đủ; false dùng cho Collect Best để bỏ qua con vĩnh viễn.
local function getAllBrainrots(includeNoTimer)
    local camera = workspace:FindFirstChild("Camera")
    local container = camera and camera:FindFirstChild("BrainrotContainer")

    local results = {}
    if not container then
        return results
    end

    for _, brainrot in ipairs(container:GetChildren()) do
        local info = brainrot:FindFirstChild("BrainrotInfo")
        local frame = info and info:FindFirstChild("Frame")
        local displayName = frame and frame:FindFirstChild("DisplayName")
        local tier = frame and frame:FindFirstChild("Tier")
        local income = frame and frame:FindFirstChild("Income")
        local timer = frame and frame:FindFirstChild("BrainrotInfoTimer")
        local time = timer and timer:FindFirstChild("Time")

        if frame and income then
            local timeText = readText(time)
            local timerValid = hasValidTimer(timeText)
            -- Brainrot List cần đủ dữ liệu; Collect Best/Auto Collect mới bỏ qua con không có timer.
            if includeNoTimer or timerValid then
                local incomeText = readText(income)
                table.insert(results, {
                    Instance = brainrot,
                    Name = readText(displayName),
                    Tier = readText(tier),
                    Income = incomeText,
                    Time = timerValid and timeText or "No timer",
                    HasTimer = timerValid,
                    IncomeValue = parseIncomeValue(incomeText),
                })
            end
        end
    end

    table.sort(results, function(left, right)
        return left.IncomeValue > right.IncomeValue
    end)

    return results
end

-- Chạm vào CollectButton của một stand nếu stand đó có nút hợp lệ.
local function collectStand(stand, humanoidRootPart)
    local collectButton = stand:FindFirstChild("CollectButton")
    if not collectButton then
        return false
    end

    local button = collectButton:FindFirstChild("Button")
    if not button then
        return false
    end

    local touchInterest = button:FindFirstChildOfClass("TouchTransmitter") or button:FindFirstChild("TouchInterest")
    if not touchInterest then
        return false
    end

    -- firetouchinterest dùng để kích hoạt TouchInterest giống như người chơi chạm vào nút.
    firetouchinterest(humanoidRootPart, button, 0)
    task.wait(0.05)
    firetouchinterest(humanoidRootPart, button, 1)

    return true
end

-- Quét tất cả Floor trong base và collect toàn bộ stand tìm được.
local function collectAllFloors()
    local brainrotStands, errMsg, baseName = getBrainrotStands()
    if not brainrotStands then
        Library:Notify({
            Title = "Lucky Block",
            Description = errMsg or "Không tìm thấy base hoặc BrainrotStands.",
            Time = 4,
        })
        return 0, nil
    end

    local collected = 0
    local humanoidRootPart = getHumanoidRootPart()

    -- Logic cũ: collect từng stand theo thứ tự, mỗi nút có delay riêng để game nhận đủ TouchInterest.
    for _, floor in ipairs(brainrotStands:GetChildren()) do
        if floor.Name:match("^Floor%d+$") then
            for _, stand in ipairs(floor:GetChildren()) do
                if collectStand(stand, humanoidRootPart) then
                    collected += 1
                    task.wait(Config.CollectDelay)
                end
            end
        end
    end

    return collected, baseName
end

-- Label hiển thị tên base đang dùng (sẽ được refresh theo auto-detect).
local BaseLabel = CollectGroup:AddLabel("Base đang dùng: đang quét...", true)

-- Quét danh sách BaseX có trong workspace.GameArea.Bases để đổ vào dropdown.
local function getAvailableBases()
    local bases = workspace:FindFirstChild("GameArea")
        and workspace.GameArea:FindFirstChild("Bases")
    if not bases then
        return { "Auto" }
    end

    local values = { "Auto" }
    for _, base in ipairs(bases:GetChildren()) do
        if base.Name:match("^Base%d+$") then
            table.insert(values, base.Name)
        end
    end

    -- Sắp xếp Base1, Base2, ... theo thứ tự số (Auto luôn ở đầu).
    table.sort(values, function(left, right)
        if left == "Auto" then
            return true
        end
        if right == "Auto" then
            return false
        end
        return tonumber(left:match("%d+")) < tonumber(right:match("%d+"))
    end)

    return values
end

-- Dropdown cho phép user chọn thủ công hoặc để Auto.
local BaseDropdown = CollectGroup:AddDropdown("BaseDropdown", {
    Values = getAvailableBases(),
    Default = 1,
    Multi = false,
    Text = "Chọn Base",
    Tooltip = "Auto = tự phát hiện theo tên nhân vật. Hoặc chọn Base cụ thể.",
    Callback = function(value)
        Config.BaseSelectionMode = value
        refreshBaseLabel()
    end,
})

-- Hàm refresh BaseLabel theo detectOwnedBase() hoặc manual.
local function refreshBaseLabel()
    local bases = workspace:FindFirstChild("GameArea")
        and workspace.GameArea:FindFirstChild("Bases")
    local mode = Config.BaseSelectionMode or "Auto"
    local labelText

    if mode == "Auto" then
        local owned = detectOwnedBase()
        if owned then
            labelText = "Base đang dùng: " .. owned.Name .. " (auto-detect)"
        elseif bases then
            local fallback = bases:FindFirstChild("Base" .. tostring(Config.BaseNumber))
            labelText = "Base đang dùng: " .. (fallback and fallback.Name or ("Base" .. tostring(Config.BaseNumber))) .. " (fallback)"
        else
            labelText = "Base đang dùng: không có"
        end
    else
        local selected = bases and bases:FindFirstChild(mode)
        labelText = "Base đang dùng: " .. (selected and selected.Name or mode) .. " (manual)"
    end

    BaseLabel:SetText(labelText)
end

refreshBaseLabel()

-- Refresh dropdown định kỳ để cập nhật base mới (player mới vào game).
task.spawn(function()
    while not Config.Unloaded and task.wait(5) do
        pcall(function()
            local newValues = getAvailableBases()
            BaseDropdown:SetValues(newValues)
            refreshBaseLabel()
        end)
    end
end)

-- Slider chỉnh delay giữa mỗi lần collect để tránh spam quá nhanh.
CollectGroup:AddSlider("CollectDelaySlider", {
    Text = "Collect Delay",
    Default = Config.CollectDelay,
    Min = 0.1,
    Max = 1,
    Rounding = 1,
    Suffix = "s",
    Callback = function(value)
        Config.CollectDelay = value
    end,
})

-- Nút collect thủ công một lần.
CollectGroup:AddButton({
    Text = "Collect All Floors",
    Func = function()
        local collected, baseName = collectAllFloors()
        Library:Notify({
            Title = "Lucky Block",
            Description = "Đã collect " .. tostring(collected) .. " stand ở " .. tostring(baseName or ("Base" .. tostring(Config.BaseNumber))) .. ".",
            Time = 4,
        })
    end,
    Tooltip = "Collect tất cả floor trong base đã chọn.",
})

-- Toggle tự động collect lặp lại theo delay đang đặt.
CollectGroup:AddToggle("AutoCollectToggle", {
    Text = "Auto Collect",
    Default = false,
    Tooltip = "Tự động collect tất cả floor liên tục.",
    Callback = function(value)
        Config.AutoCollect = value
    end,
})

-- Vòng lặp auto collect chạy khi toggle bật và tự dừng khi unload script.
task.spawn(function()
    while not Config.Unloaded and task.wait(0.5) do
        if Config.AutoCollect then
            collectAllFloors()
        end
    end
end)

local EquipGroup = Tabs.Equip:AddLeftGroupbox("Auto Equip Best", "refresh-cw")
local EquipInfoGroup = Tabs.Equip:AddRightGroupbox("Status", "info")

EquipGroup:AddButton({
    Text = "Equip Best Now",
    Func = function()
        local status, message = equipBestOnce()
        Library:Notify({
            Title = "Equip Best",
            Description = message,
            Time = 4,
        })
    end,
    Tooltip = "Tìm stand yếu nhất trong base, nếu brainrot cầm tay mạnh hơn thì replace.",
})

EquipGroup:AddToggle("AutoEquipToggle", {
    Text = "Auto Equip Best",
    Default = false,
    Tooltip = "Tự động tìm và thay stand yếu nhất liên tục.",
    Callback = function(value)
        Config.AutoEquip = value
    end,
})

EquipGroup:AddSlider("AutoEquipDelay", {
    Text = "Equip Delay",
    Default = 1,
    Min = 1,
    Max = 10,
    Rounding = 0,
    Suffix = "s",
    Callback = function(value)
        Config.AutoEquipDelay = value
    end,
})

EquipInfoGroup:AddLabel("1. Mang Brainrot cần thay vào tay hoặc để trong Backpack.", true)
EquipInfoGroup:AddLabel("2. Bấm Equip Best Now để thay thủ công.", true)
EquipInfoGroup:AddLabel("3. Bật Auto Equip Best nếu muốn tự động lặp.", true)

-- Vòng lặp auto equip: chỉ notify khi thay thật sự, bỏ qua khi 'skipped' hoặc 'error' để tránh spam.
task.spawn(function()
    while not Config.Unloaded and task.wait(0.5) do
        if Config.AutoEquip then
            local status, message = equipBestOnce()
            if status == "replaced" then
                Library:Notify({
                    Title = "Auto Equip Best",
                    Description = message,
                    Time = 3,
                })
            end
            task.wait(Config.AutoEquipDelay or 1)
        end
    end
end)

-- Tab Teleport: danh sách các map spawn + nút back to line.
local TeleportGroup = Tabs.Teleport:AddLeftGroupbox("Map Spawn", "map-pin")
local TeleportInfoGroup = Tabs.Teleport:AddRightGroupbox("Info", "info")

-- Khai báo trước để refreshMapDropdownValues dùng đúng dropdown local, không rơi sang global nil.
local MapDropdown
local SelectedMap

-- Quét dynamic tất cả map numbers từ workspace.GameArea.Interactables.BrainrotSpawns.
-- Tránh hardcode vì game có thể thêm map mới.
local function refreshMapDropdownValues()
    local values = getAvailableMapNumbers()
    -- Nếu dropdown đã tạo thì cập nhật; nếu chưa thì trả về danh sách để khởi tạo.
    if MapDropdown then
        pcall(function()
            MapDropdown:SetValues(values)
        end)
        -- Nếu map đang chọn không còn trong danh sách mới (game xóa map) thì reset về map đầu.
        local stillExists = false
        for _, v in ipairs(values) do
            if v == SelectedMap then
                stillExists = true
                break
            end
        end
        if not stillExists and values[1] then
            SelectedMap = values[1]
            -- Đồng bộ lại giá trị hiển thị khi map cũ không còn trong danh sách.
            MapDropdown:SetValue(SelectedMap)
        end
    end
    return values
end

-- Khởi tạo dropdown lần đầu bằng danh sách map đang có trong workspace.
local initialMaps = getAvailableMapNumbers()
SelectedMap = initialMaps[1]

MapDropdown = TeleportGroup:AddDropdown("MapDropdown", {
    Values = initialMaps,
    Default = 1,
    Multi = false,
    Text = "Chọn Map",
    MaxVisibleDropdownItems = 17,
    Searchable = true,
    Tooltip = "Teleport tới BrainrotSpawns[\"X\"] — số đầu tiên trong path.",
    Callback = function(value)
        SelectedMap = value
    end,
})

-- Loop refresh 5s để cập nhật khi game thêm map mới (giống BaseDropdown).
task.spawn(function()
    while not Config.Unloaded and task.wait(5) do
        refreshMapDropdownValues()
    end
end)

-- Nút teleport tới spawn của map đã chọn.
TeleportGroup:AddButton({
    Text = "Teleport to Map",
    Func = function()
        local part = getSpawnByMapNumber(SelectedMap)
        if not part then
            Library:Notify({
                Title = "Teleport",
                Description = "Không tìm thấy BrainrotSpawns[\"" .. tostring(SelectedMap) .. "\"].",
                Time = 4,
            })
            return
        end

        local ok, err = teleportToPart(part)
        Library:Notify({
            Title = "Teleport",
            Description = ok and ("Đã teleport tới map " .. tostring(SelectedMap) .. ".") or err,
            Time = 3,
        })
    end,
    Tooltip = "Teleport player tới map đang chọn trong dropdown.",
})

-- Nút teleport về FinishLine (chỉ có 1 FinishLine duy nhất trong GameplayZones[\"1\"]).
TeleportGroup:AddButton({
    Text = "Back to Line",
    Func = function()
        local part = getFinishLinePart()
        if not part then
            Library:Notify({
                Title = "Teleport",
                Description = "Không tìm thấy GameplayZones[\"1\"].FinishLine.",
                Time = 4,
            })
            return
        end

        local ok, err = teleportToPart(part)
        Library:Notify({
            Title = "Teleport",
            Description = ok and "Đã teleport về FinishLine." or err,
            Time = 3,
        })
    end,
    Tooltip = "Teleport về GameplayZones[\"1\"].FinishLine.",
})

TeleportInfoGroup:AddLabel("1. Chọn map trong dropdown.", true)
TeleportInfoGroup:AddLabel("2. Bấm Teleport to Map để bay tới spawn.", true)
TeleportInfoGroup:AddLabel("3. Bấm Back to Line để quay lại FinishLine.", true)

-- Hiển thị hướng dẫn ngắn trong UI.
InfoGroup:AddLabel("1. Chọn 'Auto' để tự phát hiện base theo tên nhân vật.", true)
InfoGroup:AddLabel("2. Hoặc chọn Base cụ thể trong dropdown Chọn Base.", true)
InfoGroup:AddLabel("3. Bấm Collect All Floors hoặc bật Auto Collect.", true)

local BrainrotBoardGroup = Tabs.Brainrot:AddLeftGroupbox("Brainrot List", "list")
local BrainrotCollectGroup = Tabs.Brainrot:AddRightGroupbox("Collect Brainrot", "hand")
local BrainrotNameMap = {}
local BrainrotListLabels = {}
local TopBrainrotESPObjects = {}
local LastBrainrotDropdownRefresh = 0
local LastTopBrainrotESPRefresh = 0

-- Xoá toàn bộ object ESP top brainrot để tránh bị chồng Billboard/Highlight.
local function clearTopBrainrotESP()
    -- Destroy từng object ESP đã tạo trước đó.
    for _, object in ipairs(TopBrainrotESPObjects) do
        if object and object.Parent then
            object:Destroy()
        end
    end
    TopBrainrotESPObjects = {}
end

-- Tìm BasePart để gắn BillboardGui vào brainrot model/folder.
local function getBrainrotESPAdornee(brainrot)
    -- Nếu bản thân brainrot là BasePart thì gắn trực tiếp.
    if brainrot:IsA("BasePart") then
        return brainrot
    end
    -- Ưu tiên HumanoidRootPart/Root nếu có, sau đó lấy BasePart bất kỳ.
    return brainrot:FindFirstChild("HumanoidRootPart", true)
        or brainrot:FindFirstChild("Root", true)
        or brainrot:FindFirstChildWhichIsA("BasePart", true)
end

-- Tạo ESP cho top 5 brainrot income cao nhất, chỉ lấy con có timer.
local function refreshTopBrainrotESP(brainrots)
    if not Config.TopBrainrotESP then return end

    local now = os.clock()
    -- Throttle ESP vì việc Destroy/Create Billboard + Highlight liên tục khá nặng.
    if now - LastTopBrainrotESPRefresh < Config.TopBrainrotESPRefreshDelay then
        return
    end
    LastTopBrainrotESPRefresh = now

    -- Luôn clear trước khi rebuild ESP để phản ánh đúng top mới nhất.
    clearTopBrainrotESP()

    -- Lọc riêng ESP: bỏ qua brainrot No timer, nhưng không ảnh hưởng Brainrot List.
    local espBrainrots = {}
    for _, brainrot in ipairs(brainrots) do
        if brainrot.HasTimer then
            table.insert(espBrainrots, brainrot)
            if #espBrainrots >= 5 then
                break
            end
        end
    end

    -- Màu theo rank để nhìn nhanh top 1-5.
    local rankColors = {
        Color3.fromRGB(255, 215, 0),
        Color3.fromRGB(180, 220, 255),
        Color3.fromRGB(255, 170, 80),
        Color3.fromRGB(140, 255, 140),
        Color3.fromRGB(255, 120, 220),
    }

    for rank, brainrot in ipairs(espBrainrots) do
        if not brainrot.Instance or not brainrot.Instance.Parent then
            continue
        end

        local adornee = getBrainrotESPAdornee(brainrot.Instance)
        if not adornee then
            continue
        end

        local color = rankColors[rank] or Color3.fromRGB(255, 255, 255)
        -- Highlight chỉ adorn Model/BasePart; nếu brainrot là Folder thì adorn BasePart tìm được.
        local highlightAdornee = (brainrot.Instance:IsA("Model") or brainrot.Instance:IsA("BasePart")) and brainrot.Instance or adornee

        -- Highlight tạo viền sáng quanh model/part.
        local highlight = Instance.new("Highlight")
        highlight.Name = "WiniFyTopBrainrotESPHighlight"
        highlight.Adornee = highlightAdornee
        highlight.FillTransparency = 0.75
        highlight.OutlineTransparency = 0
        highlight.FillColor = color
        highlight.OutlineColor = color
        highlight.Parent = brainrot.Instance
        table.insert(TopBrainrotESPObjects, highlight)

        -- BillboardGui hiển thị rank, tên, income, timer.
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "WiniFyTopBrainrotESPBillboard"
        billboard.Adornee = adornee
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(0, 230, 0, 54)
        billboard.StudsOffset = Vector3.new(0, 4, 0)
        billboard.Parent = adornee
        table.insert(TopBrainrotESPObjects, billboard)

        -- TextLabel trong BillboardGui để hiển thị thông tin top brainrot.
        local label = Instance.new("TextLabel")
        label.Name = "Info"
        label.BackgroundTransparency = 0.25
        label.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        label.BorderSizePixel = 0
        label.Size = UDim2.new(1, 0, 1, 0)
        label.Font = Enum.Font.GothamBold
        label.TextScaled = true
        label.TextColor3 = color
        label.TextStrokeTransparency = 0
        label.Text = "#" .. rank .. " " .. brainrot.Name .. "\n" .. brainrot.Income .. " | " .. brainrot.Time
        label.Parent = billboard
    end
end

-- Cập nhật danh sách Brainrot theo DisplayName và sắp xếp con nhiều tiền nhất lên đầu.
-- lightRefresh = true: update label nhanh, nhưng throttle dropdown để giảm lag.
local function refreshBrainrotBoard(keepSelected, lightRefresh)
    -- Brainrot List hiển thị cả con không có timer; Collect Best tự lọc riêng.
    local brainrots = getAllBrainrots(true)
    BrainrotNameMap = {}

    local dropdownValues = {}
    for index, brainrot in ipairs(brainrots) do
        local displayText = brainrot.Name
        if BrainrotNameMap[displayText] then
            displayText = brainrot.Name .. " #" .. tostring(index)
        end

        BrainrotNameMap[displayText] = brainrot
        table.insert(dropdownValues, displayText)
    end

    if #dropdownValues == 0 then
        dropdownValues = { "Không có Brainrot" }
    end

    local now = os.clock()
    local shouldUpdateDropdown = (not lightRefresh) or (now - LastBrainrotDropdownRefresh >= Config.BrainrotDropdownRefreshDelay)

    -- Dropdown rebuild khá nặng, nên light refresh chỉ update mỗi 1s.
    if shouldUpdateDropdown and Options.BrainrotDropdown then
        LastBrainrotDropdownRefresh = now
        Options.BrainrotDropdown:SetValues(dropdownValues)
        if not keepSelected then
            Options.BrainrotDropdown:SetValue(dropdownValues[1])
        end
    end

    for index = 1, 10 do
        local brainrot = brainrots[index]
        local labelObject = BrainrotListLabels[index]

        if labelObject then
            if brainrot then
                labelObject:SetText(index .. ". " .. brainrot.Name .. " | " .. brainrot.Income .. " | " .. brainrot.Time)
            else
                labelObject:SetText(index .. ".")
            end
        end
    end

    -- ESP Top 5 dùng danh sách này nhưng tự bỏ qua brainrot No timer.
    refreshTopBrainrotESP(brainrots)

    return brainrots
end

-- Tạo bảng hiển thị nhanh 10 Brainrot mạnh nhất theo DisplayName.
for index = 1, 10 do
    -- AddLabel trả về TextLabel, lưu lại để update .Text khi refresh.
    BrainrotListLabels[index] = BrainrotBoardGroup:AddLabel(index .. ". Chưa quét dữ liệu", {
        Text = index .. ". Chưa quét dữ liệu",
        DoesWrap = true,
    })
end

BrainrotBoardGroup:AddButton({
    Text = "Refresh Brainrots",
    Func = function()
        refreshBrainrotBoard()
        Library:Notify({
            Title = "Brainrot ESP",
            Description = "Đã quét toàn bộ BrainrotContainer.",
            Time = 3,
        })
    end,
    Tooltip = "Quét lại toàn bộ workspace.Camera.BrainrotContainer.",
})

-- Toggle ESP Top 5: tạo Billboard + Highlight cho 5 brainrot income cao nhất.
BrainrotBoardGroup:AddToggle("TopBrainrotESPToggle", {
    Text = "ESP Top 5 Income",
    Default = Config.TopBrainrotESP,
    Tooltip = "Hiển thị Billboard + Highlight cho top 5 brainrot income cao nhất.",
    Callback = function(value)
        Config.TopBrainrotESP = value
        -- Nếu tắt ESP thì xoá ngay Billboard/Highlight đang tồn tại.
        if not value then
            clearTopBrainrotESP()
        else
            -- Reset throttle để ESP hiện ngay khi bật toggle.
            LastTopBrainrotESPRefresh = 0
            refreshBrainrotBoard(true)
        end
    end,
})

BrainrotCollectGroup:AddDropdown("BrainrotDropdown", {
    Values = { "Không có Brainrot" },
    Default = 1,
    Multi = false,
    Text = "Chọn Brainrot",
    Searchable = true,
    Tooltip = "Danh sách hiển thị theo DisplayName.",
})

BrainrotCollectGroup:AddButton({
    Text = "Collect Selected Brainrot",
    Func = function()
        local selectedName = Options.BrainrotDropdown and Options.BrainrotDropdown.Value
        refreshBrainrotBoard(true)
        local brainrot = selectedName and BrainrotNameMap[selectedName]
        local success = brainrot and collectBrainrot(brainrot.Instance)

        Library:Notify({
            Title = "Brainrot ESP",
            Description = success and ("Đã collect: " .. brainrot.Name) or "Không tìm thấy ProximityPrompt để collect.",
            Time = 3,
        })
    end,
    Tooltip = "Collect Brainrot đang chọn trong dropdown.",
})

BrainrotCollectGroup:AddButton({
    Text = "Collect Best",
    Func = function()
        refreshBrainrotBoard()
        -- Collect Best chỉ lấy brainrot có timer để tránh collect con vĩnh viễn.
        local brainrots = getAllBrainrots(false)
        local bestBrainrot = brainrots[1]
        if not bestBrainrot then
            Library:Notify({
                Title = "Brainrot ESP",
                Description = "Không có Brainrot nào có timer biến mất để collect.",
                Time = 3,
            })
            return
        end

        local success = collectBrainrot(bestBrainrot.Instance)
        Library:Notify({
            Title = "Brainrot ESP",
            Description = success and ("Đã collect con mạnh nhất: " .. bestBrainrot.Name .. " (" .. bestBrainrot.Income .. ")")
                or "Không tìm thấy ProximityPrompt để collect.",
            Time = 3,
        })
    end,
    Tooltip = "Collect Brainrot có Income cao nhất (đã bỏ qua con không có timer biến mất).",
})

-- Điều kiện income tối thiểu để auto collect.
-- Dùng Input text để user nhập cả số lẫn hậu tố K/M/B/T... (parseIncomeValue sẽ lo phần còn lại).
BrainrotCollectGroup:AddInput("MinIncomeInput", {
    Default = "0",
    Numeric = false,
    Text = "Min Income",
    Placeholder = "vd: 1M, 500K, 1.5B",
    Tooltip = "Chỉ collect Brainrot có Income >= giá trị này. Có thể dùng hậu tố K, M, B, T, Qa, Qd...",
})

-- Bật/tắt auto collect có điều kiện: chỉ collect khi Brainrot đạt Min Income.
BrainrotCollectGroup:AddToggle("AutoCollectBestToggle", {
    Text = "Auto Collect (>= Min Income)",
    Default = false,
    Tooltip = "Tự động collect Brainrot có timer còn lại VÀ income >= Min Income.",
    Callback = function(value)
        Config.AutoCollectBest = value
        if value then
            Library:Notify({
                Title = "Brainrot ESP",
                Description = "Đã bật Auto Collect theo điều kiện Min Income.",
                Time = 3,
            })
        end
    end,
})

-- Vòng lặp auto collect: scan → filter timer (đã có sẵn trong getAllBrainrots)
-- → check IncomeValue >= minIncomeValue → collect 1 con / lượt.
task.spawn(function()
    while not Config.Unloaded and task.wait(Config.CollectDelay or 0.3) do
        if Config.AutoCollectBest then
            pcall(function()
                -- Auto collect chỉ scan brainrot có timer để tránh collect con vĩnh viễn.
                local brainrots = getAllBrainrots(false)
                local minIncomeText = (Options.MinIncomeInput and Options.MinIncomeInput.Value) or "0"
                local minIncomeValue = parseIncomeValue(minIncomeText)

                for _, br in ipairs(brainrots) do
                    if br.IncomeValue >= minIncomeValue then
                        local success = collectBrainrot(br.Instance)
                        if success then
                            Library:Notify({
                                Title = "Auto Collect",
                                Description = "Đã collect " .. br.Name .. " (" .. br.Income .. ") thoả Min Income.",
                                Time = 3,
                            })
                        end
                        break -- Mỗi lượt chỉ collect 1 con để tránh spam.
                    end
                end
            end)
        end
    end
end)

refreshBrainrotBoard()

-- Tự động refresh nhanh để cập nhật Brainrot mới và time còn lại.
task.spawn(function()
    while not Config.Unloaded and task.wait(Config.BrainrotRefreshDelay) do
        if Library and not Config.Unloaded then
            -- Light refresh: labels nhanh, dropdown/ESP được throttle để giảm lag.
            pcall(function()
                refreshBrainrotBoard(true, true)
            end)
        end
    end
end)

-- ============ TAB MISC ============
-- Tab Misc gom các tuỳ chỉnh nhân vật: tốc độ, nhảy, khoảng cách camera, inf jump, fly, noclip.
local PlayerModsGroup = Tabs.Misc:AddLeftGroupbox("Player", "user")

-- Slider WalkSpeed để đổi tốc độ chạy (16 -> 500). Chỉ áp dụng sau khi anh kéo slider.
PlayerModsGroup:AddSlider("WalkSpeedSlider", {
    Text = "Walk Speed",
    Default = Config.WalkSpeed,
    Min = 16,
    Max = 500,
    Rounding = 0,
    Compact = false,
}):OnChanged(function()
    Config.WalkSpeed = Options.WalkSpeedSlider.Value
    -- Đánh dấu đã chỉnh speed để script không tự set speed ngay lúc mới load.
    Config.WalkSpeedActive = true
end)

-- Slider JumpPower để đổi lực nhảy (50 -> 500). Chỉ áp dụng sau khi anh kéo slider.
PlayerModsGroup:AddSlider("JumpPowerSlider", {
    Text = "Jump Power",
    Default = Config.JumpPower,
    Min = 50,
    Max = 500,
    Rounding = 0,
    Compact = false,
}):OnChanged(function()
    Config.JumpPower = Options.JumpPowerSlider.Value
    -- Đánh dấu đã chỉnh jump power để script không tự set jump ngay lúc mới load.
    Config.JumpPowerActive = true
end)

-- Slider MaxCamDistance điều chỉnh khoảng cách camera (10 -> 200).
-- Áp dụng bằng cách set Min/Max ZoomDistance của Player.
PlayerModsGroup:AddSlider("MaxCamDistanceSlider", {
    Text = "Max Cam Distance",
    Default = Config.MaxCamDistance,
    Min = 10,
    Max = 200,
    Rounding = 0,
    Compact = false,
}):OnChanged(function()
    Config.MaxCamDistance = Options.MaxCamDistanceSlider.Value
end)

local MovementGroup = Tabs.Misc:AddRightGroupbox("Movement", "rocket")

-- Toggle Inf Jump: bật thì nhảy vô hạn (UserInputService.JumpRequest).
MovementGroup:AddToggle("InfJumpToggle", {
    Text = "Inf Jump",
    Default = Config.InfJump,
    Tooltip = "Cho phép nhảy nhiều lần liên tục trên không.",
}):OnChanged(function()
    Config.InfJump = Toggles.InfJumpToggle.Value
end)

-- Toggle Fly: bật thì bay tự do bằng BodyVelocity + BodyGyro.
MovementGroup:AddToggle("FlyToggle", {
    Text = "Fly",
    Default = Config.FlyEnabled,
    Tooltip = "Bay tự do. Cần bật thêm Fly Speed bên dưới.",
}):OnChanged(function()
    Config.FlyEnabled = Toggles.FlyToggle.Value
end)

-- Slider Fly Speed để chỉnh tốc độ bay (10 -> 300).
MovementGroup:AddSlider("FlySpeedSlider", {
    Text = "Fly Speed",
    Default = Config.FlySpeed,
    Min = 10,
    Max = 300,
    Rounding = 0,
    Compact = false,
}):OnChanged(function()
    Config.FlySpeed = Options.FlySpeedSlider.Value
end)

-- Toggle Noclip: dùng logic lấy từ Infinite Yield (RunService.Stepped + PhysicsDisabled).
MovementGroup:AddToggle("NoclipToggle", {
    Text = "Noclip",
    Default = Config.NoclipEnabled,
    Tooltip = "Đi xuyên tường vật thể.",
}):OnChanged(function()
    -- Gọi hàm setNoclipState để bật/tắt loop Stepped.
    setNoclipState(Toggles.NoclipToggle.Value)
end)

-- ============ GROUPBOX EXTERNAL SCRIPTS ============
-- Groupbox chứa các nút gọi script bên ngoài (Infinite Yield, ...).
local ExternalGroup = Tabs.Misc:AddLeftGroupbox("External Scripts", "download")

-- Nút Load Infinite Yield: gọi script admin Infinite Yield từ GitHub EdgeIY/infiniteyield.
-- Bọc trong pcall để nếu mạng/HTTP lỗi thì chỉ thông báo, không crash script chính.
ExternalGroup:AddButton({
    Text = "Load Infinite Yield",
    Func = function()
        -- Báo đang load cho user biết.
        Library:Notify({
            Title = "Infinite Yield",
            Description = "Đang tải Infinite Yield...",
            Time = 2,
        })
        -- Thử gọi loadstring HTTPGet để chạy script Infinite Yield.
        local ok, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
        end)
        -- Nếu lỗi thì báo lỗi để user biết.
        if not ok then
            Library:Notify({
                Title = "Infinite Yield",
                Description = "Lỗi khi tải script: " .. tostring(err),
                Time = 5,
            })
        end
    end,
    Tooltip = "Gọi script admin Infinite Yield (EdgeIY/infiniteyield).",
})

-- ============ LOGIC MISC ============
-- Biến lưu trữ các đối tượng BodyVelocity/BodyGyro dùng cho Fly.
local flyBodyVelocity = nil
local flyBodyGyro = nil

-- Hàm tiện ích: lấy Humanoid và RootPart hiện tại của nhân vật.
local function getHumanoidAndRoot()
    -- Nếu chưa có character thì trả về nil.
    local character = Players.LocalPlayer and Players.LocalPlayer.Character
    if not character then return nil, nil end
    -- Lấy Humanoid để chỉnh WalkSpeed/JumpPower và ChangeState cho Inf Jump.
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    -- Lấy HumanoidRootPart để gắn BodyVelocity/BodyGyro cho Fly.
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    return humanoid, rootPart
end

-- Hàm áp dụng WalkSpeed, JumpPower và MaxCamDistance vào nhân vật và Player.
local function applyPlayerMods()
    local humanoid = Players.LocalPlayer and Players.LocalPlayer.Character
        and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    -- Nếu chưa có humanoid thì bỏ qua.
    if humanoid then
        -- Chỉ set WalkSpeed sau khi anh đã kéo slider, tránh đổi speed ngay lúc load script.
        if Config.WalkSpeedActive then
            humanoid.WalkSpeed = Config.WalkSpeed
        end
        -- Chỉ set JumpPower sau khi anh đã kéo slider, tránh đổi jump ngay lúc load script.
        if Config.JumpPowerActive then
            -- UseJumpPower để dùng JumpPower thay vì JumpHeight (Roblox đời mới).
            humanoid.UseJumpPower = true
            humanoid.JumpPower = Config.JumpPower
        end
    end
    -- Chỉ set MaxZoomDistance để đúng nghĩa Max Cam Distance, không khoá zoom gần.
    Players.LocalPlayer.CameraMaxZoomDistance = Config.MaxCamDistance
end

-- Hàm bật/tắt Fly: tạo BodyVelocity + BodyGyro trên HumanoidRootPart.
local function setFlyState(enabled)
    local humanoid, rootPart = getHumanoidAndRoot()
    -- Nếu không đủ thông tin thì không làm gì.
    if not humanoid or not rootPart then return end
    -- Nếu tắt Fly thì destroy BodyVelocity/BodyGyro và trả về trạng thái ground.
    if not enabled then
        if flyBodyVelocity then flyBodyVelocity:Destroy(); flyBodyVelocity = nil end
        if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
        -- Trả Humanoid về trạng thái đứng trên mặt đất.
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
        return
    end
    -- Nếu bật Fly mà chưa tạo BodyVelocity/BodyGyro thì tạo mới.
    if not flyBodyVelocity then
        -- BodyVelocity để điều khiển vận tốc bay theo FlySpeed.
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        flyBodyVelocity.Parent = rootPart
    end
    if not flyBodyGyro then
        -- BodyGyro để giữ hướng nhìn khi bay (tránh xoay lung tung).
        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        flyBodyGyro.P = 9e4
        flyBodyGyro.D = 500
        flyBodyGyro.Parent = rootPart
    end
end

-- Hàm xử lý di chuyển khi đang Fly: dựa theo phím WASD + Space/Shift để bay lên/xuống.
local function updateFlyMovement()
    -- Nếu không có BodyVelocity hoặc nhân vật thì bỏ qua.
    if not flyBodyVelocity or not flyBodyGyro then return end
    local _, rootPart = getHumanoidAndRoot()
    if not rootPart then return end
    -- Lấy camera và humanoid để xác định hướng bay theo góc nhìn.
    local camera = workspace.CurrentCamera
    local humanoid = Players.LocalPlayer and Players.LocalPlayer.Character
        and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not camera or not humanoid then return end

    -- Hướng bay mặc định là vector 0.
    local moveDirection = Vector3.new(0, 0, 0)
    -- Hướng phẳng của camera (bỏ trục Y để không bay chéo lên/xuống khi đi W/S).
    local cameraCF = camera.CFrame
    local forward = Vector3.new(cameraCF.LookVector.X, 0, cameraCF.LookVector.Z)
    if forward.Magnitude > 0 then forward = forward.Unit end
    local right = Vector3.new(cameraCF.RightVector.X, 0, cameraCF.RightVector.Z)
    if right.Magnitude > 0 then right = right.Unit end

    -- W -> tới, S -> lùi, A -> trái, D -> phải.
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        moveDirection = moveDirection + forward
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        moveDirection = moveDirection - forward
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        moveDirection = moveDirection - right
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        moveDirection = moveDirection + right
    end
    -- Space -> bay lên, Shift Left -> bay xuống.
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        moveDirection = moveDirection + Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        moveDirection = moveDirection - Vector3.new(0, 1, 0)
    end

    -- Nếu có di chuyển thì nhân vận tốc theo FlySpeed, ngược lại đứng yên.
    if moveDirection.Magnitude > 0 then
        flyBodyVelocity.Velocity = moveDirection.Unit * Config.FlySpeed
    else
        flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    end
    -- BodyGyro xoay theo camera để đầu nhân vật cùng hướng bay.
    flyBodyGyro.CFrame = cameraCF
end

-- ============ NOCLIP (logic lấy từ Infinite Yield) ============
-- Lưu connection Stepped để tự huỷ khi tắt noclip hoặc unload script.
local noclipConnection = nil

-- Hàm bật loop Stepped cho noclip (chỉ tạo 1 connection duy nhất).
local function startNoclipLoop()
    -- Nếu đã có connection thì không tạo thêm để tránh chồng loop.
    if noclipConnection then return end
    -- Dùng RunService.Stepped (chạy TRƯỚC physics step) để chắc chắn part
    -- không kịp va chạm — đây là cách Infinite Yield làm để noclip mượt.
    noclipConnection = RunService.Stepped:Connect(function()
        -- Nếu user tắt noclip từ chỗ khác thì tự huỷ connection.
        if not Config.NoclipEnabled then
            if noclipConnection then
                noclipConnection:Disconnect()
                noclipConnection = nil
            end
            return
        end
        -- Nếu đã unload thì cũng tự huỷ.
        if Config.Unloaded then
            if noclipConnection then
                noclipConnection:Disconnect()
                noclipConnection = nil
            end
            return
        end
        local character = Players.LocalPlayer and Players.LocalPlayer.Character
        if not character then return end
        -- Set CanCollide = false cho mọi BasePart trong character (giống IY).
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
        -- Đổi state Humanoid sang PhysicsDisabled (state 11) để tắt physics hoàn toàn
        -- -> nhân vật không bị rơi/va chạm khi đi xuyên tường.
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.PhysicsDisabled)
        end
    end)
end

-- Hàm bật/tắt noclip: bật thì chạy loop Stepped, tắt thì huỷ loop và restore Humanoid.
function setNoclipState(enabled)
    Config.NoclipEnabled = enabled
    if enabled then
        -- Bật noclip -> chạy loop Stepped.
        startNoclipLoop()
    else
        -- Tắt noclip -> huỷ loop.
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        -- Restore Humanoid về trạng thái chạy bình thường.
        local character = Players.LocalPlayer and Players.LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end
        end
    end
end

-- Kết nối UserInputService.JumpRequest để bật Inf Jump.
-- Khi người chơi nhấn phím nhảy, ép Humanoid về trạng thái Jumping.
UserInputService.JumpRequest:Connect(function()
    if Config.InfJump then
        local humanoid = Players.LocalPlayer and Players.LocalPlayer.Character
            and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        -- Nếu có humanoid và đang rảnh (không FreeFalling) thì ép nhảy.
        if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Khi respawn, áp dụng lại PlayerMods, Fly và Noclip cho nhân vật mới.
Players.LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    -- Đợi Humanoid và HumanoidRootPart load xong.
    local humanoid = newCharacter:WaitForChild("Humanoid", 5)
    local rootPart = newCharacter:WaitForChild("HumanoidRootPart", 5)
    if humanoid then
        -- Reset các BodyVelocity/BodyGyro cũ (nếu có) vì đã destroy khi respawn.
        flyBodyVelocity = nil
        flyBodyGyro = nil
        -- Reset connection noclip cũ (nếu có) để tạo lại cho character mới.
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        -- Áp dụng lại WalkSpeed/JumpPower cho character mới.
        task.defer(function()
            applyPlayerMods()
            -- Nếu đang bật Fly thì bật lại cho character mới.
            if Config.FlyEnabled then
                setFlyState(true)
            end
            -- Nếu đang bật Noclip thì bật lại loop Stepped cho character mới.
            if Config.NoclipEnabled then
                startNoclipLoop()
            end
        end)
    end
end)

-- Loop chính cho Misc: mỗi frame áp dụng PlayerMods và Fly movement.
-- Noclip dùng Stepped riêng (xem startNoclipLoop) — đúng kiểu Infinite Yield.
RunService.RenderStepped:Connect(function()
    -- Nếu đã unload script thì dừng loop.
    if Config.Unloaded then return end
    -- Áp dụng WalkSpeed/JumpPower/MaxCamDistance mỗi frame để chắc chắn luôn đúng.
    applyPlayerMods()
    -- Nếu bật Fly thì cập nhật vận tốc bay theo phím bấm.
    if Config.FlyEnabled then
        updateFlyMovement()
    else
        -- Nếu tắt Fly nhưng BodyVelocity/BodyGyro còn sót thì destroy.
        if flyBodyVelocity or flyBodyGyro then
            setFlyState(false)
        end
    end
end)

-- Cài tab theme/settings mặc định của Obsidian.
local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu", "menu")

-- Phím RightShift dùng để đóng/mở menu nhanh.
MenuGroup:AddLabel("Menu bind")
    :AddKeyPicker("MenuKeybind", {
        Default = "RightShift",
        NoUI = true,
        Text = "Menu keybind",
    })

-- Nút unload để dừng auto collect và gỡ UI khỏi màn hình.
MenuGroup:AddButton({
    Text = "Unload Script",
    Func = function()
        Config.AutoCollect = false
        Config.AutoEquip = false
        Config.Unloaded = true
        -- Tắt noclip để disconnect connection Stepped và restore Humanoid.
        if Config.NoclipEnabled then
            setNoclipState(false)
        end
        -- Tắt fly để destroy BodyVelocity/BodyGyro còn sót.
        if Config.FlyEnabled then
            setFlyState(false)
        end
        -- Xoá ESP Top 5 trước khi unload UI.
        clearTopBrainrotESP()
        BrainrotNameMap = {}
        Library:Unload()
    end,
    Tooltip = "Tắt auto collect và unload Obsidian UI.",
})

Library.ToggleKeybind = Options.MenuKeybind
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("LuckyBlock")
SaveManager:SetFolder("LuckyBlock/configs")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
