--// Zombie + Chest ESP + Hitbox + Teleport Collector
-- Load Fluent UI (working library)
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Zombie Hyperloot",
    SubTitle = "by WiniFy",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local entityFolder = Workspace:WaitForChild("Entity")
local fxFolder = Workspace:WaitForChild("FX")
local mapModel = Workspace:WaitForChild("Map")

-- Cấu hình esp
local hitboxSize = Vector3.new(4, 4, 4)
local espColorZombie = Color3.fromRGB(255, 100, 100) -- Màu đỏ nhạt cho zombie
local espColorChest = Color3.fromRGB(255, 255, 0) -- Màu vàng cho chest
local espColorPlayer = Color3.fromRGB(100, 200, 255) -- Màu xanh dương cho player
local espColorEnemy = Color3.fromRGB(255, 50, 50) -- Màu đỏ cho enemy
local teleportKey = Enum.KeyCode.T -- ấn T để tự mở toàn bộ chest

-- Toggle states
local espZombieEnabled = true
local espChestEnabled = true
local espPlayerEnabled = true -- ESP Player
local hitboxEnabled = true

-- ESP Player Configuration
local espPlayerBoxes = true
local espPlayerTracers = true
local espPlayerNames = true
local espPlayerHealth = true
local espPlayerTeamCheck = false -- Kiểm tra team
local teleportEnabled = true
local cameraTeleportEnabled = true
local teleportToLastZombie = false -- Teleport tới zombie cuối cùng hay không
local cameraTeleportKey = Enum.KeyCode.X -- ấn X để tele camera tới zombie
local cameraTeleportActive = false -- Biến kiểm tra đang chạy camera teleport loop
local cameraTeleportStartPosition = nil -- Vị trí ban đầu của nhân vật
local cameraOffsetX = 0 -- Camera offset X
local cameraOffsetY = 10 -- Camera offset Y
local cameraOffsetZ = -2 -- Camera offset Z
local hipHeightToggleKey = Enum.KeyCode.M -- ấn M để bật/tắt Anti-Zombie nhanh
local autoBulletBoxEnabled = true -- Kéo BulletBox về vị trí người chơi
local cameraTargetMode = "Nearest" -- Mode chọn mục tiêu camera: "LowestHealth" hoặc "Nearest"
local autoSkillEnabled = true -- Bật/tắt auto skill loop
local noClipEnabled = false -- Bật/tắt NoClip
local speedEnabled = false -- Bật/tắt Speed
local speedValue = 20 -- Giá trị speed mặc định
local skill1010Interval = 15 -- Thời gian giữa các lần dùng skill 1010 (giây)
local skill1002Interval = 20 -- Thời gian giữa các lần dùng skill 1002 (giây)

-- Aimbot Configuration
local aimbotEnabled = true
local aimbotHoldMouse2 = true -- Giữ chuột phải để aim
local aimbotSmoothness = 0.15 -- Mức độ mượt (0 = instantly, 1 = very slow)
local aimbotPrediction = 0.05 -- Dự đoán chuyển động
local aimbotFOVEnabled = true
local aimbotFOVRadius = 200
local aimbotTargetMode = "Zombies" -- Zombies, Players, All
local aimbotAimPart = "Head" -- Head, UpperTorso, HumanoidRootPart

-- Anti-Zombie Configuration (HipHeight)
local antiZombieEnabled = false -- Bật/tắt Anti-Zombie (tăng HipHeight)
local hipHeightValue = 20 -- Giá trị HipHeight mặc định (studs)
local originalHipHeight = nil -- Lưu HipHeight gốc để khôi phục


----------------------------------------------------------
-- 🔹 Anti-Zombie Functions - Duy trì HipHeight nhưng vẫn cho phép di chuyển
local humanoidHipHeightConnection = nil
local noClipConnection = nil
local originalCollidableParts = {}

local function disconnectHipHeightListener()
	if humanoidHipHeightConnection then
		humanoidHipHeightConnection:Disconnect()
		humanoidHipHeightConnection = nil
	end
end

local function restoreOriginalCollisions()
	for part in pairs(originalCollidableParts) do
		if part and part.Parent then
			part.CanCollide = true
		end
		originalCollidableParts[part] = nil
	end
end

local function disableNoClip()
	if noClipConnection then
		noClipConnection:Disconnect()
		noClipConnection = nil
	end
	restoreOriginalCollisions()
end

local function enableNoClip()
	disableNoClip()
	noClipConnection = RunService.Stepped:Connect(function()
		local char = localPlayer.Character
		if not char then return end
		for _, descendant in ipairs(char:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant.CanCollide then
				originalCollidableParts[descendant] = true
				descendant.CanCollide = false
			end
		end
	end)
end

local function enforceHipHeight(humanoid)
	if not humanoid or not humanoid.Parent then return end
	local desired = math.max(0, tonumber(hipHeightValue) or 20)
	humanoid.HipHeight = desired
end

local function disableAntiZombie()
	disconnectHipHeightListener()
	disableNoClip()
	local char = localPlayer.Character
	local humanoid = char and char:FindFirstChild("Humanoid")
	if humanoid and originalHipHeight ~= nil then
		humanoid.HipHeight = originalHipHeight
	end
	originalHipHeight = nil
end

local function applyAntiZombie()
	local char = localPlayer.Character
	local humanoid = char and char:FindFirstChild("Humanoid")
	if not char or not humanoid then
		disableAntiZombie()
		return
	end
	
	if antiZombieEnabled then
		if originalHipHeight == nil then
			originalHipHeight = humanoid.HipHeight
		end
		enforceHipHeight(humanoid)
		enableNoClip()
		disconnectHipHeightListener()
		humanoidHipHeightConnection = humanoid:GetPropertyChangedSignal("HipHeight"):Connect(function()
			if antiZombieEnabled then
				enforceHipHeight(humanoid)
			end
		end)
	else
		disableAntiZombie()
	end
end

-- Tự động áp dụng khi nhân vật spawn/respawn
local function onCharacterAdded(character)
	disconnectHipHeightListener()
	originalHipHeight = nil
	task.wait(0.5)
	applyAntiZombie()
end

if localPlayer.Character then
	onCharacterAdded(localPlayer.Character)
end

localPlayer.CharacterAdded:Connect(onCharacterAdded)

----------------------------------------------------------
-- 🔹 Hàm tạo ESP Billboard
local function createESP(part, color, name, zombie)
	if not part or part:FindFirstChild("ESPTag") then return end

	-- Tạo Highlight để làm nổi bật zombie
	local highlight = Instance.new("Highlight")
	highlight.Name = "ESP_Highlight"
	highlight.Adornee = part.Parent -- Áp dụng highlight cho toàn bộ zombie model
	highlight.FillColor = Color3.fromRGB(255, 100, 100) -- Màu đỏ nhạt
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255) -- Viền trắng
	highlight.FillTransparency = 0.7 -- Độ trong suốt của phần fill
	highlight.OutlineTransparency = 0 -- Viền không trong suốt
	highlight.Enabled = true
	highlight.Parent = part.Parent -- Gắn highlight vào model của zombie

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ESPTag"
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.new(0, 200, 0, 30) -- Chỉ cần kích thước cho máu
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.Parent = part

	-- Không tạo label tên nữa, chỉ hiển thị máu
	
	-- Thêm hiển thị máu cho zombie
	if zombie and zombie:FindFirstChild("Humanoid") then
		local humanoid = zombie.Humanoid
		local healthText = string.format("[%d/%d]", math.floor(humanoid.Health), math.floor(humanoid.MaxHealth))
		
		local healthLabel = Instance.new("TextLabel")
		healthLabel.Size = UDim2.new(1, 0, 0, 20)
		healthLabel.Position = UDim2.new(0, 0, 0, 0) -- Đặt ở vị trí đầu tiên
		healthLabel.BackgroundTransparency = 1
		healthLabel.Text = healthText
		healthLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- Màu trắng nổi bật
		healthLabel.TextStrokeTransparency = 0
		healthLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) -- Viền đen để nổi bật
		healthLabel.Font = Enum.Font.SourceSansBold
		healthLabel.TextSize = 16 -- Tăng kích thước chữ
		healthLabel.Parent = billboard
		
		-- Cập nhật máu theo thời gian thực
		task.spawn(function()
			while part and part.Parent and billboard and billboard.Parent do
				if humanoid and humanoid.Parent then
					local currentHealth = math.floor(humanoid.Health)
					local maxHealth = math.floor(humanoid.MaxHealth)
					healthText = string.format("[%d/%d]", currentHealth, maxHealth)
					healthLabel.Text = healthText
					
					-- Đổi màu theo mức máu với màu nổi bật
					if currentHealth <= maxHealth * 0.25 then
						healthLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- Đỏ đậm khi ít máu
						healthLabel.TextStrokeColor3 = Color3.fromRGB(255, 255, 255) -- Viền trắng
					elseif currentHealth <= maxHealth * 0.5 then
						healthLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- Vàng khi máu trung bình
						healthLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) -- Viền đen
					else
						healthLabel.TextColor3 = Color3.fromRGB(0, 255, 0) -- Xanh lá khi nhiều máu
						healthLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) -- Viền đen
					end
				else
					break
				end
				task.wait(0.1) -- Cập nhật mỗi 0.1 giây
			end
			
			-- Xóa highlight khi kết thúc
			if highlight and highlight.Parent then
				highlight:Destroy()
			end
		end)
	end
end

----------------------------------------------------------
-- 🔹 Mở rộng hitbox cho zombie (chỉ làm 1 lần)
local processedZombies = {} -- Lưu zombie đã xử lý

local function expandHitbox(zombie)
	-- Kiểm tra xem zombie đã được xử lý chưa
	if processedZombies[zombie] then return end
	
	-- Đợi model load xong các bộ phận chính
	local head = zombie:WaitForChild("Head", 4)
	if not head then return end
	
	if head:IsA("BasePart") then
		-- Lưu size gốc
		if not head:GetAttribute("OriginalSize") then
			head:SetAttribute("OriginalSizeX", head.Size.X)
			head:SetAttribute("OriginalSizeY", head.Size.Y)
			head:SetAttribute("OriginalSizeZ", head.Size.Z)
		end
		
		-- Chỉ set hitbox nếu đang bật
		if hitboxEnabled then
			head.Size = hitboxSize
			head.Transparency = 0.5
			head.Color = Color3.fromRGB(255, 0, 0)
			head.CanCollide = false
		end
		
		-- Đánh dấu đã xử lý
		processedZombies[zombie] = true
	end
end

-- Hàm khôi phục hitbox về bình thường
local function restoreHitbox(zombie)
	local head = zombie:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		-- Khôi phục size gốc
		local origX = head:GetAttribute("OriginalSizeX")
		local origY = head:GetAttribute("OriginalSizeY")
		local origZ = head:GetAttribute("OriginalSizeZ")
		
		if origX and origY and origZ then
			head.Size = Vector3.new(origX, origY, origZ)
			head.Transparency = 1
			head.CanCollide = true
		end
	end
end

----------------------------------------------------------
-- 🔹 ESP cho zombie mới sinh ra (đợi load hết)
entityFolder.ChildAdded:Connect(function(zombie)
	if zombie:IsA("Model") then
		-- Đợi zombie load đủ các bộ phận
		local head = zombie:WaitForChild("Head", 3)
		if head then
			task.wait(0.5) -- Đợi thêm một chút để model load xong hoàn toàn
			if espZombieEnabled then
				createESP(head, espColorZombie, zombie.Name, zombie)
			end
			if hitboxEnabled then
				expandHitbox(zombie)
			end
		end
	end
end)

entityFolder.ChildRemoved:Connect(function(zombie)
	processedZombies[zombie] = nil
	
	-- Xóa highlight nếu có
	local highlight = zombie:FindFirstChild("ESP_Highlight")
	if highlight then
		highlight:Destroy()
	end
end)

----------------------------------------------------------
-- 🔹 ESP cho chest (chính xác đường dẫn: Map.Model.Chest.Model.Chest)
local chestDescendantConnection = nil

local function forEachChestPart(callback)
	local map = Workspace:FindFirstChild("Map")
	if not map then return end
	
	-- Duyệt qua tất cả children của Map để tìm Chest folder
	for _, mapChild in ipairs(map:GetChildren()) do
		local chestFolder = mapChild:FindFirstChild("Chest")
		if chestFolder then
			-- Duyệt qua tất cả chest models
			for _, chestModel in ipairs(chestFolder:GetChildren()) do
				if chestModel:IsA("Model") and chestModel:FindFirstChild("Chest") then
					local chestModelFolder = chestModel.Chest
					
					-- Duyệt qua tất cả các loại chest (Common Chest, Rare Chest, Epic Chest, Legendary Chest, v.v.)
					for _, chestType in ipairs(chestModelFolder:GetChildren()) do
						if chestType:IsA("Model") then
							local chestPart = chestType:FindFirstChildWhichIsA("BasePart")
							if chestPart then
								callback(chestPart)
							end
						end
					end
				end
			end
		end
	end
end

local function applyChestESP()
	if not espChestEnabled then return end
	forEachChestPart(function(chestPart)
		if not chestPart:FindFirstChild("ESPTag") then
			createESP(chestPart, espColorChest, "Chest", nil)
		end
	end)
end

local function clearChestESP()
	forEachChestPart(function(chestPart)
		local tag = chestPart:FindFirstChild("ESPTag")
		if tag then
			tag:Destroy()
		end
	end)
end

local function watchChestDescendants()
	if chestDescendantConnection then
		chestDescendantConnection:Disconnect()
		chestDescendantConnection = nil
	end
	local map = Workspace:FindFirstChild("Map")
	if not map then return end
	
	-- Lắng nghe tất cả các chest folder trong Map
	local connections = {}
	for _, mapChild in ipairs(map:GetChildren()) do
		local chestFolder = mapChild:FindFirstChild("Chest")
		if chestFolder then
			local connection = chestFolder.DescendantAdded:Connect(function(desc)
				if espChestEnabled and desc:IsA("BasePart") then
					task.defer(applyChestESP)
				end
			end)
			table.insert(connections, connection)
		end
	end
	
	-- Lưu connections để có thể disconnect sau này
	chestDescendantConnection = {
		Disconnect = function()
			for _, conn in ipairs(connections) do
				conn:Disconnect()
			end
		end
	}
end

----------------------------------------------------------
-- 🔹 Hàm áp dụng/loại bỏ ESP hiện có
local function applyZombieESPToAll()
	if not espZombieEnabled then return end
	for _, zombie in ipairs(entityFolder:GetChildren()) do
		if zombie:IsA("Model") then
			local head = zombie:FindFirstChild("Head")
			if head then
				createESP(head, espColorZombie, zombie.Name, zombie)
			end
		end
	end
end

local function clearZombieESP()
	for _, zombie in ipairs(entityFolder:GetChildren()) do
		local head = zombie:FindFirstChild("Head")
		if head then
			local espTag = head:FindFirstChild("ESPTag")
			if espTag then
				espTag:Destroy()
			end
			
			-- Xóa highlight nếu có
			local highlight = zombie:FindFirstChild("ESP_Highlight")
			if highlight then
				highlight:Destroy()
			end
		end
	end
end

watchChestDescendants()
applyZombieESPToAll()
if espChestEnabled then
	applyChestESP()
end

----------------------------------------------------------
-- 🔹 Auto Teleport Chests (Press T)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == teleportKey and teleportEnabled then
		local char = localPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local oldPos = hrp.Position
		local virtualUser = game:GetService("VirtualUser")
		
		-- Bước 1: Tìm tất cả chest (tất cả các loại: Common Chest, Rare Chest, v.v.)
		local chests = {}
		
		-- Sử dụng function chung để tìm tất cả chest
		forEachChestPart(function(chestPart)
			table.insert(chests, chestPart)
		end)
		
		-- Bước 2: Teleport tới từng chest và mở
		for _, chestPart in ipairs(chests) do
			-- Teleport tới chest
			hrp.CFrame = CFrame.new(chestPart.Position + Vector3.new(0, 2, 0))
			task.wait(0.3)
			
			-- Tự động nhấn E để interact với chest
			virtualUser:CaptureController()
			virtualUser:ClickButton1(Vector2.new(0, 0))
			task.wait(0.1)
			
			-- Giả lập nhấn phím E
			game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game)
			task.wait(0.1)
			game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game)
			task.wait(0.2)
		end
		
		-- Quay về vị trí cũ
		hrp.CFrame = CFrame.new(oldPos)
	end
end)

----------------------------------------------------------
-- 🔹 Infinite Skill Loop
local function triggerSkill(skillId)
	local char = localPlayer.Character
	if not char then return end
	
	local tool = char:FindFirstChild("Tool")
	if not tool then return end
	
	local netMessage = char:FindFirstChild("NetMessage")
	if not netMessage then return end
	
	pcall(function()
		netMessage:WaitForChild("TrigerSkill"):FireServer(skillId, "Enter")
	end)
end

local function activateSkill1010()
	triggerSkill(1010)
end

local function activateSkill1002()
	triggerSkill(1002)
end

local function startSkillLoop(getInterval, action)
	task.spawn(function()
		if autoSkillEnabled then
			task.wait(1) -- Đợi nhân vật load ổn định
			action()
		end
		
		while task.wait(getInterval()) do
			if autoSkillEnabled then
				action()
			end
		end
	end)
end

startSkillLoop(function()
	return skill1010Interval
end, activateSkill1010)

startSkillLoop(function()
	return skill1002Interval
end, activateSkill1002)

----------------------------------------------------------
-- 🔹 Auto BulletBox + Item Magnet
local function getBulletBoxPart()
	local fx = Workspace:FindFirstChild("FX")
	local bulletBoxFolder = fx and fx:FindFirstChild("BulletBox")
	local box = bulletBoxFolder and bulletBoxFolder:FindFirstChild("Box")
	if box and box:IsA("BasePart") then
		return box
	end
	return nil
end

local function pullItemsToPlayer(hrp)
	for _, fx in ipairs(fxFolder:GetChildren()) do
		local itemPart = fx:FindFirstChildWhichIsA("BasePart")
		if itemPart and itemPart:IsDescendantOf(fxFolder) then
			itemPart.Anchored = false
			itemPart.CanCollide = false
			itemPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 2, 0))
			itemPart.AssemblyLinearVelocity = Vector3.new()
		end
	end
end

task.spawn(function()
	while task.wait(1) do
		local char = localPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			-- Auto BulletBox
			if autoBulletBoxEnabled then
				local boxPart = getBulletBoxPart()
				if boxPart then
					boxPart.Anchored = false
					boxPart.CanCollide = false
					boxPart.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 2, 0))
					boxPart.AssemblyLinearVelocity = Vector3.new()
				end
				pullItemsToPlayer(hrp)
			end
		end
	end
end)

----------------------------------------------------------
-- 🔹 NoClip Functions
local noClipConnection = nil

local function enableNoClip()
	if noClipConnection then return end
	
	noClipConnection = RunService.Stepped:Connect(function()
		local char = localPlayer.Character
		if char and noClipEnabled then
			for _, descendant in ipairs(char:GetDescendants()) do
				if descendant:IsA("BasePart") then
					descendant.CanCollide = false
				end
			end
		end
	end)
end

local function disableNoClip()
	if noClipConnection then
		noClipConnection:Disconnect()
		noClipConnection = nil
		
		-- Khôi phục collision
		local char = localPlayer.Character
		if char then
			for _, descendant in ipairs(char:GetDescendants()) do
				if descendant:IsA("BasePart") then
					descendant.CanCollide = true
				end
			end
		end
	end
end

local function applyNoClip()
	if noClipEnabled then
		enableNoClip()
	else
		disableNoClip()
	end
end

----------------------------------------------------------
-- 🔹 Speed Functions
local speedConnection = nil

local function applySpeed()
	local char = localPlayer.Character
	local humanoid = char and char:FindFirstChild("Humanoid")
	if humanoid then
		if speedEnabled then
			humanoid.WalkSpeed = speedValue
		else
			humanoid.WalkSpeed = 16 -- Giá trị mặc định của Roblox
		end
	end
end

-- Tự động áp dụng speed khi character respawn
local function onCharacterAddedForSpeed(character)
	task.wait(0.5)
	if speedEnabled then
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = speedValue
		end
	end
end

localPlayer.CharacterAdded:Connect(onCharacterAddedForSpeed)

----------------------------------------------------------
-- 🔹 HipHeight Toggle (Press M)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == hipHeightToggleKey then
		antiZombieEnabled = not antiZombieEnabled
		applyAntiZombie()
		print("Anti-Zombie:", antiZombieEnabled and "ON" or "OFF")
	end
end)

----------------------------------------------------------
-- 🔹 Camera Teleport to Nearest Zombie (Auto loop)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == cameraTeleportKey and cameraTeleportEnabled then
		-- Nếu đang chạy thì hủy
		if cameraTeleportActive then
			cameraTeleportActive = false
			
			-- Teleport về vị trí ban đầu
			local char = localPlayer.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp and cameraTeleportStartPosition then
				hrp.Anchored = false
				hrp.CFrame = CFrame.new(cameraTeleportStartPosition)
			elseif hrp then
				hrp.Anchored = false
			end
			
			-- Reset camera
			local camera = Workspace.CurrentCamera
			camera.CameraSubject = localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid")
			return
		end
		
		-- Lưu vị trí ban đầu của nhân vật
		local char = localPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			cameraTeleportStartPosition = hrp.Position
		end
		
		-- Bắt đầu camera teleport
		cameraTeleportActive = true
		
		-- Hàm hỗ trợ tìm mục tiêu camera theo từng chế độ
        local function findLowestMaxHealthZombie(currentZombie)
            local char = localPlayer.Character
            local playerHRP = char and char:FindFirstChild("HumanoidRootPart")
            if not playerHRP then return nil end
            local playerPosition = playerHRP.Position
            local lowestMaxHealth = math.huge
            local nearestDistance = math.huge
            local result = nil
            for _, zombie in ipairs(entityFolder:GetChildren()) do
                if zombie:IsA("Model") then
                    local humanoid = zombie:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        local head = zombie:FindFirstChild("Head")
                        local hrp = zombie:FindFirstChild("HumanoidRootPart")
                        local targetPart = head or hrp
                        if targetPart and targetPart:IsA("BasePart") then
                            local maxHealth = humanoid.MaxHealth
                            local distance = (playerPosition - targetPart.Position).Magnitude
                            if maxHealth < lowestMaxHealth or (maxHealth == lowestMaxHealth and distance < nearestDistance) then
                                lowestMaxHealth = maxHealth
                                nearestDistance = distance
                                result = {part = targetPart, zombie = zombie, maxHealth = maxHealth}
                            end
                        end
                    end
                end
            end
            if currentZombie == nil or (result and result.zombie ~= currentZombie) then
                return result
            end
            return nil
        end
        
        local function findLowestHealthZombie()
            local char = localPlayer.Character
            local playerHRP = char and char:FindFirstChild("HumanoidRootPart")
            if not playerHRP then return nil end
        
            local playerPosition = playerHRP.Position
            local lowestZombie = nil
            local lowestHealth = math.huge
            local nearestDistance = math.huge
        
            for _, zombie in ipairs(entityFolder:GetChildren()) do
                if zombie:IsA("Model") then
                    local humanoid = zombie:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        local head = zombie:FindFirstChild("Head")
                        local hrp = zombie:FindFirstChild("HumanoidRootPart")
                        local targetPart = head or hrp
                        if targetPart and targetPart:IsA("BasePart") then
                            local currentHealth = humanoid.Health
                            local distance = (playerPosition - targetPart.Position).Magnitude
                            if currentHealth < lowestHealth or (currentHealth == lowestHealth and distance < nearestDistance) then
                                lowestHealth = currentHealth
                                nearestDistance = distance
                                lowestZombie = {part = targetPart, zombie = zombie}
                            end
                        end
                    end
                end
            end
            return lowestZombie
        end
        
        local function findNearestAliveZombie()
            local char = localPlayer.Character
            local playerHRP = char and char:FindFirstChild("HumanoidRootPart")
            if not playerHRP then return nil end
        
            local playerPosition = playerHRP.Position
            local nearestZombie = nil
            local nearestDistance = math.huge
        
            for _, zombie in ipairs(entityFolder:GetChildren()) do
                if zombie:IsA("Model") then
                    local humanoid = zombie:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        local head = zombie:FindFirstChild("Head")
                        local hrp = zombie:FindFirstChild("HumanoidRootPart")
                        local targetPart = head or hrp
                        if targetPart and targetPart:IsA("BasePart") then
                            local distance = (playerPosition - targetPart.Position).Magnitude
                            if distance < nearestDistance then
                                nearestDistance = distance
                                nearestZombie = {part = targetPart, zombie = zombie}
                            end
                        end
                    end
                end
            end
            return nearestZombie
        end
        
        local function selectInitialTarget()
            if cameraTargetMode == "Nearest" then
                return findNearestAliveZombie()
            end
            return findLowestHealthZombie()
        end
        
        local function selectNextTarget(currentZombie)
            if cameraTargetMode == "Nearest" then
                return findNearestAliveZombie()
            end
        
            if currentZombie then
                local lowerMaxZombie = findLowestMaxHealthZombie(currentZombie.zombie)
                if lowerMaxZombie then
                    return lowerMaxZombie
                end
            end
        
            return findLowestHealthZombie()
        end
        
        -- Loop teleport theo mode được chọn
        task.spawn(function()
            local camera = Workspace.CurrentCamera
            local char = localPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            -- Kiểm tra xem có zombie không trước khi bắt đầu
            local currentTarget = selectInitialTarget()
            if not currentTarget then
                print("Không tìm thấy zombie nào!")
                cameraTeleportActive = false
                return
            end
            
            local lastZombiePosition = nil
            local ranOutOfZombies = false
            
            while cameraTeleportActive and currentTarget do
                local newTarget = nil
                
                -- Nếu đã có target, luôn kiểm tra nếu xuất hiện zombie mới có MaxHealth nhỏ hơn
                if currentTarget then
                    local lowerMaxZombie = findLowestMaxHealthZombie(currentTarget.zombie)
                    if lowerMaxZombie then
                        newTarget = lowerMaxZombie
                    end
                end
                
                if not newTarget then
                    newTarget = findLowestHealthZombie()
                end
                

                currentTarget = selectNextTarget(currentTarget)
                if cameraTeleportActive and not currentTarget then
                    ranOutOfZombies = true
                    break
                end
                
                if currentTarget and currentTarget.zombie then
                    local humanoid = currentTarget.zombie:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health > 0 and humanoid.Parent then
                        local targetPosition = currentTarget.part.Position
                        lastZombiePosition = targetPosition
                        
                        -- Set camera
                        camera.CameraSubject = humanoid
                        camera.CameraType = Enum.CameraType.Custom
                        local cameraOffset = Vector3.new(cameraOffsetX, cameraOffsetY, cameraOffsetZ)
                        camera.CFrame = CFrame.lookAt(targetPosition + cameraOffset, targetPosition)
                        
                        -- Đợi zombie chết/thay đổi mục tiêu
                        local checkCount = 0
                        repeat
                            task.wait(0.1)
                            checkCount = checkCount + 1
                            
                            -- Kiểm tra nếu đã bị hủy
                            if not cameraTeleportActive then
                                break
                            end
                            
                            -- Nếu zombie đã chết hoặc đổi sang target maxHealth thấp hơn thì break ngay
                            if not humanoid or humanoid.Parent == nil or humanoid.Health <= 0 then
                                break
                            end
                            
                            -- Kiểm tra zombie mới có MaxHealth thấp hơn
                            local lowerMaxZombie = findLowestMaxHealthZombie(currentTarget.zombie)
                            if lowerMaxZombie then
                                break
                            end
                            
                            -- Safety: nếu quá lâu không có thay đổi, break để tìm zombie mới
                            if checkCount > 300 then -- 30 giây
                                break
                            end
                        until false
                    else
                        -- Zombie đã chết hoặc không hợp lệ, tìm zombie mới
                        task.wait(0.2)
                    end
                else
                    -- Không tìm thấy target, đợi một chút rồi tìm lại
                    task.wait(0.5)
                end
            end
            
            -- Reset camera và nhân vật
            if hrp then
                hrp.Anchored = false
                if teleportToLastZombie and lastZombiePosition then
                    hrp.CFrame = CFrame.new(lastZombiePosition + Vector3.new(0, 5, 0))
                end
            end
            
            local finalChar = localPlayer.Character
            if finalChar then
                local finalHumanoid = finalChar:FindFirstChild("Humanoid")
                if finalHumanoid then
                    camera.CameraSubject = finalHumanoid
                end
            end
            
            cameraTeleportActive = false
            print("Camera Teleport đã dừng")
        end)
	end
end)

-- 🔹 ESP Player Drawing System (như Ryzex)
local hasPlayerDrawing = false
local playerESPObjects = {}

-- Function để tạo ESP elements cho player
local function newPlayerDrawing(t, props)
    local o = Drawing.new(t)
    for k, v in pairs(props) do
        o[k] = v
    end
    return o
end

local function createPlayerESPElements()
    return {
        Box       = newPlayerDrawing("Square", {Visible = false, Thickness = 2, Filled = false, Color = espColorPlayer}),
        Name      = newPlayerDrawing("Text",   {Visible = false, Center = true, Outline = true, Size = 14, Font = 2, Color = Color3.new(1,1,1)}),
        Tracer    = newPlayerDrawing("Line",   {Visible = false, Thickness = 1, Color = espColorPlayer}),
        HealthBar = newPlayerDrawing("Line",   {Visible = false, Thickness = 3, Color = Color3.new(0,1,0)})
    }
end

-- Kiểm tra Drawing API và khởi tạo ESP player
local function initializePlayerESP()
    local ok, obj = pcall(function()
        return Drawing.new("Square")
    end)
    if ok and obj then
        hasPlayerDrawing = true
        obj:Remove()
        
        -- Tạo ESP objects cho tất cả players hiện tại
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= localPlayer then
                playerESPObjects[plr] = createPlayerESPElements()
            end
        end
        
        -- Tạo ESP cho player mới join
        Players.PlayerAdded:Connect(function(plr)
            if plr ~= localPlayer then
                playerESPObjects[plr] = createPlayerESPElements()
            end
        end)
        
        -- Xóa ESP khi player leave
        Players.PlayerRemoving:Connect(function(plr)
            if playerESPObjects[plr] then
                for _, drawing in pairs(playerESPObjects[plr]) do
                    if drawing.Remove then
                        drawing:Remove()
                    end
                end
                playerESPObjects[plr] = nil
            end
        end)
        
        return true
    end
    return false
end

-- Khởi tạo ESP player
local playerESPInitialized = initializePlayerESP()

-- Function lấy box screen points (như Ryzex)
local function getBoxScreenPoints(cf, size)
    local half = size / 2
    local points = {}
    local visible = true

    for x = -1, 1, 2 do
        for y = -1, 1, 2 do
            for z = -1, 1, 2 do
                local corner = cf * Vector3.new(half.X * x, half.Y * y, half.Z * z)
                local screenPos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(corner)
                if not onScreen then
                    visible = false
                end
                table.insert(points, Vector2.new(screenPos.X, screenPos.Y))
            end
        end
    end

    return points, visible
end

-- Function ẩn ESP elements
local function hidePlayerESP(data)
    if not data then return end
    data.Box.Visible = false
    data.Name.Visible = false
    data.Tracer.Visible = false
    data.HealthBar.Visible = false
end

-- Function vẽ ESP cho player (như Ryzex)
local function drawPlayerESP(plr, cf, size, humanoid)
    if not hasPlayerDrawing or not espPlayerEnabled then
        hidePlayerESP(playerESPObjects[plr])
        return
    end

    local points, visible = getBoxScreenPoints(cf, size)
    if not visible or #points == 0 then
        hidePlayerESP(playerESPObjects[plr])
        return
    end

    local data = playerESPObjects[plr]
    if not data then
        return
    end

    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    for _, pt in ipairs(points) do
        minX = math.min(minX, pt.X)
        minY = math.min(minY, pt.Y)
        maxX = math.max(maxX, pt.X)
        maxY = math.max(maxY, pt.Y)
    end

    local boxWidth, boxHeight = maxX - minX, maxY - minY
    if boxWidth <= 3 or boxHeight <= 4 then
        hidePlayerESP(data)
        return
    end

    local slimWidth = boxWidth * 0.7
    local slimX = minX + (boxWidth - slimWidth) / 2
    
    -- Xác định màu dựa trên team
    local isEnemy = espPlayerTeamCheck and plr.Team ~= localPlayer.Team
    local baseColor = isEnemy and espColorEnemy or espColorPlayer
    local screenCenter = Vector2.new(Workspace.CurrentCamera.ViewportSize.X / 2, Workspace.CurrentCamera.ViewportSize.Y)

    local hp    = humanoid and humanoid.Health or 0
    local maxHp = humanoid and humanoid.MaxHealth or 100
    local ratio = math.clamp(maxHp > 0 and hp / maxHp or 0, 0, 1)

    -- Box
    if espPlayerBoxes then
        data.Box.Visible  = true
        data.Box.Position = Vector2.new(slimX, minY)
        data.Box.Size     = Vector2.new(slimWidth, boxHeight)
        data.Box.Color    = baseColor
    else
        data.Box.Visible = false
    end

    -- Name
    if espPlayerNames then
        data.Name.Visible  = true
        data.Name.Text     = string.format("%s [%d]", plr.Name, math.floor(hp))
        data.Name.Position = Vector2.new(slimX + slimWidth / 2, minY - 18)
        data.Name.Color    = baseColor
    else
        data.Name.Visible = false
    end

    -- Tracer
    if espPlayerTracers then
        data.Tracer.Visible = true
        data.Tracer.From    = screenCenter
        data.Tracer.To      = Vector2.new(slimX + slimWidth / 2, maxY)
        data.Tracer.Color   = baseColor
    else
        data.Tracer.Visible = false
    end

    -- Health Bar
    if espPlayerHealth then
        local barHeight = boxHeight * ratio
        data.HealthBar.Visible = true
        data.HealthBar.From = Vector2.new(slimX - 5, maxY)
        data.HealthBar.To   = Vector2.new(slimX - 5, maxY - barHeight)
        data.HealthBar.Color = Color3.fromRGB((1 - ratio) * 255, ratio * 255, 0)
    else
        data.HealthBar.Visible = false
    end
end

-- 🔹 FOV Drawing
local hasDrawing = false
local FOVCircle = nil

-- Kiểm tra Drawing API cho FOV Circle
local hasFOVDrawing = false
do
    local ok, obj = pcall(function()
        return Drawing.new("Circle")
    end)
    if ok and obj then
        hasFOVDrawing = true
        obj:Remove()
        
        -- Tạo FOV Circle
        FOVCircle = Drawing.new("Circle")
        FOVCircle.NumSides = 64
        FOVCircle.Thickness = 1.5
        FOVCircle.Filled = false
        FOVCircle.Color = Color3.fromRGB(255, 255, 255)
        FOVCircle.Visible = false
        FOVCircle.Transparency = 0.8
    end
end

-- 🔹 Aimbot Functions
local function getAimbotTargets()
    local targets = {}
    
    if aimbotTargetMode == "Players" or aimbotTargetMode == "All" then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= localPlayer and plr.Character then
                local hum = plr.Character:FindFirstChildWhichIsA("Humanoid")
                if hum and hum.Health > 0 then
                    -- Team check cho players (nếu có)
                    if not espPlayerTeamCheck or plr.Team ~= localPlayer.Team then
                        table.insert(targets, plr.Character)
                    end
                end
            end
        end
    end
    
    if aimbotTargetMode == "Zombies" or aimbotTargetMode == "All" then
        for _, m in ipairs(entityFolder:GetChildren()) do
            if m:IsA("Model") then
                local hum = m:FindFirstChildWhichIsA("Humanoid")
                if hum and hum.Health > 0 then
                    table.insert(targets, m)
                end
            end
        end
    end
    
    return targets
end

local function getClosestAimbotTarget()
    local camera = Workspace.CurrentCamera
    local mousePos = UserInputService:GetMouseLocation()
    local closestChar, closestPart
    local closestDist = math.huge
    
    for _, char in ipairs(getAimbotTargets()) do
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        if hum and hum.Health > 0 then
            local part = char:FindFirstChild(aimbotAimPart)
            if not part then
                part = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("Head")
            end
            if part then
                local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
                if onScreen and screenPos.Z > 0 then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if (not aimbotFOVEnabled) or dist <= aimbotFOVRadius then
                        if dist < closestDist then
                            closestDist = dist
                            closestChar = char
                            closestPart = part
                        end
                    end
                end
            end
        end
    end
    
    return closestChar, closestPart
end

local holdingMouse2 = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        holdingMouse2 = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        holdingMouse2 = false
    end
end)

-- Aimbot loop with FOV
RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    
    -- Cập nhật FOV Circle
    if FOVCircle then
        FOVCircle.Position = mousePos
        FOVCircle.Radius = aimbotFOVRadius
        FOVCircle.Visible = aimbotEnabled and aimbotFOVEnabled
        FOVCircle.Color = aimbotEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 255)
        FOVCircle.Thickness = aimbotEnabled and 2 or 1.5
    end
    
    -- ESP Player Update Loop
    if hasPlayerDrawing and espPlayerEnabled then
        local camera = Workspace.CurrentCamera
        local playerCount = 0
        
        -- Update ESP cho tất cả players
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= localPlayer then
                local char = plr.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if char and hum and hum.Health > 0 then
                    playerCount = playerCount + 1
                    -- Team check
                    if espPlayerTeamCheck and plr.Team == localPlayer.Team then
                        hidePlayerESP(playerESPObjects[plr])
                    else
                        local ok, cf, size = pcall(char.GetBoundingBox, char)
                        if ok and cf and size then
                            drawPlayerESP(plr, cf, size, hum)
                        else
                            hidePlayerESP(playerESPObjects[plr])
                        end
                    end
                else
                    hidePlayerESP(playerESPObjects[plr])
                end
            end
        end
        

    else
        -- Ẩn tất cả ESP player nếu tắt
        for _, data in pairs(playerESPObjects) do
            hidePlayerESP(data)
        end
    end
    
    if not aimbotEnabled then return end
    
    local active = true
    if aimbotHoldMouse2 and not holdingMouse2 then
        active = false
    end
    
    if active then
        local char, part = getClosestAimbotTarget()
        if char and part then
            local targetPos = part.Position
            if aimbotPrediction > 0 then
                local vel = part.AssemblyLinearVelocity or part.Velocity
                targetPos = targetPos + (vel * aimbotPrediction)
            end
            
            local camera = Workspace.CurrentCamera
            local cf = camera.CFrame
            local desired = CFrame.new(cf.Position, targetPos)
            
            if aimbotSmoothness > 0 then
                camera.CFrame = cf:Lerp(desired, aimbotSmoothness)
            else
                camera.CFrame = desired
            end
            
            -- Đổi màu FOV khi lock target
            if FOVCircle then
                FOVCircle.Color = Color3.fromRGB(255, 0, 0)
                FOVCircle.Thickness = 2.5
            end
        else
            -- Reset màu FOV khi không có target
            if FOVCircle then
                FOVCircle.Color = Color3.fromRGB(0, 255, 0)
                FOVCircle.Thickness = 2
            end
        end
    end
end)

-- 🔹 Fluent UI Controls - Reorganized Tabs

-- 🎯 COMBAT TAB
local CombatTab = Window:AddTab({ Title = "Combat", Icon = "⚔️" })

CombatTab:AddToggle("Aimbot", {
    Title = "🎯 Aimbot",
    Default = aimbotEnabled,
    Callback = function(Value)
        aimbotEnabled = Value
        print("Aimbot:", Value and "ON" or "OFF")
    end
})

-- Aimbot Settings trong Combat Tab
CombatTab:AddSection("🎯 Aimbot Settings")

CombatTab:AddDropdown("AimbotTargetMode", {
    Title = "🎯 Target Mode",
    Description = "Chọn mục tiêu cho aimbot",
    Values = {"Zombies", "Players", "All"},
    Default = aimbotTargetMode,
    Callback = function(Value)
        aimbotTargetMode = Value
        print("Aimbot Target Mode:", Value)
    end
})

CombatTab:AddDropdown("AimbotAimPart", {
    Title = "📍 Aim Part",
    Description = "Chọn bộ phận nhắm mục tiêu",
    Values = {"Head", "UpperTorso", "HumanoidRootPart"},
    Default = aimbotAimPart,
    Callback = function(Value)
        aimbotAimPart = Value
        print("Aimbot Aim Part:", Value)
    end
})

CombatTab:AddToggle("AimbotHoldMouse2", {
    Title = "🖱️ Hold Right Click",
    Description = "Giữ chuột phải để kích hoạt aimbot",
    Default = aimbotHoldMouse2,
    Callback = function(Value)
        aimbotHoldMouse2 = Value
        print("Aimbot Hold Mouse2:", Value and "ON" or "OFF")
    end
})

CombatTab:AddToggle("AimbotFOV", {
    Title = "📸 FOV Circle",
    Description = "Hiển thị và giới hạn phạm vi aimbot",
    Default = aimbotFOVEnabled,
    Callback = function(Value)
        aimbotFOVEnabled = Value
        print("Aimbot FOV:", Value and "ON" or "OFF")
    end
})

CombatTab:AddSlider("AimbotFOVRadius", {
    Title = "📏 FOV Radius",
    Description = "Bán kính phạm vi aimbot",
    Default = aimbotFOVRadius,
    Min = 50,
    Max = 500,
    Rounding = 0,
    Callback = function(Value)
        aimbotFOVRadius = Value
        print("Aimbot FOV Radius:", Value)
    end
})

CombatTab:AddSlider("AimbotSmoothness", {
    Title = "🐍 Smoothness",
    Description = "Mức độ mượt của aimbot (0 = instantly, 1 = very slow)",
    Default = aimbotSmoothness,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        aimbotSmoothness = Value
        print("Aimbot Smoothness:", Value)
    end
})

CombatTab:AddSlider("AimbotPrediction", {
    Title = "🔮 Prediction",
    Description = "Dự đoán chuyển động mục tiêu",
    Default = aimbotPrediction,
    Min = 0,
    Max = 0.2,
    Rounding = 3,
    Callback = function(Value)
        aimbotPrediction = Value
        print("Aimbot Prediction:", Value)
    end
})

CombatTab:AddSection("📦 Hitbox Settings")

CombatTab:AddToggle("Hitbox", {
    Title = "📦 Hitbox Expander",
    Default = hitboxEnabled,
    Callback = function(Value)
        hitboxEnabled = Value
        -- Cập nhật hitbox cho tất cả zombie hiện tại
        for _, zombie in ipairs(entityFolder:GetChildren()) do
            if zombie:IsA("Model") then
                local head = zombie:FindFirstChild("Head")
                if head and head:IsA("BasePart") then
                    if Value then
                        -- Bật hitbox
                        head.Size = hitboxSize
                        head.Transparency = 0.5
                        head.Color = Color3.fromRGB(255, 0, 0)
                        head.CanCollide = false
                    else
                        -- Tắt hitbox - khôi phục size gốc
                        local origX = head:GetAttribute("OriginalSizeX")
                        local origY = head:GetAttribute("OriginalSizeY")
                        local origZ = head:GetAttribute("OriginalSizeZ")
                        if origX and origY and origZ then
                            head.Size = Vector3.new(origX, origY, origZ)
                            head.Transparency = 1
                            head.CanCollide = true
                        end
                    end
                end
            end
        end
        print("Hitbox:", Value and "ON" or "OFF")
    end
})

CombatTab:AddSlider("HitboxSize", {
    Title = "Hitbox Size",
    Description = "Adjust zombie hitbox size",
    Default = 4,
    Min = 1,
    Max = 20,
    Rounding = 1,
    Callback = function(Value)
        hitboxSize = Vector3.new(Value, Value, Value)
        print("Hitbox Size:", Value)
    end
})

CombatTab:AddSection("⚡ Auto Skill")

CombatTab:AddToggle("AutoSkill", {
    Title = "⚡ Auto Skill",
    Default = autoSkillEnabled,
    Callback = function(Value)
        autoSkillEnabled = Value
        if Value then
            -- Kích hoạt từng skill ngay lập tức khi bật
            task.spawn(function()
                task.wait(1) -- Đợi 1 giây để character load xong
                activateSkill1010()
                task.wait(0.5)
                activateSkill1002()
            end)
        end
        print("Auto Skill:", Value and "ON" or "OFF")
    end
})

CombatTab:AddSlider("Skill1010Interval", {
    Title = "⚡ Skill 1010 Interval",
    Description = "Khoảng thời gian dùng skill 1010 (giây)",
    Default = skill1010Interval,
    Min = 1,
    Max = 60,
    Rounding = 1,
    Callback = function(Value)
        skill1010Interval = Value
        print("Skill 1010 Interval:", Value, "seconds")
    end
})

CombatTab:AddSlider("Skill1002Interval", {
    Title = "⚡ Skill 1002 Interval",
    Description = "Khoảng thời gian dùng skill 1002 (giây)",
    Default = skill1002Interval,
    Min = 1,
    Max = 60,
    Rounding = 1,
    Callback = function(Value)
        skill1002Interval = Value
        print("Skill 1002 Interval:", Value, "seconds")
    end
})

-- 👁️ ESP TAB
local ESPTab = Window:AddTab({ Title = "ESP", Icon = "👁️" })

ESPTab:AddSection("🧟 Zombie & Chest ESP")

ESPTab:AddToggle("ESPZombie", {
    Title = "🧟 ESP Zombie",
    Default = espZombieEnabled,
    Callback = function(Value)
        espZombieEnabled = Value
        if Value then
            applyZombieESPToAll()
        else
            clearZombieESP()
        end
        print("ESP Zombie:", Value and "ON" or "OFF")
    end
})

ESPTab:AddToggle("ESPChest", {
    Title = "📦 ESP Chest",
    Default = espChestEnabled,
    Callback = function(Value)
        espChestEnabled = Value
        if Value then
            applyChestESP()
        else
            clearChestESP()
        end
        print("ESP Chest:", Value and "ON" or "OFF")
    end
})

ESPTab:AddSection("👤 Player ESP")

ESPTab:AddToggle("ESPPlayer", {
    Title = "👤 ESP Player",
    Default = espPlayerEnabled,
    Callback = function(Value)
        espPlayerEnabled = Value
        
        if Value then
            -- Thử khởi tạo lại ESP player nếu chưa được khởi tạo
            if not playerESPInitialized then
                playerESPInitialized = initializePlayerESP()
            end
        else
            -- Ẩn tất cả ESP player khi tắt
            for _, data in pairs(playerESPObjects) do
                hidePlayerESP(data)
            end
        end
        
        print("ESP Player:", Value and "ON" or "OFF")
    end
})

-- ESP Player Settings trong ESP Tab
ESPTab:AddToggle("ESPPlayerBoxes", {
    Title = "📦 Player Boxes",
    Description = "Hiển thị box quanh người chơi",
    Default = espPlayerBoxes,
    Callback = function(Value)
        espPlayerBoxes = Value
        print("ESP Player Boxes:", Value and "ON" or "OFF")
    end
})

ESPTab:AddToggle("ESPPlayerTracers", {
    Title = "📍 Player Tracers",
    Description = "Hiển thị đường line từ camera đến player",
    Default = espPlayerTracers,
    Callback = function(Value)
        espPlayerTracers = Value
        print("ESP Player Tracers:", Value and "ON" or "OFF")
    end
})

ESPTab:AddToggle("ESPPlayerNames", {
    Title = "🏷️ Player Names",
    Description = "Hiển thị tên và máu của player",
    Default = espPlayerNames,
    Callback = function(Value)
        espPlayerNames = Value
        print("ESP Player Names:", Value and "ON" or "OFF")
    end
})

ESPTab:AddToggle("ESPPlayerHealth", {
    Title = "❤️ Player Health Bars",
    Description = "Hiển thị thanh máu của player",
    Default = espPlayerHealth,
    Callback = function(Value)
        espPlayerHealth = Value
        print("ESP Player Health:", Value and "ON" or "OFF")
    end
})

ESPTab:AddToggle("ESPPlayerTeamCheck", {
    Title = "🤝 Team Check",
    Description = "Chỉ hiển thị ESP cho enemy (không cùng team)",
    Default = espPlayerTeamCheck,
    Callback = function(Value)
        espPlayerTeamCheck = Value
        print("ESP Player Team Check:", Value and "ON" or "OFF")
    end
})

-- 🚀 MOVEMENT TAB
local MovementTab = Window:AddTab({ Title = "Movement", Icon = "🚀" })

MovementTab:AddToggle("Speed", {
    Title = "💨 Speed Boost",
    Default = speedEnabled,
    Callback = function(Value)
        speedEnabled = Value
        applySpeed()
        print("Speed:", Value and "ON" or "OFF")
    end
})

MovementTab:AddSlider("Speed", {
    Title = "💨 Speed Value",
    Description = "Tốc độ di chuyển (default: 20)",
    Default = speedValue,
    Min = 1,
    Max = 100,
    Rounding = 1,
    Callback = function(Value)
        speedValue = Value
        if speedEnabled then
            applySpeed() -- Áp dụng ngay nếu đang bật
        end
        print("Speed Value:", Value)
    end
})

MovementTab:AddToggle("NoClip", {
    Title = "👻 NoClip",
    Default = noClipEnabled,
    Callback = function(Value)
        noClipEnabled = Value
        applyNoClip()
        print("NoClip:", Value and "ON" or "OFF")
    end
})

MovementTab:AddToggle("AntiZombie", {
    Title = "🛡️ Anti-Zombie",
    Default = antiZombieEnabled,
    Callback = function(Value)
        antiZombieEnabled = Value
        applyAntiZombie() -- Áp dụng ngay lập tức
        print("Anti-Zombie:", Value and "ON" or "OFF")
    end
})

MovementTab:AddSlider("HipHeight", {
    Title = "🛡️ HipHeight",
    Description = "Điều chỉnh HipHeight để tránh zombie (studs)",
    Default = 20,
    Min = 0,
    Max = 200,
    Rounding = 1,
    Callback = function(Value)
        hipHeightValue = Value
        if antiZombieEnabled then
            applyAntiZombie() -- Áp dụng ngay nếu đang bật
        end
        print("HipHeight:", Value)
    end
})

MovementTab:AddSection("📷 Camera Teleport")

MovementTab:AddToggle("CameraTeleport", {
    Title = "📷 Camera Teleport (X)",
    Default = cameraTeleportEnabled,
    Callback = function(Value)
        cameraTeleportEnabled = Value
        print("Camera Teleport:", Value and "ON" or "OFF")
    end
})

MovementTab:AddDropdown("CameraTargetMode", {
    Title = "🎥 Target Mode",
    Description = "Chọn chế độ nhắm mục tiêu cho camera teleport",
    Values = {"LowestHealth", "Nearest"},
    Default = cameraTargetMode,
    Callback = function(Value)
        cameraTargetMode = Value
        print("Camera Target Mode:", Value)
    end
})

MovementTab:AddToggle("TeleportToLastZombie", {
    Title = "🏁 Teleport to Last Zombie",
    Description = "Teleport đến vị trí zombie cuối cùng sau khi camera teleport kết thúc",
    Default = teleportToLastZombie,
    Callback = function(Value)
        teleportToLastZombie = Value
        print("Teleport to Last Zombie:", Value and "ON" or "OFF")
    end
})

-- 💰 FARM TAB
local FarmTab = Window:AddTab({ Title = "Farm", Icon = "💰" })

FarmTab:AddToggle("AutoBulletBox", {
    Title = "🎁 Auto BulletBox + Items",
    Default = autoBulletBoxEnabled,
    Callback = function(Value)
        autoBulletBoxEnabled = Value
        print("Auto BulletBox + Items:", Value and "ON" or "OFF")
    end
})

FarmTab:AddToggle("Teleport", {
    Title = "🗝️ Auto Chest (T Key)",
    Default = teleportEnabled,
    Callback = function(Value)
        teleportEnabled = Value
        print("Auto Chest:", Value and "ON" or "OFF")
    end
})

-- ⚙️ SETTINGS TAB
local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "⚙️" })

SettingsTab:AddSection("🎮 Keybinds")

SettingsTab:AddKeybind("MenuKey", {
    Title = "🔧 Menu Key",
    Default = Enum.KeyCode.RightShift,
    Callback = function()
        -- Menu key đã được Fluent xử lý
    end
})

SettingsTab:AddSection("⚠️ Reset Script")

SettingsTab:AddButton("Unload", {
    Title = "🧹 Unload Script",
    Description = "Unload toàn bộ script và xóa GUI",
    Callback = function()
        -- Cleanup FOV
        if FOVCircle then
            FOVCircle:Remove()
        end
        -- Xóa ESP Player objects
        for _, data in pairs(playerESPObjects) do
            if data.Box then data.Box:Remove() end
            if data.Name then data.Name:Remove() end
            if data.Tracer then data.Tracer:Remove() end
            if data.HealthBar then data.HealthBar:Remove() end
        end
        -- Xóa GUI
        local ScreenGui = localPlayer:FindFirstChild("PlayerGui"):FindFirstChild("QuickTeleportButtons")
        if ScreenGui then
            ScreenGui:Destroy()
        end
        Window:Destroy()
        print("Script unloaded successfully!")
    end
})

SettingsTab:AddSection("🎨 Theme")
SettingsTab:AddDropdown("Theme", {
    Title = "🎨 UI Theme",
    Description = "Chọn theme cho giao diện",
    Values = {"Dark", "Light", "Acrilic", "Glass"},
    Default = "Dark",
    Callback = function(Value)
        -- Fluent sẽ tự xử lý theme
        print("Theme changed to:", Value)
    end
})

-- 📝 INFO TAB
local InfoTab = Window:AddTab({ Title = "Info", Icon = "📝" })

InfoTab:AddParagraph({
    Title = "🎮 Controls",
    Content = [[
🖱️ Right Click - Activate Aimbot (if enabled)
🗝️ T Key - Auto Open All Chests  
📷 X Key - Camera Teleport to Zombies
🛡️ M Key - Toggle Anti-Zombie
⌨️ Right Shift - Open/Close Menu
]]
})

InfoTab:AddParagraph({
    Title = "💡 Tips",
    Content = [[
• Combine Aimbot + Hitbox for maximum efficiency
• Use ESP to track zombies through walls
• ESP Player shows enemies through walls with boxes
• Anti-Zombie keeps you safe from attacks
• Auto Skill provides continuous damage
• Camera Teleport is great for farming
• Auto Chest collects all loot instantly
• Aimbot targets both zombies and players
]]
})

InfoTab:AddParagraph({
    Title = "🔧 Cleanup",
    Content = [[
• End key - Cleanup all script objects
• Right Shift - Toggle menu
]]
})

InfoTab:AddParagraph({
    Title = "⚠️ Important",
    Content = [[
• Some features may not work in all games
• Use responsibly to avoid detection
• Adjust settings based on your playstyle
• Disable features if experiencing lag
]]
})

-- Cleanup commands cho script
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- End key - Cleanup
    if input.KeyCode == Enum.KeyCode.End then
        if FOVCircle then
            FOVCircle:Remove()
        end
        -- Xóa ESP Player objects
        for _, data in pairs(playerESPObjects) do
            if data.Box then data.Box:Remove() end
            if data.Name then data.Name:Remove() end
            if data.Tracer then data.Tracer:Remove() end
            if data.HealthBar then data.HealthBar:Remove() end
        end
        playerESPObjects = {}
        print("Script cleanup completed!")
    end
end)

Window:SelectTab(1)
print("Zombie Hyperloot: Script loaded successfully!")
print("🎯 Tabs: Combat | ESP | Movement | Farm | Settings | Info")
print("👥 ESP Player: " .. (hasPlayerDrawing and "ENABLED" or "DISABLED - Drawing API not available"))
print("📸 FOV Circle: " .. (hasFOVDrawing and "ENABLED" or "DISABLED - Drawing API not available"))
print("🔴 Green FOV = Idle | Red FOV = Locked Target")
print("👤 ESP Player Features: Boxes, Tracers, Names, Health Bars")
print("🔧 End key - Cleanup all script objects")

----------------------------------------------------------
-- 🔹 Quick Teleport Buttons (Right Side of Screen)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "QuickTeleportButtons"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local Container = Instance.new("Frame")
Container.Name = "Container"
Container.BackgroundTransparency = 1
Container.Size = UDim2.new(0, 160, 0, 200)
Container.Position = UDim2.new(1, -180, 0.5, -100) -- Bên phải, giữa màn hình
Container.Parent = ScreenGui

-- Sử dụng UIListLayout để tự động sắp xếp các button
local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = Container

-- Thêm padding cho container
local UIPadding = Instance.new("UIPadding")
UIPadding.PaddingTop = UDim.new(0, 10)
UIPadding.PaddingRight = UDim.new(0, 10)
UIPadding.Parent = Container

local function createTeleportButton(name, text, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(0, 150, 0, 35)
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 14
	button.Font = Enum.Font.SourceSansBold
	button.AutoButtonColor = false
	button.Parent = Container
	
	-- Hover effects
	local hoverColor = Color3.new(math.min(color.R + 0.2, 1), math.min(color.G + 0.2, 1), math.min(color.B + 0.2, 1))
	local originalColor = color
	
	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = hoverColor
	end)
	
	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = originalColor
	end)
	
	return button
end

-- Tìm vị trí Task cuối map
local function findTaskPosition()
	local map = Workspace:FindFirstChild("Map")
	if not map then 
		return nil 
	end
	
	-- Tìm trong tất cả children của Map
	for _, mapChild in ipairs(map:GetChildren()) do
		local eItem = mapChild:FindFirstChild("EItem")
		if eItem then
			local task = eItem:FindFirstChild("Task")
			if task then
				local default = task:FindFirstChild("default")
				if default then
					local part = default:FindFirstChildWhichIsA("BasePart")
					if part then
						return part.Position + Vector3.new(0, 3, 0)
					end
				end
			end
		end
	end
	
	return nil
end

-- Tìm vị trí Safe Zone (Map.Model.Decoration.Crane.Model.Part)
local function findSafeZonePosition()
	local map = Workspace:FindFirstChild("Map")
	if not map then 
		return nil 
	end
	
	local model = map:FindFirstChild("Model")
	if not model then 
		return nil 
	end
	
	local decoration = model:FindFirstChild("Decoration")
	if not decoration then 
		return nil 
	end
	
	local crane = decoration:FindFirstChild("Crane")
	if not crane then 
		return nil 
	end
	
	local craneModel = crane:FindFirstChild("Model")
	if not craneModel then 
		return nil 
	end
	
	local part = craneModel:FindFirstChild("Part")
	if part and part:IsA("BasePart") then
		return part.Position + Vector3.new(0, 3, 0)
	end
	
	return nil
end

-- Tìm tất cả Exit Door (có thể có nhiều door)
local function findAllExitDoors()
	local doors = {}
	local map = Workspace:FindFirstChild("Map")
	if not map then 
		return doors 
	end
	
	-- Tìm trong tất cả children của Map (có thể là Map[43].EItem.ExitDoor, Map[33].EItem.ExitDoor, etc.)
	for _, mapChild in ipairs(map:GetChildren()) do
		local eItem = mapChild:FindFirstChild("EItem")
		if eItem then
			-- Tìm ExitDoor trong EItem này
			for _, child in ipairs(eItem:GetChildren()) do
				if string.find(child.Name, "ExitDoor") then
					-- Thử tìm Body trước
					local body = child:FindFirstChild("Body")
					local targetPart = nil
					
					if body then
						-- Nếu Body là BasePart
						if body:IsA("BasePart") then
							targetPart = body
						else
							-- Nếu Body là Model hoặc object khác, tìm BasePart bên trong
							targetPart = body:FindFirstChildWhichIsA("BasePart")
						end
					end
					
					-- Nếu không tìm thấy Body, tìm BasePart trực tiếp trong ExitDoor
					if not targetPart then
						targetPart = child:FindFirstChildWhichIsA("BasePart")
					end
					
					-- Nếu vẫn không tìm thấy, thử tìm PrimaryPart
					if not targetPart and child:IsA("Model") then
						targetPart = child.PrimaryPart
					end
					
					-- Nếu vẫn không tìm thấy, thử tìm HumanoidRootPart hoặc Head
					if not targetPart and child:IsA("Model") then
						targetPart = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChild("Head")
					end
					
					if targetPart and targetPart:IsA("BasePart") then
						table.insert(doors, targetPart.Position + Vector3.new(0, 3, 0))
					end
				end
			end
		end
	end
	
	return doors
end

-- Tìm tất cả Supply Piles (chỗ lấy đạn)
local function findAllSupplyPiles()
	local supplies = {}
	local map = Workspace:FindFirstChild("Map")
	if not map then 
		return supplies 
	end
	
	-- Tìm trong tất cả children của Map
	for _, mapChild in ipairs(map:GetChildren()) do
		local eItem = mapChild:FindFirstChild("EItem")
		if eItem then
			-- Tìm tất cả object có tên là số (như "3", "1", "2", "4"...)
			-- Cấu trúc: EItem["3"].Model hoặc EItem["3"] chứa BasePart
			for _, child in ipairs(eItem:GetChildren()) do
				if tonumber(child.Name) then -- Nếu tên là số (như "3")
					-- Tìm Model bên trong
					local model = child:FindFirstChild("Model")
					if model then
						local part = model:FindFirstChildWhichIsA("BasePart")
						if part then
							table.insert(supplies, part.Position + Vector3.new(0, 3, 0))
						end
					else
						-- Nếu không có Model, tìm BasePart trực tiếp trong child
						local part = child:FindFirstChildWhichIsA("BasePart")
						if part then
							table.insert(supplies, part.Position + Vector3.new(0, 3, 0))
						end
					end
				end
			end
		end
	end
	
	-- Loại bỏ duplicate dựa trên khoảng cách
	local uniqueSupplies = {}
	for i, pos1 in ipairs(supplies) do
		local isDuplicate = false
		for j, pos2 in ipairs(uniqueSupplies) do
			if (pos1 - pos2).Magnitude < 5 then -- Nếu cách nhau < 5 studs thì coi như duplicate
				isDuplicate = true
				break
			end
		end
		if not isDuplicate then
			table.insert(uniqueSupplies, pos1)
		end
	end
	
	return uniqueSupplies
end

-- Tìm tất cả Ammo (đạn)
local function findAllAmmo()
	local ammos = {}
	local map = Workspace:FindFirstChild("Map")
	if not map then 
		return ammos 
	end
	
	-- Tìm trong tất cả children của Map
	for _, mapChild in ipairs(map:GetChildren()) do
		local eItem = mapChild:FindFirstChild("EItem")
		if eItem then
			-- Tìm tất cả object có tên là "Ammo" (Model)
			for _, child in ipairs(eItem:GetChildren()) do
				if child.Name == "Ammo" and child:IsA("Model") then
					-- Tìm BasePart trong Ammo Model
					local part = child:FindFirstChildWhichIsA("BasePart")
					if part then
						table.insert(ammos, part.Position + Vector3.new(0, 3, 0))
					end
				end
			end
		end
	end
	
	-- Loại bỏ duplicate dựa trên khoảng cách
	local uniqueAmmos = {}
	for i, pos1 in ipairs(ammos) do
		local isDuplicate = false
		for j, pos2 in ipairs(uniqueAmmos) do
			if (pos1 - pos2).Magnitude < 5 then -- Nếu cách nhau < 5 studs thì coi như duplicate
				isDuplicate = true
				break
			end
		end
		if not isDuplicate then
			table.insert(uniqueAmmos, pos1)
		end
	end
	
	return uniqueAmmos
end

-- Hàm teleport
local function teleportToPosition(position)
	if not position then
		return
	end
	
	local char = localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	
	hrp.CFrame = CFrame.new(position)
end

-- Đợi game load hoàn toàn trước khi kiểm tra (tăng thời gian và retry)
local function waitForMapLoad(maxWait)
	maxWait = maxWait or 5
	local waited = 0
	while waited < maxWait do
		local map = Workspace:FindFirstChild("Map")
		if map then
			-- Kiểm tra xem có ít nhất một child có EItem không
			local foundEItem = false
			for _, mapChild in ipairs(map:GetChildren()) do
				if mapChild:FindFirstChild("EItem") then
					foundEItem = true
					break
				end
			end
			if foundEItem then
				task.wait(0.5) -- Đợi thêm một chút để chắc chắn
				break
			end
		end
		task.wait(0.5)
		waited = waited + 0.5
	end
end

waitForMapLoad(10) -- Đợi tối đa 10 giây
watchChestDescendants()
if espChestEnabled then
	applyChestESP()
end



-- Tạo các button (chỉ hiển thị nếu tìm thấy vị trí)
local createdButtons = {} -- Lưu các button đã tạo để có thể refresh
local currentButtonCount = 0

-- Hàm xóa tất cả button cũ
local function clearAllButtons()
	for _, button in pairs(createdButtons) do
		if button and button.Parent then
			button:Destroy()
		end
	end
	createdButtons = {}
	currentButtonCount = 0
end

-- Hàm tạo lại tất cả buttons
local function refreshButtons()
	-- Xóa các button cũ
	clearAllButtons()
	
	local buttonLayoutOrder = 1
	
	-- Kiểm tra và tạo button Exit Door
	local exitDoors = findAllExitDoors()
	if #exitDoors > 0 then
		local exitDoorButton = createTeleportButton("ExitDoorButton", "🚪 Exit Door", Color3.fromRGB(155, 89, 182))
		exitDoorButton.LayoutOrder = buttonLayoutOrder
		buttonLayoutOrder = buttonLayoutOrder + 1
		createdButtons["ExitDoor"] = exitDoorButton
		
		exitDoorButton.MouseButton1Click:Connect(function()
			local doors = findAllExitDoors()
			if #doors > 0 then
				-- Teleport tới door gần nhất
				local char = localPlayer.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp then
					local playerPos = hrp.Position
					local nearestDoor = doors[1]
					local nearestDistance = (playerPos - nearestDoor).Magnitude
					
					for _, doorPos in ipairs(doors) do
						local distance = (playerPos - doorPos).Magnitude
						if distance < nearestDistance then
							nearestDistance = distance
							nearestDoor = doorPos
						end
					end
					
					teleportToPosition(nearestDoor)
				end
			end
		end)
	end
	
	-- Task button (hiển thị riêng, độc lập với Exit Door)
	local taskPos = findTaskPosition()
	if taskPos then
		local taskButton = createTeleportButton("TaskButton", "📋 Task Cuối Map", Color3.fromRGB(52, 152, 219))
		taskButton.LayoutOrder = buttonLayoutOrder
		buttonLayoutOrder = buttonLayoutOrder + 1
		createdButtons["Task"] = taskButton
		
		taskButton.MouseButton1Click:Connect(function()
			local pos = findTaskPosition()
			teleportToPosition(pos)
		end)
	end
	
	-- Tạo button riêng cho TỪNG Supply Pile (nếu có 3 thì tạo 3 button)
	local supplies = findAllSupplyPiles()
	for i, supplyPos in ipairs(supplies) do
		local supplyButton = createTeleportButton("SupplyButton" .. i, "🔫 Đạn " .. i, Color3.fromRGB(241, 196, 15))
		supplyButton.LayoutOrder = buttonLayoutOrder
		buttonLayoutOrder = buttonLayoutOrder + 1
		createdButtons["Supply" .. i] = supplyButton
		
		-- Mỗi lần click sẽ tìm lại tất cả supply piles và teleport tới đúng thứ tự
		supplyButton.MouseButton1Click:Connect(function()
			local allSupplies = findAllSupplyPiles()
			if allSupplies[i] then
				teleportToPosition(allSupplies[i])
			end
		end)
	end
	
	-- Tạo button riêng cho TỪNG Ammo (nếu có 3 thì tạo 3 button)
	local ammos = findAllAmmo()
	for i, ammoPos in ipairs(ammos) do
		local ammoButton = createTeleportButton("AmmoButton" .. i, "💣 Ammo " .. i, Color3.fromRGB(230, 126, 34))
		ammoButton.LayoutOrder = buttonLayoutOrder
		buttonLayoutOrder = buttonLayoutOrder + 1
		createdButtons["Ammo" .. i] = ammoButton
		
		-- Mỗi lần click sẽ tìm lại tất cả ammo và teleport tới đúng thứ tự
		ammoButton.MouseButton1Click:Connect(function()
			local allAmmos = findAllAmmo()
			if allAmmos[i] then
				teleportToPosition(allAmmos[i])
			end
		end)
	end
	
	currentButtonCount = buttonLayoutOrder - 1
	
	-- Cập nhật kích thước container dựa trên số button
	if currentButtonCount > 0 then
		Container.Size = UDim2.new(0, 160, 0, currentButtonCount * 40 + 20)
		Container.Position = UDim2.new(1, -180, 0.5, -(currentButtonCount * 40 + 20) / 2)
		Container.Visible = true
	else
		Container.Visible = false
	end
end

-- Tạo buttons lần đầu
refreshButtons()

-- Tự động refresh buttons mỗi 15 giây để cập nhật khi qua map mới
task.spawn(function()
	while task.wait(15) do
		refreshButtons()
	end
end)