--// Zombie + Chest ESP + Hitbox + Teleport Collector
-- Load Fluent UI (working library)
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Zombie Hyperloot",
    SubTitle = "by TNG",
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

-- Cấu hình
local hitboxSize = Vector3.new(4, 4, 4)
local espColorZombie = Color3.fromRGB(0, 255, 0)
local espColorChest = Color3.fromRGB(255, 255, 0)
local refreshRate = 1
local teleportKey = Enum.KeyCode.T -- ấn T để teleport tới toàn bộ vật phẩm rơi

-- Toggle states
local espZombieEnabled = true
local espChestEnabled = false
local hitboxEnabled = true
local teleportEnabled = true
local cameraTeleportEnabled = true
local teleportToLastZombie = false -- Teleport tới zombie cuối cùng hay không
local cameraTeleportKey = Enum.KeyCode.X -- ấn X để tele camera tới zombie
local cameraTeleportActive = false -- Biến kiểm tra đang chạy camera teleport loop
local cameraTeleportStartPosition = nil -- Vị trí ban đầu của nhân vật
local cameraOffsetX = 0 -- Camera offset X
local cameraOffsetY = 10 -- Camera offset Y
local cameraOffsetZ = -2 -- Camera offset Z

-- Auto Move Configuration
local autoMoveEnabled = false -- Tự động duy trì khoảng cách với zombie
local autoMoveDistance = 100 -- Khoảng cách cần duy trì với zombie (studs)
local autoMoveSpeed = 16 -- Tốc độ di chuyển (studs/second)
local autoMoveKey = Enum.KeyCode.M -- ấn M để bật/tắt auto move
local isAutoMoving = false -- Trạng thái đang auto move
local autoMoveTarget = nil -- Zombie đang theo dõi
local lastTargetZombie = nil -- Zombie được theo dõi lần trước


----------------------------------------------------------
-- 🔹 Auto Move Functions - Duy trì khoảng cách cố định với zombie
-- Kiểm tra vật cản trên đường đi
local function checkObstacle(startPos, endPos)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {localPlayer.Character}
	
	local direction = (endPos - startPos)
	local raycastResult = Workspace:Raycast(startPos, direction)
	
	if raycastResult then
		local distance = (raycastResult.Position - startPos).Magnitude
		local totalDistance = direction.Magnitude
		
		-- Nếu vật cản ở gần (trong 80% đường đi)
		if distance < totalDistance * 0.8 then
			return true, raycastResult.Position
		end
	end
	
	return false, nil
end

-- Tìm zombie gần nhất để theo dõi
local function findNearestZombieToPlayer()
	local char = localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	
	local playerPosition = hrp.Position
	local nearestZombie = nil
	local nearestDistance = math.huge
	
	for _, zombie in ipairs(entityFolder:GetChildren()) do
		if zombie:IsA("Model") then
			local humanoid = zombie:FindFirstChild("Humanoid")
			local zombieHRP = zombie:FindFirstChild("HumanoidRootPart")
			
			if humanoid and humanoid.Health > 0 and zombieHRP then
				local distance = (playerPosition - zombieHRP.Position).Magnitude
				if distance < nearestDistance then
					nearestDistance = distance
					nearestZombie = {zombie = zombie, distance = distance, position = zombieHRP.Position}
				end
			end
		end
	end
	
	return nearestZombie
end

-- Hàm duy trì khoảng cách cố định với zombie gần nhất
local function maintainDistanceFromZombie()
	local char = localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChild("Humanoid")
	
	if not hrp or not humanoid then 
		return 
	end
	
	local playerPosition = hrp.Position
	local targetDistance = tonumber(autoMoveDistance) or 100
	
	-- Tìm zombie gần nhất
	local nearestZombie = findNearestZombieToPlayer()
	if not nearestZombie then 
		lastTargetZombie = nil
		return 
	end
	
	-- Kiểm tra xem có phải zombie mới không
	if lastTargetZombie ~= nearestZombie.zombie then
		lastTargetZombie = nearestZombie.zombie
	end
	
	local zombiePosition = nearestZombie.position
	local currentDistance = nearestZombie.distance
	
	-- Tính toán vị trí cần di chuyển tới để duy trì khoảng cách 100 studs
	local direction = (playerPosition - zombiePosition).Unit
	local targetPosition = zombiePosition + (direction * targetDistance)
	
	-- Kiểm tra vật cản
	local hasObstacle, obstaclePos = checkObstacle(playerPosition, targetPosition)
	if hasObstacle then
		
		-- Tìm đường đi thay thế (di chuyển sang trái/phải)
		local sideDirections = {
			Vector3.new(1, 0, 0),   -- Phải
			Vector3.new(-1, 0, 0),  -- Trái
			Vector3.new(0, 0, 1),   -- Trước
			Vector3.new(0, 0, -1)   -- Sau
		}
		
		local bestPosition = nil
		for _, sideDir in ipairs(sideDirections) do
			local testPos = zombiePosition + (sideDir * targetDistance)
			local testDir = (testPos - playerPosition).Unit
			local finalPos = playerPosition + (testDir * targetDistance)
			
			local hasTestObstacle = checkObstacle(playerPosition, finalPos)
			if not hasTestObstacle then
				bestPosition = finalPos
				break
			end
		end
		
		if bestPosition then
			targetPosition = bestPosition
		else
			return
		end
	end
	
	-- Di chuyển tới vị trí mục tiêu để duy trì khoảng cách 100 studs
	humanoid:MoveTo(targetPosition)
end

-- Auto Move Loop - Duy trì khoảng cách 100 studs với zombie gần nhất
task.spawn(function()
	while task.wait(0.2) do -- Kiểm tra thường xuyên để theo dõi zombie gần nhất
		if autoMoveEnabled then
			local nearestZombie = findNearestZombieToPlayer()
			
			if nearestZombie then
				local currentDistance = tonumber(nearestZombie.distance) or 0
				local targetDistance = tonumber(autoMoveDistance) or 100
				local distanceDiff = math.abs(currentDistance - targetDistance)
				
				-- Chỉ di chuyển nếu khoảng cách sai lệch > 10 studs (cho khoảng cách 100)
				if distanceDiff > 10 then
					maintainDistanceFromZombie()
					task.wait(0.5) -- Đợi ngắn hơn để phản ứng nhanh hơn
				end
			end
		end
	end
end)

----------------------------------------------------------
-- 🔹 Hàm tạo ESP Billboard
local function createESP(part, color, name, zombie)
	if not part or part:FindFirstChild("ESPTag") then return end

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

----------------------------------------------------------
-- 🔹 ESP cho chest (chính xác đường dẫn: Map.Model.Chest.Model.Chest)
local function setupChestESP()
	local map = Workspace:FindFirstChild("Map")
	if not map then return end
	
	local mapModel = map:FindFirstChild("Model")
	if not mapModel then return end
	
	local chest = mapModel:FindFirstChild("Chest")
	if not chest then return end
	
	local chestModel = chest:FindFirstChild("Model")
	if not chestModel then return end
	
	-- ESP cho tất cả chest trong Model
	for _, chestObj in ipairs(chestModel:GetChildren()) do
		if chestObj:IsA("Model") then
			local chestPart = chestObj:FindFirstChild("Chest")
			if chestPart and chestPart:IsA("BasePart") then
				createESP(chestPart, espColorChest, "Chest", nil)
			end
		end
	end
end

----------------------------------------------------------
-- 🔹 Tự động làm mới ESP mỗi vài giây
task.spawn(function()
	while task.wait(refreshRate) do
		for _, zombie in ipairs(entityFolder:GetChildren()) do
			if zombie:IsA("Model") and zombie:FindFirstChild("Head") then
				local head = zombie:FindFirstChild("Head")
				if head then
					if espZombieEnabled then
						createESP(head, espColorZombie, zombie.Name, zombie)
					end
					-- Không gọi expandHitbox ở đây nữa vì đã xử lý trong ChildAdded
				end
			end
		end
		if espChestEnabled then
			setupChestESP()
		end
	end
end)

----------------------------------------------------------
-- 🔹 Auto Teleport to Chests and Items (Press T)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == teleportKey and teleportEnabled then
		local char = localPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local oldPos = hrp.Position
		local virtualUser = game:GetService("VirtualUser")
		
		-- Bước 1: Tìm tất cả chest (tất cả loại chest: Common, Rare, Epic, Legendary...)
		local chests = {}
		local map = Workspace:FindFirstChild("Map")
		if map then
			-- Duyệt qua tất cả children của Map
			for _, child in ipairs(map:GetChildren()) do
				if child:FindFirstChild("Chest") then
					local chestFolder = child.Chest
					
					-- Duyệt qua TẤT CẢ children (Model, Model1, Model2, Model3...)
					for _, chestModel in ipairs(chestFolder:GetChildren()) do
						if chestModel:IsA("Model") and chestModel:FindFirstChild("Chest") then
							local chestModelFolder = chestModel.Chest
							
							-- Tìm tất cả chest types (Common, Rare, Epic, Legendary...)
							for _, chestModelChild in ipairs(chestModelFolder:GetChildren()) do
								if chestModelChild:IsA("Model") then
									-- Lấy BasePart đầu tiên bên trong chest Model
									local chestPart = chestModelChild:FindFirstChildWhichIsA("BasePart")
									if chestPart then
										table.insert(chests, chestPart)
									end
								end
							end
						end
					end
				end
			end
		end
		
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
	
		
		-- Bước 3: Teleport tới tất cả items
		local items = {}
		for _, fx in ipairs(fxFolder:GetChildren()) do
			local part = fx:FindFirstChildWhichIsA("BasePart")
			if part then
				table.insert(items, part)
			end
		end
		
		for _, part in ipairs(items) do
			if part and part:IsDescendantOf(fxFolder) then
				hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 2, 0))
				task.wait(0.15)
			end
		end
		
		-- Quay về vị trí cũ
		hrp.CFrame = CFrame.new(oldPos)
	end
end)



----------------------------------------------------------
-- 🔹 Auto Move Keybind (Press M)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == autoMoveKey then
		autoMoveEnabled = not autoMoveEnabled
		print("Auto Move:", autoMoveEnabled and "ON" or "OFF")
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
		
		-- Tìm zombie còn sống máu ít nhất từ vị trí người chơi
        -- Tìm zombie còn sống có MaxHealth nhỏ nhất. Nếu hiện tại đã tele vào 1 zombie mà có zombie mới MaxHealth thấp hơn, chuyển sang tele tới con đó.
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
            -- Nếu truyền vào zombie hiện tại mà vẫn là con này/là nil thì trả về nil, ngược lại trả về zombie mới
            if currentZombie == nil or (result and result.zombie ~= currentZombie) then
                return result
            end
            return nil
        end
        
        -- Tìm zombie máu hiện tại thấp nhất (ưu tiên gần nếu trùng máu)
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
                    if humanoid and humanoid.Health > 0 then -- chỉ lấy zombie còn sống
                        local head = zombie:FindFirstChild("Head")
                        local hrp = zombie:FindFirstChild("HumanoidRootPart")
                        local targetPart = head or hrp
                        if targetPart and targetPart:IsA("BasePart") then
                            local currentHealth = humanoid.Health
                            local distance = (playerPosition - targetPart.Position).Magnitude
                            -- Ưu tiên máu thấp nhất, nếu trùng máu thì lấy con gần nhất
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
        
        -- Loop teleport tới zombie máu thấp nhất hoặc zombie MaxHealth thấp hơn
        task.spawn(function()
            local camera = Workspace.CurrentCamera
            local char = localPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            -- Kiểm tra xem có zombie không trước khi bắt đầu
            local initialZombie = findLowestHealthZombie()
            if not initialZombie then
                print("Không tìm thấy zombie nào!")
                cameraTeleportActive = false
                return
            end
            
            local lastZombiePosition = nil
            local currentTarget = nil
            
            while cameraTeleportActive do
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
                
                -- Nếu không tìm thấy zombie nào, thoát khỏi loop
                if not newTarget then
                    print("Không còn zombie nào!")
                    break
                end
                
                currentTarget = newTarget
                
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

----------------------------------------------------------
-- 🔹 Fluent UI Controls
local MainTab = Window:AddTab({ Title = "Main", Icon = "" })

MainTab:AddToggle("ESPZombie", {
    Title = "ESP Zombie",
    Default = espZombieEnabled,
    Callback = function(Value)
        espZombieEnabled = Value
        print("ESP Zombie:", Value and "ON" or "OFF")
    end
})

MainTab:AddToggle("Hitbox", {
    Title = "Hitbox",
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

MainTab:AddToggle("Teleport", {
    Title = "Auto Collect (T Key) - Open Chests & Items",
    Default = teleportEnabled,
    Callback = function(Value)
        teleportEnabled = Value
        print("Auto Collect:", Value and "ON" or "OFF")
    end
})


MainTab:AddToggle("CameraTeleport", {
    Title = "Camera Teleport (X Key)",
    Default = cameraTeleportEnabled,
    Callback = function(Value)
        cameraTeleportEnabled = Value
        print("Camera Teleport:", Value and "ON" or "OFF")
    end
})


MainTab:AddToggle("AutoMove", {
    Title = "Auto Move (M Key) - Maintain Distance",
    Default = autoMoveEnabled,
    Callback = function(Value)
        autoMoveEnabled = Value
        print("Auto Move:", Value and "ON" or "OFF")
    end
})


-- Settings Tab
local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "" })

SettingsTab:AddSlider("HitboxSize", {
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

SettingsTab:AddSlider("RefreshRate", {
    Title = "Refresh Rate",
    Description = "ESP update rate in seconds",
    Default = 1,
    Min = 0.1,
    Max = 5,
    Rounding = 1,
    Callback = function(Value)
        refreshRate = Value
        print("Refresh Rate:", Value)
    end
})

SettingsTab:AddSlider("AutoMoveDistance", {
    Title = "Auto Move Distance",
    Description = "Distance to maintain from zombie (studs)",
    Default = 100,
    Min = 50,
    Max = 200,
    Rounding = 10,
    Callback = function(Value)
        autoMoveDistance = Value
        print("Auto Move Distance:", Value)
    end
})

SettingsTab:AddSlider("AutoMoveSpeed", {
    Title = "Auto Move Speed",
    Description = "Speed of auto movement (studs/second)",
    Default = 16,
    Min = 5,
    Max = 50,
    Rounding = 1,
    Callback = function(Value)
        autoMoveSpeed = Value
        print("Auto Move Speed:", Value)
    end
})

SettingsTab:AddToggle("TeleportToLastZombie", {
    Title = "Teleport to Last Zombie",
    Description = "Teleport to last zombie after camera teleport",
    Default = teleportToLastZombie,
    Callback = function(Value)
        teleportToLastZombie = Value
        print("Teleport to Last Zombie:", Value and "ON" or "OFF")
    end
})

SettingsTab:AddSlider("CameraOffsetX", {
    Title = "Camera Offset X",
    Description = "Camera X offset position",
    Default = 0,
    Min = -50,
    Max = 50,
    Rounding = 1,
    Callback = function(Value)
        cameraOffsetX = Value
        print("Camera Offset X:", Value)
    end
})

SettingsTab:AddSlider("CameraOffsetY", {
    Title = "Camera Offset Y",
    Description = "Camera Y offset position (height)",
    Default = 10,
    Min = -50,
    Max = 50,
    Rounding = 1,
    Callback = function(Value)
        cameraOffsetY = Value
        print("Camera Offset Y:", Value)
    end
})

SettingsTab:AddSlider("CameraOffsetZ", {
    Title = "Camera Offset Z",
    Description = "Camera Z offset position (distance)",
    Default = -10,
    Min = -50,
    Max = 50,
    Rounding = 1,
    Callback = function(Value)
        cameraOffsetZ = Value
        print("Camera Offset Z:", Value)
    end
})

Window:SelectTab(1)
print("Zombie Hyperloot: Script loaded successfully!")

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
		warn("findTaskPosition: Không tìm thấy Map!")
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
						print("findTaskPosition: Đã tìm thấy Task tại", part.Position)
						return part.Position + Vector3.new(0, 3, 0)
					end
				end
			end
		end
	end
	
	warn("findTaskPosition: Không tìm thấy Task trong bất kỳ Map child nào!")
	return nil
end

-- Tìm vị trí Safe Zone (Map.Model.Decoration.Crane.Model.Part)
local function findSafeZonePosition()
	local map = Workspace:FindFirstChild("Map")
	if not map then 
		warn("findSafeZonePosition: Không tìm thấy Map!")
		return nil 
	end
	
	local model = map:FindFirstChild("Model")
	if not model then 
		warn("findSafeZonePosition: Không tìm thấy Map.Model!")
		return nil 
	end
	
	local decoration = model:FindFirstChild("Decoration")
	if not decoration then 
		warn("findSafeZonePosition: Không tìm thấy Decoration!")
		return nil 
	end
	
	local crane = decoration:FindFirstChild("Crane")
	if not crane then 
		warn("findSafeZonePosition: Không tìm thấy Decoration.Crane!")
		return nil 
	end
	
	local craneModel = crane:FindFirstChild("Model")
	if not craneModel then 
		warn("findSafeZonePosition: Không tìm thấy Decoration.Crane.Model!")
		return nil 
	end
	
	local part = craneModel:FindFirstChild("Part")
	if part and part:IsA("BasePart") then
		print("findSafeZonePosition: Đã tìm thấy Safe Zone tại", part.Position)
		return part.Position + Vector3.new(0, 3, 0)
	else
		warn("findSafeZonePosition: Không tìm thấy Part trong Crane.Model!")
	end
	
	return nil
end

-- Tìm tất cả Exit Door (có thể có nhiều door)
local function findAllExitDoors()
	local doors = {}
	local map = Workspace:FindFirstChild("Map")
	if not map then 
		warn("Không tìm thấy Map!")
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
						print("Tìm thấy ExitDoor:", child.Name, "tại", targetPart.Position)
					else
						warn("ExitDoor", child.Name, "không có BasePart hợp lệ!")
					end
				end
			end
		end
	end
	
	-- Debug: In ra số lượng door tìm được
	if #doors > 0 then
		print("Đã tìm thấy", #doors, "Exit Door(s)")
	else
		warn("Không tìm thấy Exit Door nào!")
	end
	
	return doors
end

-- Tìm tất cả Supply Piles (chỗ lấy đạn)
local function findAllSupplyPiles()
	local supplies = {}
	local map = Workspace:FindFirstChild("Map")
	if not map then 
		warn("findAllSupplyPiles: Không tìm thấy Map!")
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
	
	if #uniqueSupplies > 0 then
		print("findAllSupplyPiles: Đã tìm thấy", #uniqueSupplies, "Supply Pile(s)")
	else
		warn("findAllSupplyPiles: Không tìm thấy Supply Pile nào trong bất kỳ Map child nào!")
	end
	
	return uniqueSupplies
end

-- Tìm tất cả Ammo (đạn)
local function findAllAmmo()
	local ammos = {}
	local map = Workspace:FindFirstChild("Map")
	if not map then 
		warn("findAllAmmo: Không tìm thấy Map!")
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
	
	if #uniqueAmmos > 0 then
		print("findAllAmmo: Đã tìm thấy", #uniqueAmmos, "Ammo(s)")
	else
		warn("findAllAmmo: Không tìm thấy Ammo nào trong bất kỳ Map child nào!")
	end
	
	return uniqueAmmos
end

-- Hàm teleport
local function teleportToPosition(position)
	if not position then
		print("Không tìm thấy vị trí!")
		return
	end
	
	local char = localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		print("Không tìm thấy nhân vật!")
		return
	end
	
	hrp.CFrame = CFrame.new(position)
	print("Đã teleport tới vị trí:", position)
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
				print("Map đã load hoàn toàn!")
				task.wait(0.5) -- Đợi thêm một chút để chắc chắn
				break
			end
		end
		task.wait(0.5)
		waited = waited + 0.5
	end
end

waitForMapLoad(10) -- Đợi tối đa 10 giây

-- Debug: In ra cấu trúc Map để kiểm tra
local map = Workspace:FindFirstChild("Map")
if map then
	print("=== DEBUG: Cấu trúc Map ===")
	print("Số lượng children của Map:", #map:GetChildren())
	for i, mapChild in ipairs(map:GetChildren()) do
		print("Map[" .. i .. "]:", mapChild.Name, "(" .. mapChild.ClassName .. ")")
		local eItem = mapChild:FindFirstChild("EItem")
		if eItem then
			print("  └─ EItem tìm thấy trong", mapChild.Name)
			-- In ra một vài children của EItem để debug
			local eItemChildren = eItem:GetChildren()
			print("  └─ EItem có", #eItemChildren, "children")
			for j, child in ipairs(eItemChildren) do
				if j <= 5 then -- Chỉ in 5 children đầu tiên
					print("    └─", child.Name, "(" .. child.ClassName .. ")")
				end
			end
			if #eItemChildren > 5 then
				print("    ... và", #eItemChildren - 5, "children khác")
			end
		end
	end
	print("=== END DEBUG ===")
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
					print("Tìm thấy", #doors, "door(s), teleport tới door gần nhất")
				end
			else
				print("Không tìm thấy Exit Door!")
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
				print("Teleport tới Supply Pile", i)
			else
				print("Supply Pile", i, "không còn tồn tại!")
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
				print("Teleport tới Ammo", i)
			else
				print("Ammo", i, "không còn tồn tại!")
			end
		end)
	end
	
	currentButtonCount = buttonLayoutOrder - 1
	
	-- Cập nhật kích thước container dựa trên số button
	if currentButtonCount > 0 then
		Container.Size = UDim2.new(0, 160, 0, currentButtonCount * 40 + 20)
		Container.Position = UDim2.new(1, -180, 0.5, -(currentButtonCount * 40 + 20) / 2)
		Container.Visible = true
		print("Quick Teleport Buttons đã được cập nhật! (" .. currentButtonCount .. " button(s))")
	else
		Container.Visible = false
		print("Không tìm thấy vị trí teleport nào!")
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