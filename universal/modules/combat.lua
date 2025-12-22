--[[
    Combat Module - Universal Script
    Tab Combat - Aimbot, Hitbox, Crosshair, Auto Shoot, Trigger Bot
]]

local Combat = {}
local Config = nil
local UI = nil

-- Variables
local aimbotTarget = nil
local aimbotFOVCircle = nil
local holdingMouse2 = false
local hitboxOriginals = {}
local autoShootConnection
local lastAutoShootTime = 0
local crosshairLines = {}
local crosshairDot = nil
local hasDrawingAPI = false
local mainRenderConnection = nil

----------------------------------------------------------
-- 🔹 Initialize
function Combat.init(config, ui)
	Config = config
	UI = ui
end

----------------------------------------------------------
-- 🔹 Check Drawing API
local function checkDrawingAPI()
	if not hasDrawingAPI then
		local ok, obj = pcall(function() return Drawing.new("Circle") end)
		if ok and obj then
			hasDrawingAPI = true
			obj:Remove()
		end
	end
	return hasDrawingAPI
end

----------------------------------------------------------
-- 🔹 Aimbot Functions
local function initFOVCircle()
	if not checkDrawingAPI() then return end
	
	if not aimbotFOVCircle then
		aimbotFOVCircle = Drawing.new("Circle")
		aimbotFOVCircle.Thickness = 1.5
		aimbotFOVCircle.NumSides = 64
		aimbotFOVCircle.Filled = false
		aimbotFOVCircle.Visible = false
		aimbotFOVCircle.Color = Color3.fromRGB(0, 255, 0)
		aimbotFOVCircle.Radius = 150
	end
end

local function isTargetVisible(targetPart)
	if not UI.Toggles.AimbotVisibleCheck.Value then return true end
	if not targetPart or not Config.rootPart then return false end
	
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {Config.character, targetPart.Parent}
	
	local direction = (targetPart.Position - Config.Camera.CFrame.Position)
	local result = Config.Workspace:Raycast(Config.Camera.CFrame.Position, direction, rayParams)
	
	return result == nil
end

local function getAimbotTargets()
	local targets = {}
	local mode = UI.Options.AimbotTargetType and UI.Options.AimbotTargetType.Value or "Players"
	
	if mode == "Players" or mode == "All" then
		for _, player in ipairs(Config.Players:GetPlayers()) do
			if player ~= Config.LocalPlayer and player.Character then
				local hum = player.Character:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					-- Team check
					if not (UI.Toggles.AimbotTeamCheck.Value and player.Team == Config.LocalPlayer.Team) then
						table.insert(targets, {char = player.Character, isPlayer = true, player = player})
					end
				end
			end
		end
	end
	
	if (mode == "NPCs" or mode == "All") and Config.EntityFolder then
		for _, model in ipairs(Config.EntityFolder:GetChildren()) do
			if model:IsA("Model") then
				local hum = model:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					table.insert(targets, {char = model, isPlayer = false})
				end
			end
		end
	end
	
	return targets
end

local function getClosestAimbotTarget()
	local mousePos = Config.UserInputService:GetMouseLocation()
	local fovRadius = UI.Options.AimbotFOV and UI.Options.AimbotFOV.Value or 150
	local targetPartName = UI.Options.AimbotTargetPart and UI.Options.AimbotTargetPart.Value or "Head"
	
	local closestTarget = nil
	local closestPart = nil
	local closestDist = fovRadius
	
	for _, targetData in ipairs(getAimbotTargets()) do
		local char = targetData.char
		if char then
			-- Try to find target part
			local part = char:FindFirstChild(targetPartName)
			-- Fallback parts
			if not part then
				part = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
			end
			
			if part then
				local screenPos, onScreen = Config.Camera:WorldToViewportPoint(part.Position)
				if onScreen and screenPos.Z > 0 then
					local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
					if dist < closestDist then
						-- Visibility check
						if isTargetVisible(part) then
							closestDist = dist
							closestTarget = char
							closestPart = part
						end
					end
				end
			end
		end
	end
	
	return closestTarget, closestPart
end

----------------------------------------------------------
-- 🔹 Hitbox Functions
local function getHitboxTargets()
	local targets = {}
	local mode = UI.Options.HitboxTarget and UI.Options.HitboxTarget.Value or "Players"
	
	if mode == "Players" or mode == "All" then
		for _, player in ipairs(Config.Players:GetPlayers()) do
			if player ~= Config.LocalPlayer and player.Character then
				local hum = player.Character:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					table.insert(targets, player.Character)
				end
			end
		end
	end
	
	if (mode == "NPCs" or mode == "All") and Config.EntityFolder then
		for _, model in ipairs(Config.EntityFolder:GetChildren()) do
			if model:IsA("Model") then
				local hum = model:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					table.insert(targets, model)
				end
			end
		end
	end
	
	return targets
end

local function resetHitbox()
	for part, original in pairs(hitboxOriginals) do
		if part and part.Parent then
			part.Size = original.Size
			part.CanCollide = original.CanCollide
			part.Transparency = original.Transparency
			if original.Color then
				part.Color = original.Color
			end
		end
	end
	hitboxOriginals = {}
end

local function applyHitbox()
	if not UI.Toggles.Hitbox.Value then
		resetHitbox()
		return
	end
	
	local sizeValue = UI.Options.HitboxSize and UI.Options.HitboxSize.Value or 10
	local modePart = UI.Options.HitboxPart and UI.Options.HitboxPart.Value or "HumanoidRootPart"
	
	for _, character in ipairs(getHitboxTargets()) do
		local parts = {}
		if modePart == "All" then
			for _, name in ipairs({ "Head", "HumanoidRootPart", "UpperTorso" }) do
				local p = character:FindFirstChild(name)
				if p and p:IsA("BasePart") then
					table.insert(parts, p)
				end
			end
		else
			local p = character:FindFirstChild(modePart)
			if p and p:IsA("BasePart") then
				table.insert(parts, p)
			end
		end
		
		for _, part in ipairs(parts) do
			if not hitboxOriginals[part] then
				hitboxOriginals[part] = {
					Size = part.Size,
					CanCollide = part.CanCollide,
					Transparency = part.Transparency,
					Color = part.Color,
				}
			end
			part.Size = Vector3.new(sizeValue, sizeValue, sizeValue)
			part.CanCollide = false
			part.Transparency = 0.7
			if UI.Options.HitboxColor then
				part.Color = UI.Options.HitboxColor.Value
			end
		end
	end
end

----------------------------------------------------------
-- 🔹 Crosshair Functions
local function createCrosshair()
	if not checkDrawingAPI() then return end
	
	-- Tạo 4 đường kẻ (trên, dưới, trái, phải)
	for i = 1, 4 do
		if not crosshairLines[i] then
			crosshairLines[i] = Drawing.new("Line")
			crosshairLines[i].Visible = false
			crosshairLines[i].Thickness = 1
			crosshairLines[i].Color = Color3.fromRGB(255, 255, 255)
		end
	end
	
	-- Tạo điểm ở giữa
	if not crosshairDot then
		crosshairDot = Drawing.new("Circle")
		crosshairDot.Visible = false
		crosshairDot.Thickness = 1
		crosshairDot.Filled = true
		crosshairDot.Radius = 2
		crosshairDot.Color = Color3.fromRGB(255, 255, 255)
	end
end

local function updateCrosshair()
	if not UI.Toggles.CrosshairEnabled or not UI.Toggles.CrosshairEnabled.Value then
		for _, line in ipairs(crosshairLines) do
			if line then line.Visible = false end
		end
		if crosshairDot then crosshairDot.Visible = false end
		return
	end
	
	if not checkDrawingAPI() then
		createCrosshair()
		return
	end
	
	local screenSize = Config.Camera.ViewportSize
	local centerX = screenSize.X / 2
	local centerY = screenSize.Y / 2
	
	local size = UI.Options.CrosshairSize and UI.Options.CrosshairSize.Value or 10
	local thickness = UI.Options.CrosshairThickness and UI.Options.CrosshairThickness.Value or 1
	local color = UI.Options.CrosshairColor and UI.Options.CrosshairColor.Value or Color3.fromRGB(255, 255, 255)
	
	-- Vẽ 4 đường kẻ
	-- Trên
	if crosshairLines[1] then
		crosshairLines[1].Visible = true
		crosshairLines[1].From = Vector2.new(centerX, centerY - size - 2)
		crosshairLines[1].To = Vector2.new(centerX, centerY - 2)
		crosshairLines[1].Thickness = thickness
		crosshairLines[1].Color = color
	end
	
	-- Dưới
	if crosshairLines[2] then
		crosshairLines[2].Visible = true
		crosshairLines[2].From = Vector2.new(centerX, centerY + 2)
		crosshairLines[2].To = Vector2.new(centerX, centerY + size + 2)
		crosshairLines[2].Thickness = thickness
		crosshairLines[2].Color = color
	end
	
	-- Trái
	if crosshairLines[3] then
		crosshairLines[3].Visible = true
		crosshairLines[3].From = Vector2.new(centerX - size - 2, centerY)
		crosshairLines[3].To = Vector2.new(centerX - 2, centerY)
		crosshairLines[3].Thickness = thickness
		crosshairLines[3].Color = color
	end
	
	-- Phải
	if crosshairLines[4] then
		crosshairLines[4].Visible = true
		crosshairLines[4].From = Vector2.new(centerX + 2, centerY)
		crosshairLines[4].To = Vector2.new(centerX + size + 2, centerY)
		crosshairLines[4].Thickness = thickness
		crosshairLines[4].Color = color
	end
	
	-- Điểm ở giữa
	if crosshairDot then
		crosshairDot.Visible = UI.Toggles.CrosshairDot and UI.Toggles.CrosshairDot.Value or false
		crosshairDot.Position = Vector2.new(centerX, centerY)
		crosshairDot.Color = color
	end
end

----------------------------------------------------------
-- 🔹 Create Tab
function Combat.createTab()
	local AimbotGroup = UI.Tabs.Combat:AddLeftGroupbox("Aimbot", "crosshair")
	
	AimbotGroup:AddToggle("AimbotEnabled", {
		Text = "Aimbot",
		Default = false,
		Tooltip = "Enable aimbot",
	})
	
	AimbotGroup:AddToggle("AimbotFOVShow", {
		Text = "Show FOV Circle",
		Default = true,
	})
	
	AimbotGroup:AddSlider("AimbotFOV", {
		Text = "FOV Radius",
		Default = 150,
		Min = 50,
		Max = 500,
		Rounding = 0,
	})
	
	AimbotGroup:AddSlider("AimbotSmoothness", {
		Text = "Smoothness",
		Default = 0.1,
		Min = 0,
		Max = 0.9,
		Rounding = 2,
		Tooltip = "0 = instant, higher = smoother",
	})
	
	AimbotGroup:AddSlider("AimbotPrediction", {
		Text = "Prediction",
		Default = 0,
		Min = 0,
		Max = 0.3,
		Rounding = 3,
		Tooltip = "Predict target movement",
	})
	
	AimbotGroup:AddDropdown("AimbotTargetType", {
		Values = { "Players", "NPCs", "All" },
		Default = 1,
		Text = "Target Type",
	})
	
	AimbotGroup:AddDropdown("AimbotTargetPart", {
		Values = { "Head", "HumanoidRootPart", "UpperTorso", "Torso" },
		Default = 1,
		Text = "Target Part",
	})
	
	AimbotGroup:AddToggle("AimbotTeamCheck", {
		Text = "Team Check",
		Default = false,
		Tooltip = "Don't target teammates",
	})
	
	AimbotGroup:AddToggle("AimbotHoldMouse2", {
		Text = "Hold Right Click",
		Default = false,
		Tooltip = "Only aim when holding right mouse button",
	})
	
	AimbotGroup:AddToggle("AimbotVisibleCheck", {
		Text = "Visibility Check",
		Default = false,
		Tooltip = "Only target visible enemies",
	})
	
	AimbotGroup:AddLabel("FOV Color"):AddColorPicker("AimbotFOVColor", {
		Default = Color3.fromRGB(0, 255, 0),
		Title = "FOV Circle Color",
	})
	
	AimbotGroup:AddDivider()
	
	-- Crosshair (Tâm Ảo - Điểm tâm ở giữa màn hình)
	AimbotGroup:AddToggle("CrosshairEnabled", {
		Text = "Crosshair (Tâm Ảo)",
		Default = false,
		Tooltip = "Hiển thị crosshair/điểm tâm ở giữa màn hình",
	})
	
	AimbotGroup:AddSlider("CrosshairSize", {
		Text = "Crosshair Size",
		Default = 10,
		Min = 5,
		Max = 50,
		Rounding = 0,
		Tooltip = "Kích thước crosshair",
	})
	
	AimbotGroup:AddSlider("CrosshairThickness", {
		Text = "Crosshair Thickness",
		Default = 1,
		Min = 1,
		Max = 5,
		Rounding = 0,
		Tooltip = "Độ dày đường kẻ",
	})
	
	AimbotGroup:AddToggle("CrosshairDot", {
		Text = "Show Center Dot",
		Default = true,
		Tooltip = "Hiển thị điểm ở giữa",
	})
	
	AimbotGroup:AddLabel("Crosshair Color"):AddColorPicker("CrosshairColor", {
		Default = Color3.fromRGB(255, 255, 255),
		Title = "Crosshair Color",
	})
	
	-- Auto Shoot
	AimbotGroup:AddToggle("AutoShootEnabled", {
		Text = "Auto Shoot",
		Default = false,
		Tooltip = "Tự động bắn khi có target trong FOV",
		Risky = true,
	})
	
	AimbotGroup:AddSlider("AutoShootDelay", {
		Text = "Auto Shoot Delay (ms)",
		Default = 100,
		Min = 0,
		Max = 1000,
		Rounding = 0,
		Tooltip = "Độ trễ giữa các lần bắn",
	})
	
	-- Trigger Bot
	AimbotGroup:AddToggle("TriggerBotEnabled", {
		Text = "Trigger Bot",
		Default = false,
		Tooltip = "Tự động bắn khi crosshair trên target",
		Risky = true,
	})
	
	AimbotGroup:AddSlider("TriggerBotDelay", {
		Text = "Trigger Bot Delay (ms)",
		Default = 50,
		Min = 0,
		Max = 500,
		Rounding = 0,
		Tooltip = "Độ trễ trước khi bắn",
	})
	
	-- Hitbox Group
	local CombatGroup = UI.Tabs.Combat:AddRightGroupbox("Hitbox", "target")
	
	CombatGroup:AddToggle("Hitbox", {
		Text = "Hitbox",
		Default = false,
		Tooltip = "Expand target hitbox",
		Risky = true,
	})
	
	CombatGroup:AddSlider("HitboxSize", {
		Text = "Hitbox Size",
		Default = 10,
		Min = 5,
		Max = 30,
		Rounding = 0,
	})
	
	CombatGroup:AddLabel("Hitbox Color"):AddColorPicker("HitboxColor", {
		Default = Color3.fromRGB(255, 0, 0),
		Title = "Hitbox Color",
	})
	
	CombatGroup:AddDropdown("HitboxTarget", {
		Values = { "Players", "NPCs", "All" },
		Default = 1,
		Text = "Target Type",
	})
	
	CombatGroup:AddDropdown("HitboxPart", {
		Values = { "Head", "HumanoidRootPart", "UpperTorso", "All" },
		Default = 2,
		Text = "Hitbox Part",
	})
	
	-- Mouse input for hold right click
	Config.UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			holdingMouse2 = true
		end
	end)
	
	Config.UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			holdingMouse2 = false
		end
	end)
	
	-- Initialize FOV Circle
	initFOVCircle()
	
	-- Initialize Crosshair
	createCrosshair()
	
	-- Hitbox Loop
	Config.RunService.Heartbeat:Connect(function()
		if UI.Toggles.Hitbox.Value then
			applyHitbox()
		end
	end)
	
	-- Main Render Loop (Aimbot, Crosshair, Trigger Bot)
	mainRenderConnection = Config.RunService.RenderStepped:Connect(function()
		-- Aimbot Update
		local mousePos = Config.UserInputService:GetMouseLocation()
		
		-- Update FOV Circle
		if aimbotFOVCircle then
			aimbotFOVCircle.Position = mousePos
			aimbotFOVCircle.Radius = UI.Options.AimbotFOV and UI.Options.AimbotFOV.Value or 150
			aimbotFOVCircle.Visible = UI.Toggles.AimbotEnabled.Value and UI.Toggles.AimbotFOVShow.Value
			aimbotFOVCircle.Color = UI.Options.AimbotFOVColor and UI.Options.AimbotFOVColor.Value or Color3.fromRGB(0, 255, 0)
		end
		
		-- Aimbot Logic
		if UI.Toggles.AimbotEnabled.Value then
			local active = true
			if UI.Toggles.AimbotHoldMouse2.Value and not holdingMouse2 then
				active = false
			end
			
			if active then
				local targetChar, targetPart = getClosestAimbotTarget()
				if targetChar and targetPart then
					local targetPos = targetPart.Position
					
					-- Prediction
					local prediction = UI.Options.AimbotPrediction and UI.Options.AimbotPrediction.Value or 0
					if prediction > 0 then
						local vel = targetPart.AssemblyLinearVelocity or targetPart.Velocity or Vector3.new(0, 0, 0)
						targetPos = targetPos + (vel * prediction)
					end
					
					local cf = Config.Camera.CFrame
					local desired = CFrame.new(cf.Position, targetPos)
					
					-- Smoothness
					local smoothness = UI.Options.AimbotSmoothness and UI.Options.AimbotSmoothness.Value or 0.1
					if smoothness > 0 then
						local alpha = 1 - smoothness
						alpha = math.min(math.max(alpha, 0.01), 1)
						Config.Camera.CFrame = cf:Lerp(desired, alpha)
					else
						Config.Camera.CFrame = desired
					end
					
					-- Change FOV color when locked
					if aimbotFOVCircle then
						aimbotFOVCircle.Color = Color3.fromRGB(255, 0, 0)
					end
				else
					-- Reset FOV color
					if aimbotFOVCircle then
						aimbotFOVCircle.Color = UI.Options.AimbotFOVColor and UI.Options.AimbotFOVColor.Value or Color3.fromRGB(0, 255, 0)
					end
				end
			end
		end
		
		-- Trigger Bot Logic
		if UI.Toggles.TriggerBotEnabled and UI.Toggles.TriggerBotEnabled.Value then
			local mousePos = Config.UserInputService:GetMouseLocation()
			local targetChar, targetPart = getClosestAimbotTarget()
			
			if targetChar and targetPart then
				local screenPos, onScreen = Config.Camera:WorldToViewportPoint(targetPart.Position)
				if onScreen and screenPos.Z > 0 then
					local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
					-- Nếu crosshair gần target (trong vòng 20 pixels)
					if dist < 20 then
						local delay = UI.Options.TriggerBotDelay and UI.Options.TriggerBotDelay.Value or 50
						task.spawn(function()
							task.wait(delay / 1000)
							pcall(Config.mouse1click)
						end)
					end
				end
			end
		end
		
		-- Update Crosshair (Tâm Ảo)
		updateCrosshair()
	end)
	
	-- Auto Shoot Logic
	UI.Toggles.AutoShootEnabled:OnChanged(function()
		if UI.Toggles.AutoShootEnabled.Value then
			autoShootConnection = Config.RunService.Heartbeat:Connect(function()
				local currentTime = tick()
				local delay = UI.Options.AutoShootDelay and UI.Options.AutoShootDelay.Value or 100
				
				if currentTime - lastAutoShootTime >= (delay / 1000) then
					local targetChar, targetPart = getClosestAimbotTarget()
					
					if targetChar and targetPart then
						-- Kiểm tra FOV
						local fov = UI.Options.AimbotFOV and UI.Options.AimbotFOV.Value or 150
						local mousePos = Config.UserInputService:GetMouseLocation()
						local screenPos, onScreen = Config.Camera:WorldToViewportPoint(targetPart.Position)
						
						if onScreen and screenPos.Z > 0 then
							local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
							if dist <= fov then
								-- Auto shoot
								pcall(Config.mouse1click)
								lastAutoShootTime = currentTime
							end
						end
					end
				end
			end)
		else
			if autoShootConnection then
				autoShootConnection:Disconnect()
				autoShootConnection = nil
			end
			lastAutoShootTime = 0
		end
	end)
end

----------------------------------------------------------
-- 🔹 Cleanup
function Combat.cleanup()
	-- Disconnect main render loop
	if mainRenderConnection then
		mainRenderConnection:Disconnect()
		mainRenderConnection = nil
	end
	
	-- Cleanup Aimbot FOV Circle
	if aimbotFOVCircle then
		aimbotFOVCircle.Visible = false
		pcall(function() aimbotFOVCircle:Remove() end)
		aimbotFOVCircle = nil
	end
	
	-- Cleanup Crosshair (Tâm Ảo)
	for _, line in ipairs(crosshairLines) do
		if line then
			line.Visible = false
			pcall(function() line:Remove() end)
		end
	end
	crosshairLines = {}
	if crosshairDot then
		crosshairDot.Visible = false
		pcall(function() crosshairDot:Remove() end)
		crosshairDot = nil
	end
	
	-- Cleanup Auto Shoot
	if autoShootConnection then
		autoShootConnection:Disconnect()
		autoShootConnection = nil
	end
	
	-- Reset Hitbox
	resetHitbox()
end

return Combat

