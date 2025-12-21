-- Universal Script với Obsidian UI
-- Script này hoạt động trên mọi game Roblox

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")

-- Player
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local EntityFolder = Workspace:FindFirstChild("Entity")

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
	Title = "WiniFy",
	Footer = "version: 1.0.0",
	NotifySide = "Right",
	ShowCustomCursor = true,
})

local Tabs = {
	Main = Window:AddTab("Main", "user"),
	Combat = Window:AddTab("Combat", "sword"),
	Visuals = Window:AddTab("Visuals", "eye"),
	Teleport = Window:AddTab("Teleport", "map-pin"),
	Server = Window:AddTab("Server", "server"),
	Misc = Window:AddTab("Misc", "settings"),
	["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

-- Variables
local character, humanoid, rootPart
local noclipConnection
local hitboxOriginals = {}
local wsLoopConnection
local wsCharAddedConnection
local jpLoopConnection
local jpCharAddedConnection

-- HipHeight Variables
local hipHeightConnection = nil
local hipHeightCharConnection = nil
local originalHipHeight = nil
local targetYPosition = nil

-- ESP Variables
local espObjects = {}
local espHighlights = {}
local hasDrawingAPI = false



-- Get Character
local function getCharacter()
	character = LocalPlayer.Character
	if character then
		humanoid = character:FindFirstChildOfClass("Humanoid")
		rootPart = character:FindFirstChild("HumanoidRootPart")
	end
	return character, humanoid, rootPart
end

-- Character Added
LocalPlayer.CharacterAdded:Connect(function()
	getCharacter()
end)
getCharacter()

-- ============================================
-- MAIN TAB - Movement
-- ============================================
local MovementGroup = Tabs.Main:AddLeftGroupbox("Movement", "move")

MovementGroup:AddToggle("SpeedHack", {
	Text = "Speed Hack",
	Default = false,
	Tooltip = "Increase movement speed",
})

MovementGroup:AddSlider("SpeedValue", {
	Text = "Speed Value",
	Default = 16,
	Min = 1,
	Max = 500,
	Rounding = 0,
})

MovementGroup:AddToggle("JumpPower", {
	Text = "Jump Power",
	Default = false,
	Tooltip = "Increase jump power",
})

MovementGroup:AddSlider("JumpValue", {
	Text = "Jump Value",
	Default = 50,
	Min = 1,
	Max = 500,
	Rounding = 0,
})

MovementGroup:AddToggle("Noclip", {
	Text = "Noclip",
	Default = false,
	Tooltip = "Walk through walls",
})

MovementGroup:AddToggle("HipHeight", {
	Text = "Hip Height (Fly)",
	Default = false,
	Tooltip = "Float at a fixed height above ground",
})

MovementGroup:AddSlider("HipHeightValue", {
	Text = "Height Value",
	Default = 20,
	Min = 1,
	Max = 200,
	Rounding = 0,
})

MovementGroup:AddToggle("InfiniteJump", {
	Text = "Infinite Jump",
	Default = false,
	Tooltip = "Infinite jumps",
})

-- Speed Hack (loopspeed style)
local function applyWalkSpeed()
	if humanoid and Toggles.SpeedHack.Value then
		humanoid.WalkSpeed = Options.SpeedValue.Value
	end
end

local function setupWalkSpeedLoop()
	if not humanoid then return end

	if wsLoopConnection then
		wsLoopConnection:Disconnect()
		wsLoopConnection = nil
	end

	wsLoopConnection = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		if Toggles.SpeedHack.Value then
			applyWalkSpeed()
		end
	end)

	if wsCharAddedConnection then
		wsCharAddedConnection:Disconnect()
		wsCharAddedConnection = nil
	end

	wsCharAddedConnection = LocalPlayer.CharacterAdded:Connect(function()
		getCharacter()
		applyWalkSpeed()
		if humanoid then
			if wsLoopConnection then
				wsLoopConnection:Disconnect()
				wsLoopConnection = nil
			end
			wsLoopConnection = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
				if Toggles.SpeedHack.Value then
					applyWalkSpeed()
				end
			end)
		end
	end)
end

Toggles.SpeedHack:OnChanged(function()
	if Toggles.SpeedHack.Value then
		applyWalkSpeed()
		setupWalkSpeedLoop()
	else
		if wsLoopConnection then
			wsLoopConnection:Disconnect()
			wsLoopConnection = nil
		end
		if wsCharAddedConnection then
			wsCharAddedConnection:Disconnect()
			wsCharAddedConnection = nil
		end
		if humanoid then
			humanoid.WalkSpeed = 16
		end
	end
end)

Options.SpeedValue:OnChanged(function()
	if Toggles.SpeedHack.Value then
		applyWalkSpeed()
	end
end)

-- Jump Power (loop style giống SpeedHack)
local function applyJumpPower()
	if humanoid and Toggles.JumpPower.Value then
		humanoid.JumpPower = Options.JumpValue.Value
	end
end

local function setupJumpPowerLoop()
	if not humanoid then return end

	if jpLoopConnection then
		jpLoopConnection:Disconnect()
		jpLoopConnection = nil
	end

	jpLoopConnection = humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
		if Toggles.JumpPower.Value then
			applyJumpPower()
		end
	end)

	if jpCharAddedConnection then
		jpCharAddedConnection:Disconnect()
		jpCharAddedConnection = nil
	end

	jpCharAddedConnection = LocalPlayer.CharacterAdded:Connect(function()
		getCharacter()
		applyJumpPower()
		if humanoid then
			if jpLoopConnection then
				jpLoopConnection:Disconnect()
				jpLoopConnection = nil
			end
			jpLoopConnection = humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
				if Toggles.JumpPower.Value then
					applyJumpPower()
				end
			end)
		end
	end)
end

Toggles.JumpPower:OnChanged(function()
	if Toggles.JumpPower.Value then
		applyJumpPower()
		setupJumpPowerLoop()
	else
		if jpLoopConnection then
			jpLoopConnection:Disconnect()
			jpLoopConnection = nil
		end
		if jpCharAddedConnection then
			jpCharAddedConnection:Disconnect()
			jpCharAddedConnection = nil
		end
		if humanoid then
			humanoid.JumpPower = 50
		end
	end
end)

Options.JumpValue:OnChanged(function()
	if Toggles.JumpPower.Value then
		applyJumpPower()
	end
end)

-- Noclip
Toggles.Noclip:OnChanged(function()
	if Toggles.Noclip.Value then
		if noclipConnection then
			noclipConnection:Disconnect()
		end
		noclipConnection = RunService.Stepped:Connect(function()
			if character then
				for _, part in pairs(character:GetDescendants()) do
					if part:IsA("BasePart") and part.CanCollide then
						part.CanCollide = false
					end
				end
			end
		end)
	else
		if noclipConnection then
			noclipConnection:Disconnect()
			noclipConnection = nil
		end
		if character then
			for _, part in pairs(character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = true
				end
			end
		end
	end
end)

-- HipHeight (Float at fixed height)
local function getGroundY()
	if not rootPart then return 0 end
	
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {character}
	
	-- Raycast xuống để tìm mặt đất
	local rayOrigin = rootPart.Position
	local rayDirection = Vector3.new(0, -500, 0)
	local result = Workspace:Raycast(rayOrigin, rayDirection, rayParams)
	
	if result then
		return result.Position.Y
	end
	return 0
end

local function applyHipHeight()
	if not humanoid or not rootPart then return end
	
	if Toggles.HipHeight.Value then
		local heightValue = Options.HipHeightValue and Options.HipHeightValue.Value or 20
		
		-- Lưu original hip height
		if originalHipHeight == nil then
			originalHipHeight = humanoid.HipHeight
		end
		
		-- Set hip height
		humanoid.HipHeight = heightValue
		
		-- Tính toán vị trí Y mục tiêu (mặt đất + height + offset cho character)
		local groundY = getGroundY()
		local characterHeight = 3 -- Chiều cao cơ bản của character
		targetYPosition = groundY + heightValue + characterHeight
	end
end

local function setupHipHeightLoop()
	if hipHeightConnection then
		hipHeightConnection:Disconnect()
		hipHeightConnection = nil
	end
	
	hipHeightConnection = RunService.Heartbeat:Connect(function()
		if not Toggles.HipHeight.Value then return end
		if not rootPart or not humanoid then return end
		
		local heightValue = Options.HipHeightValue and Options.HipHeightValue.Value or 20
		
		-- Enforce hip height liên tục
		if humanoid.HipHeight ~= heightValue then
			humanoid.HipHeight = heightValue
		end
		
		-- Giữ vị trí Y cố định (không rơi)
		local groundY = getGroundY()
		local characterHeight = 3
		local targetY = groundY + heightValue + characterHeight
		
		local currentPos = rootPart.Position
		local currentVel = rootPart.AssemblyLinearVelocity or rootPart.Velocity
		
		-- Nếu đang rơi hoặc vị trí Y khác target, điều chỉnh
		if math.abs(currentPos.Y - targetY) > 0.5 then
			rootPart.CFrame = CFrame.new(currentPos.X, targetY, currentPos.Z) * (rootPart.CFrame - rootPart.CFrame.Position)
		end
		
		-- Tắt gravity effect bằng cách set velocity Y = 0
		if currentVel.Y < -1 then
			rootPart.AssemblyLinearVelocity = Vector3.new(currentVel.X, 0, currentVel.Z)
		end
	end)
	
	-- Character respawn handler
	if hipHeightCharConnection then
		hipHeightCharConnection:Disconnect()
		hipHeightCharConnection = nil
	end
	
	hipHeightCharConnection = LocalPlayer.CharacterAdded:Connect(function()
		getCharacter()
		originalHipHeight = nil
		task.wait(0.5)
		if Toggles.HipHeight.Value then
			applyHipHeight()
		end
	end)
end

local function disableHipHeight()
	if hipHeightConnection then
		hipHeightConnection:Disconnect()
		hipHeightConnection = nil
	end
	
	if hipHeightCharConnection then
		hipHeightCharConnection:Disconnect()
		hipHeightCharConnection = nil
	end
	
	-- Restore original hip height
	if humanoid and originalHipHeight ~= nil then
		humanoid.HipHeight = originalHipHeight
	end
	originalHipHeight = nil
	targetYPosition = nil
end

Toggles.HipHeight:OnChanged(function()
	if Toggles.HipHeight.Value then
		applyHipHeight()
		setupHipHeightLoop()
	else
		disableHipHeight()
	end
end)

Options.HipHeightValue:OnChanged(function()
	if Toggles.HipHeight.Value then
		applyHipHeight()
	end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
	if Toggles.InfiniteJump.Value and humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

-- ============================================
-- COMBAT TAB
-- ============================================

-- Aimbot Variables
local aimbotTarget = nil
local aimbotFOVCircle = nil
local holdingMouse2 = false

local AimbotGroup = Tabs.Combat:AddLeftGroupbox("Aimbot", "crosshair")

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

-- Aimbot Functions
local function initFOVCircle()
	if not hasDrawingAPI then
		local ok, obj = pcall(function() return Drawing.new("Circle") end)
		if ok and obj then
			hasDrawingAPI = true
			obj:Remove()
		end
	end
	
	if hasDrawingAPI and not aimbotFOVCircle then
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
	if not Toggles.AimbotVisibleCheck.Value then return true end
	if not targetPart or not rootPart then return false end
	
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {character, targetPart.Parent}
	
	local direction = (targetPart.Position - Camera.CFrame.Position)
	local result = Workspace:Raycast(Camera.CFrame.Position, direction, rayParams)
	
	return result == nil
end

local function getAimbotTargets()
	local targets = {}
	local mode = Options.AimbotTargetType and Options.AimbotTargetType.Value or "Players"
	
	if mode == "Players" or mode == "All" then
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character then
				local hum = player.Character:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					-- Team check
					if Toggles.AimbotTeamCheck.Value and player.Team == LocalPlayer.Team then
						continue
					end
					table.insert(targets, {char = player.Character, isPlayer = true, player = player})
				end
			end
		end
	end
	
	if (mode == "NPCs" or mode == "All") and EntityFolder then
		for _, model in ipairs(EntityFolder:GetChildren()) do
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
	local mousePos = UserInputService:GetMouseLocation()
	local fovRadius = Options.AimbotFOV and Options.AimbotFOV.Value or 150
	local targetPartName = Options.AimbotTargetPart and Options.AimbotTargetPart.Value or "Head"
	
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
				local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
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

-- Mouse input for hold right click
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

-- Initialize FOV Circle
initFOVCircle()

local CombatGroup = Tabs.Combat:AddRightGroupbox("Hitbox", "target")

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



-- Hitbox
local function getHitboxTargets()
	local targets = {}
	local mode = Options.HitboxTarget and Options.HitboxTarget.Value or "Players"

	if mode == "Players" or mode == "All" then
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character then
				local hum = player.Character:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					table.insert(targets, player.Character)
				end
			end
		end
	end

	if (mode == "NPCs" or mode == "All") and EntityFolder then
		for _, model in ipairs(EntityFolder:GetChildren()) do
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
	if not Toggles.Hitbox.Value then
		resetHitbox()
		return
	end

	local sizeValue = Options.HitboxSize and Options.HitboxSize.Value or 10
	local modePart = Options.HitboxPart and Options.HitboxPart.Value or "HumanoidRootPart"

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
			if Options.HitboxColor then
				part.Color = Options.HitboxColor.Value
			end
		end
	end
end

RunService.Heartbeat:Connect(function()
	applyHitbox()
end)





local VisualsGroup = Tabs.Visuals:AddLeftGroupbox("Visuals", "sun")

VisualsGroup:AddToggle("FullBright", {
	Text = "Full Bright",
	Default = false,
	Tooltip = "Make the map fully bright",
})

VisualsGroup:AddToggle("NoFog", {
	Text = "No Fog",
	Default = false,
	Tooltip = "Disable fog",
})

-- ESP Group
local ESPGroup = Tabs.Visuals:AddRightGroupbox("Player ESP", "eye")

ESPGroup:AddToggle("PlayerESP", {
	Text = "Player ESP",
	Default = false,
	Tooltip = "Show ESP for players",
})

ESPGroup:AddToggle("ESPBoxes", {
	Text = "2D Box",
	Default = true,
})

ESPGroup:AddToggle("ESP3DBox", {
	Text = "3D Box",
	Default = false,
	Tooltip = "Draw 3D wireframe box",
})

ESPGroup:AddToggle("ESPNames", {
	Text = "Names",
	Default = true,
})

ESPGroup:AddToggle("ESPTracers", {
	Text = "Tracers",
	Default = false,
})

ESPGroup:AddToggle("ESPHealth", {
	Text = "Health Bar",
	Default = true,
})

ESPGroup:AddToggle("ESPHighlight", {
	Text = "Highlight",
	Default = false,
	Tooltip = "Show outline around players",
})

ESPGroup:AddToggle("ESPTeamCheck", {
	Text = "Team Check",
	Default = false,
	Tooltip = "Different color for enemies",
})

ESPGroup:AddLabel("ESP Color"):AddColorPicker("ESPColor", {
	Default = Color3.fromRGB(0, 170, 255),
	Title = "ESP Color",
})

ESPGroup:AddLabel("Enemy Color"):AddColorPicker("ESPEnemyColor", {
	Default = Color3.fromRGB(255, 0, 0),
	Title = "Enemy ESP Color",
})

ESPGroup:AddToggle("ESPSkeleton", {
	Text = "Skeleton",
	Default = false,
	Tooltip = "Draw skeleton lines on players",
})

-- Full Bright
Toggles.FullBright:OnChanged(function()
	if Toggles.FullBright.Value then
		Lighting.Brightness = 2
		Lighting.Ambient = Color3.fromRGB(255, 255, 255)
	else
		Lighting.Brightness = 1
		Lighting.Ambient = Color3.fromRGB(128, 128, 128)
	end
end)

-- No Fog
Toggles.NoFog:OnChanged(function()
	if Toggles.NoFog.Value then
		Lighting.FogEnd = 9e9
	else
		Lighting.FogEnd = 500
	end
end)

-- ============================================
-- ESP FUNCTIONS
-- ============================================
local function newDrawing(drawingType, props)
	local obj = Drawing.new(drawingType)
	for k, v in pairs(props) do
		obj[k] = v
	end
	return obj
end

local function createESPElements()
	local elements = {
		Box = newDrawing("Square", {Visible = false, Thickness = 2, Filled = false, Color = Color3.fromRGB(0, 255, 0)}),
		Name = newDrawing("Text", {Visible = false, Center = true, Outline = true, Size = 14, Font = 2, Color = Color3.new(1, 1, 1)}),
		Tracer = newDrawing("Line", {Visible = false, Thickness = 1, Color = Color3.fromRGB(0, 255, 0)}),
		HealthBar = newDrawing("Line", {Visible = false, Thickness = 3, Color = Color3.new(0, 1, 0)}),
		Skeleton = {},
		Box3D = {}
	}
	-- Pre-create skeleton lines (max 14 for R15)
	for i = 1, 14 do
		elements.Skeleton[i] = newDrawing("Line", {Visible = false, Thickness = 1.5, Color = Color3.fromRGB(0, 255, 0)})
	end
	-- Pre-create 3D box lines (15 body parts * 12 edges = 180 lines max for R15)
	for i = 1, 180 do
		elements.Box3D[i] = newDrawing("Line", {Visible = false, Thickness = 1, Color = Color3.fromRGB(0, 255, 0)})
	end
	return elements
end

local function hideESP(data)
	if not data then return end
	data.Box.Visible = false
	data.Name.Visible = false
	data.Tracer.Visible = false
	data.HealthBar.Visible = false
	if data.Skeleton then
		for _, line in ipairs(data.Skeleton) do
			line.Visible = false
		end
	end
	if data.Box3D then
		for _, line in ipairs(data.Box3D) do
			line.Visible = false
		end
	end
end

-- Skeleton bones for R15
local skeletonBonesR15 = {
	{"Head", "UpperTorso"},
	{"UpperTorso", "LowerTorso"},
	{"LowerTorso", "LeftUpperLeg"},
	{"LeftUpperLeg", "LeftLowerLeg"},
	{"LeftLowerLeg", "LeftFoot"},
	{"LowerTorso", "RightUpperLeg"},
	{"RightUpperLeg", "RightLowerLeg"},
	{"RightLowerLeg", "RightFoot"},
	{"UpperTorso", "LeftUpperArm"},
	{"LeftUpperArm", "LeftLowerArm"},
	{"LeftLowerArm", "LeftHand"},
	{"UpperTorso", "RightUpperArm"},
	{"RightUpperArm", "RightLowerArm"},
	{"RightLowerArm", "RightHand"},
}

-- Skeleton bones for R6
local skeletonBonesR6 = {
	{"Head", "Torso"},
	{"Torso", "Left Arm"},
	{"Torso", "Right Arm"},
	{"Torso", "Left Leg"},
	{"Torso", "Right Leg"},
}

local function getSkeletonBones(char)
	if char:FindFirstChild("UpperTorso") then
		return skeletonBonesR15
	else
		return skeletonBonesR6
	end
end

local function getBoxScreenPoints(cf, size)
	local half = size / 2
	local points = {}
	local visible = true

	for x = -1, 1, 2 do
		for y = -1, 1, 2 do
			for z = -1, 1, 2 do
				local corner = cf * Vector3.new(half.X * x, half.Y * y, half.Z * z)
				local screenPos, onScreen = Camera:WorldToViewportPoint(corner)
				if not onScreen then
					visible = false
				end
				table.insert(points, Vector2.new(screenPos.X, screenPos.Y))
			end
		end
	end

	return points, visible
end

-- Get 3D box corners with screen positions and Z depth
local function get3DBoxCorners(cf, size)
	local half = size / 2
	local corners = {}
	local allVisible = true
	
	-- 8 corners of the box in specific order for edge drawing
	local offsets = {
		Vector3.new(-1, -1, -1), -- 1: bottom-back-left
		Vector3.new(1, -1, -1),  -- 2: bottom-back-right
		Vector3.new(1, -1, 1),   -- 3: bottom-front-right
		Vector3.new(-1, -1, 1),  -- 4: bottom-front-left
		Vector3.new(-1, 1, -1),  -- 5: top-back-left
		Vector3.new(1, 1, -1),   -- 6: top-back-right
		Vector3.new(1, 1, 1),    -- 7: top-front-right
		Vector3.new(-1, 1, 1),   -- 8: top-front-left
	}
	
	for i, offset in ipairs(offsets) do
		local worldPos = cf * Vector3.new(half.X * offset.X, half.Y * offset.Y, half.Z * offset.Z)
		local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
		if screenPos.Z <= 0 then
			allVisible = false
		end
		corners[i] = {
			screen = Vector2.new(screenPos.X, screenPos.Y),
			depth = screenPos.Z,
			visible = screenPos.Z > 0
		}
	end
	
	return corners, allVisible
end

-- 12 edges of a 3D box (pairs of corner indices)
local box3DEdges = {
	-- Bottom face
	{1, 2}, {2, 3}, {3, 4}, {4, 1},
	-- Top face
	{5, 6}, {6, 7}, {7, 8}, {8, 5},
	-- Vertical edges
	{1, 5}, {2, 6}, {3, 7}, {4, 8},
}

-- Body parts for 3D box ESP (R15)
local bodyPartsR15 = {
	"Head", "UpperTorso", "LowerTorso",
	"LeftUpperArm", "LeftLowerArm", "LeftHand",
	"RightUpperArm", "RightLowerArm", "RightHand",
	"LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
	"RightUpperLeg", "RightLowerLeg", "RightFoot"
}

-- Body parts for 3D box ESP (R6)
local bodyPartsR6 = {
	"Head", "Torso",
	"Left Arm", "Right Arm",
	"Left Leg", "Right Leg"
}

local function getBodyParts(char)
	if char:FindFirstChild("UpperTorso") then
		return bodyPartsR15
	else
		return bodyPartsR6
	end
end

-- Draw 3D box for a single part
local function drawPart3DBox(part, lines, startIndex, color)
	if not part or not part:IsA("BasePart") then
		-- Hide lines if part doesn't exist
		for i = startIndex, startIndex + 11 do
			if lines[i] then lines[i].Visible = false end
		end
		return startIndex + 12
	end
	
	-- Vẫn vẽ dù part bị invisible (Transparency = 1)
	local cf = part.CFrame
	local size = part.Size
	local corners, allVisible = get3DBoxCorners(cf, size)
	
	for i, edge in ipairs(box3DEdges) do
		local lineIndex = startIndex + i - 1
		local line = lines[lineIndex]
		if line then
			local c1 = corners[edge[1]]
			local c2 = corners[edge[2]]
			if c1.visible and c2.visible then
				line.Visible = true
				line.From = c1.screen
				line.To = c2.screen
				line.Color = color
			else
				line.Visible = false
			end
		end
	end
	
	return startIndex + 12
end

local function addHighlight(player)
	if not Toggles.ESPHighlight.Value then return end
	local char = player.Character
	if not char or espHighlights[player] then return end

	local isEnemy = Toggles.ESPTeamCheck.Value and player.Team ~= LocalPlayer.Team
	local color = isEnemy and Options.ESPEnemyColor.Value or Options.ESPColor.Value

	local highlight = Instance.new("Highlight")
	highlight.Name = "ESP_Highlight"
	highlight.Adornee = char
	highlight.FillColor = color
	highlight.OutlineColor = color
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0
	highlight.Parent = char

	espHighlights[player] = highlight
end

local function removeHighlight(player)
	local highlight = espHighlights[player]
	if highlight then
		highlight:Destroy()
		espHighlights[player] = nil
	end
end

local function updateHighlights()
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")

			if char and hum and hum.Health > 0 then
				if Toggles.PlayerESP.Value and Toggles.ESPHighlight.Value then
					if Toggles.ESPTeamCheck.Value and player.Team == LocalPlayer.Team then
						removeHighlight(player)
					else
						-- Update color if highlight exists
						if espHighlights[player] then
							local isEnemy = Toggles.ESPTeamCheck.Value and player.Team ~= LocalPlayer.Team
							local color = isEnemy and Options.ESPEnemyColor.Value or Options.ESPColor.Value
							espHighlights[player].FillColor = color
							espHighlights[player].OutlineColor = color
						else
							addHighlight(player)
						end
					end
				else
					removeHighlight(player)
				end
			else
				removeHighlight(player)
			end
		end
	end
end

local function drawPlayerESP(player, cf, size, hum)
	if not hasDrawingAPI or not Toggles.PlayerESP.Value then
		hideESP(espObjects[player])
		return
	end

	local points, visible = getBoxScreenPoints(cf, size)
	if not visible or #points == 0 then
		hideESP(espObjects[player])
		return
	end

	local data = espObjects[player]
	if not data then return end

	local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
	for _, pt in ipairs(points) do
		minX = math.min(minX, pt.X)
		minY = math.min(minY, pt.Y)
		maxX = math.max(maxX, pt.X)
		maxY = math.max(maxY, pt.Y)
	end

	local boxWidth, boxHeight = maxX - minX, maxY - minY
	if boxWidth <= 3 or boxHeight <= 4 then
		hideESP(data)
		return
	end

	local slimWidth = boxWidth * 0.7
	local slimX = minX + (boxWidth - slimWidth) / 2
	local isEnemy = Toggles.ESPTeamCheck.Value and player.Team ~= LocalPlayer.Team
	local baseColor = isEnemy and Options.ESPEnemyColor.Value or Options.ESPColor.Value
	local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)

	local hp = hum and hum.Health or 0
	local maxHp = hum and hum.MaxHealth or 100
	local ratio = math.clamp(maxHp > 0 and hp / maxHp or 0, 0, 1)

	-- 2D Box
	if Toggles.ESPBoxes.Value then
		data.Box.Visible = true
		data.Box.Position = Vector2.new(slimX, minY)
		data.Box.Size = Vector2.new(slimWidth, boxHeight)
		data.Box.Color = baseColor
	else
		data.Box.Visible = false
	end

	-- 3D Box (per body part)
	if data.Box3D then
		if Toggles.ESP3DBox and Toggles.ESP3DBox.Value then
			local char = player.Character
			if char then
				local bodyParts = getBodyParts(char)
				local lineIndex = 1
				for _, partName in ipairs(bodyParts) do
					local part = char:FindFirstChild(partName)
					lineIndex = drawPart3DBox(part, data.Box3D, lineIndex, baseColor)
				end
				-- Hide remaining unused lines
				for i = lineIndex, #data.Box3D do
					if data.Box3D[i] then
						data.Box3D[i].Visible = false
					end
				end
			else
				for _, line in ipairs(data.Box3D) do
					line.Visible = false
				end
			end
		else
			for _, line in ipairs(data.Box3D) do
				line.Visible = false
			end
		end
	end

	-- Name
	if Toggles.ESPNames.Value then
		data.Name.Visible = true
		data.Name.Text = string.format("%s [%d]", player.Name, math.floor(hp))
		data.Name.Position = Vector2.new(slimX + slimWidth / 2, minY - 18)
		data.Name.Color = baseColor
	else
		data.Name.Visible = false
	end

	-- Tracer
	if Toggles.ESPTracers.Value then
		data.Tracer.Visible = true
		data.Tracer.From = screenCenter
		data.Tracer.To = Vector2.new(slimX + slimWidth / 2, maxY)
		data.Tracer.Color = baseColor
	else
		data.Tracer.Visible = false
	end

	-- Health Bar
	if Toggles.ESPHealth.Value then
		local barHeight = boxHeight * ratio
		data.HealthBar.Visible = true
		data.HealthBar.From = Vector2.new(slimX - 5, maxY)
		data.HealthBar.To = Vector2.new(slimX - 5, maxY - barHeight)
		data.HealthBar.Color = Color3.fromRGB((1 - ratio) * 255, ratio * 255, 0)
	else
		data.HealthBar.Visible = false
	end

	-- Skeleton
	if data.Skeleton then
		if Toggles.ESPSkeleton and Toggles.ESPSkeleton.Value then
			local char = player.Character
			if char then
				local bones = getSkeletonBones(char)
				local lineIndex = 1
				for _, bone in ipairs(bones) do
					local part0 = char:FindFirstChild(bone[1])
					local part1 = char:FindFirstChild(bone[2])
					if part0 and part1 then
						local p0 = Camera:WorldToViewportPoint(part0.Position)
						local p1 = Camera:WorldToViewportPoint(part1.Position)
						if p0.Z > 0 and p1.Z > 0 then
							local line = data.Skeleton[lineIndex]
							if line then
								line.Visible = true
								line.From = Vector2.new(p0.X, p0.Y)
								line.To = Vector2.new(p1.X, p1.Y)
								line.Color = baseColor
							end
							lineIndex = lineIndex + 1
						end
					end
				end
				-- Hide unused skeleton lines
				for i = lineIndex, #data.Skeleton do
					if data.Skeleton[i] then
						data.Skeleton[i].Visible = false
					end
				end
			end
		else
			for _, line in ipairs(data.Skeleton) do
				line.Visible = false
			end
		end
	end
end

local function initializeESP()
	local ok, obj = pcall(function()
		return Drawing.new("Square")
	end)
	if ok and obj then
		hasDrawingAPI = true
		obj:Remove()

		-- Tạo ESP cho players hiện tại
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				espObjects[player] = createESPElements()
				-- Lắng nghe khi respawn
				player.CharacterAdded:Connect(function()
					if not espObjects[player] then
						espObjects[player] = createESPElements()
					end
				end)
			end
		end

		-- Player mới join
		Players.PlayerAdded:Connect(function(player)
			if player ~= LocalPlayer then
				espObjects[player] = createESPElements()
				player.CharacterAdded:Connect(function()
					if not espObjects[player] then
						espObjects[player] = createESPElements()
					end
				end)
			end
		end)

		Players.PlayerRemoving:Connect(function(player)
			if espObjects[player] then
				local data = espObjects[player]
				-- Ẩn trước
				if data.Box then data.Box.Visible = false end
				if data.Name then data.Name.Visible = false end
				if data.Tracer then data.Tracer.Visible = false end
				if data.HealthBar then data.HealthBar.Visible = false end
				if data.Skeleton then
					for _, line in ipairs(data.Skeleton) do
						if line then line.Visible = false end
					end
				end
				if data.Box3D then
					for _, line in ipairs(data.Box3D) do
						if line then line.Visible = false end
					end
				end
				-- Rồi remove
				if data.Box and data.Box.Remove then pcall(function() data.Box:Remove() end) end
				if data.Name and data.Name.Remove then pcall(function() data.Name:Remove() end) end
				if data.Tracer and data.Tracer.Remove then pcall(function() data.Tracer:Remove() end) end
				if data.HealthBar and data.HealthBar.Remove then pcall(function() data.HealthBar:Remove() end) end
				if data.Skeleton then
					for _, line in ipairs(data.Skeleton) do
						if line and line.Remove then pcall(function() line:Remove() end) end
					end
				end
				if data.Box3D then
					for _, line in ipairs(data.Box3D) do
						if line and line.Remove then pcall(function() line:Remove() end) end
					end
				end
				espObjects[player] = nil
			end
			removeHighlight(player)
		end)

		return true
	end
	return false
end

local function updateESP()
	if not Toggles.PlayerESP.Value then
		for _, data in pairs(espObjects) do
			hideESP(data)
		end
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")

			if char and hum and hum.Health > 0 then
				-- Team check - ẩn ESP cho teammate nếu bật
				if Toggles.ESPTeamCheck.Value and player.Team == LocalPlayer.Team then
					hideESP(espObjects[player])
				else
					-- Try GetBoundingBox first
					local ok, cf, size = pcall(char.GetBoundingBox, char)
					
					-- Fallback to HumanoidRootPart if GetBoundingBox fails (e.g. invisible player)
					if not ok or not cf or not size then
						local hrp = char:FindFirstChild("HumanoidRootPart")
						if hrp then
							cf = hrp.CFrame
							-- Estimate character size
							size = Vector3.new(4, 5, 2)
							ok = true
						end
					end
					
					if ok and cf and size then
						drawPlayerESP(player, cf, size, hum)
					else
						hideESP(espObjects[player])
					end
				end
			else
				hideESP(espObjects[player])
			end
		end
	end
end

-- Initialize ESP
initializeESP()

-- ESP Update Loop
RunService.RenderStepped:Connect(function()
	updateESP()
	updateHighlights()
	
	-- Aimbot Update
	local mousePos = UserInputService:GetMouseLocation()
	
	-- Update FOV Circle
	if aimbotFOVCircle then
		aimbotFOVCircle.Position = mousePos
		aimbotFOVCircle.Radius = Options.AimbotFOV and Options.AimbotFOV.Value or 150
		aimbotFOVCircle.Visible = Toggles.AimbotEnabled.Value and Toggles.AimbotFOVShow.Value
		aimbotFOVCircle.Color = Options.AimbotFOVColor and Options.AimbotFOVColor.Value or Color3.fromRGB(0, 255, 0)
	end
	
	-- Aimbot Logic
	if Toggles.AimbotEnabled.Value then
		local active = true
		if Toggles.AimbotHoldMouse2.Value and not holdingMouse2 then
			active = false
		end
		
		if active then
			local targetChar, targetPart = getClosestAimbotTarget()
			if targetChar and targetPart then
				local targetPos = targetPart.Position
				
				-- Prediction
				local prediction = Options.AimbotPrediction and Options.AimbotPrediction.Value or 0
				if prediction > 0 then
					local vel = targetPart.AssemblyLinearVelocity or targetPart.Velocity or Vector3.new(0, 0, 0)
					targetPos = targetPos + (vel * prediction)
				end
				
				local cf = Camera.CFrame
				local desired = CFrame.new(cf.Position, targetPos)
				
				-- Smoothness
				local smoothness = Options.AimbotSmoothness and Options.AimbotSmoothness.Value or 0.1
				if smoothness > 0 then
					local alpha = 1 - smoothness
					alpha = math.clamp(alpha, 0.01, 1)
					Camera.CFrame = cf:Lerp(desired, alpha)
				else
					Camera.CFrame = desired
				end
				
				-- Change FOV color when locked
				if aimbotFOVCircle then
					aimbotFOVCircle.Color = Color3.fromRGB(255, 0, 0)
				end
			else
				-- Reset FOV color
				if aimbotFOVCircle then
					aimbotFOVCircle.Color = Options.AimbotFOVColor and Options.AimbotFOVColor.Value or Color3.fromRGB(0, 255, 0)
				end
			end
		end
	end
end)

-- ESP Toggle handlers
Toggles.PlayerESP:OnChanged(function()
	if not Toggles.PlayerESP.Value then
		for _, data in pairs(espObjects) do
			hideESP(data)
		end
		for player, _ in pairs(espHighlights) do
			removeHighlight(player)
		end
	end
end)

Toggles.ESPHighlight:OnChanged(function()
	if not Toggles.ESPHighlight.Value then
		for player, _ in pairs(espHighlights) do
			removeHighlight(player)
		end
	end
end)



-- ============================================
-- TELEPORT TAB
-- ============================================
local TeleportGroup = Tabs.Teleport:AddLeftGroupbox("Teleport", "map-pin")

TeleportGroup:AddDropdown("TeleportPlayer", {
	SpecialType = "Player",
	ExcludeLocalPlayer = true,
	Text = "Teleport To Player",
})

TeleportGroup:AddButton({
	Text = "Teleport",
	Func = function()
		local targetPlayer = Options.TeleportPlayer.Value
		if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
			if rootPart then
				rootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
				Library:Notify({
					Title = "Teleported",
					Description = "Teleported to " .. targetPlayer.Name,
					Time = 3,
				})
			end
		end
	end,
})

-- ============================================
-- SERVER TAB
-- ============================================
local ServerInfoGroup = Tabs.Server:AddLeftGroupbox("Server Information", "server")

ServerInfoGroup:AddLabel("Current server info:")
ServerInfoGroup:AddLabel("PlaceId: " .. tostring(game.PlaceId))
ServerInfoGroup:AddLabel("JobId: " .. tostring(game.JobId))
ServerInfoGroup:AddLabel("Players: " .. tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers or "?"))

ServerInfoGroup:AddButton({
	Text = "Rejoin Server",
	Func = function()
		TeleportService:Teleport(game.PlaceId, LocalPlayer)
	end,
	Risky = true,
})

local ServerListGroup = Tabs.Server:AddRightGroupbox("Server List", "server")

local serverList = {}
local serverListDisplay = {}
local serverDropdown = ServerListGroup:AddDropdown("ServerList", {
	Values = {},
	Text = "Server List",
})

ServerListGroup:AddButton({
	Text = "Refresh server list",
	Func = function()
		local success, result = pcall(function()
			return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" ..
			game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
		end)

		if not success or not result or not result.data then
			Library:Notify({
				Title = "Server",
				Description = "Failed to load server list",
				Time = 3,
			})
			return
		end

		serverList = {}
		serverListDisplay = {}

		for _, server in ipairs(result.data) do
			if server.id ~= game.JobId then
				local currentPlayers = server.playing or server.playerCount or 0
				local maxPlayers = server.maxPlayers or "?"
				local ping = server.ping or server.latency or "?"
				local fps = server.fps or "?"
				local shortId = typeof(server.id) == "string" and string.sub(server.id, 1, 6) or tostring(server.id)
				local display = string.format("%d/%s|ping: %s|fps: %s|%s", currentPlayers, maxPlayers, tostring(ping),
					tostring(fps), shortId)
				table.insert(serverList, server)
				table.insert(serverListDisplay, display)
			end
		end

		if #serverListDisplay == 0 then
			Library:Notify({
				Title = "Server",
				Description = "No other servers found",
				Time = 3,
			})
		else
			Library:Notify({
				Title = "Server",
				Description = "Refreshed " .. tostring(#serverListDisplay) .. " servers",
				Time = 3,
			})
		end

		serverDropdown:SetValues(serverListDisplay)
	end,
})

ServerListGroup:AddButton({
	Text = "Join Selected Server",
	Func = function()
		local selected = Options.ServerList.Value

		if not selected or selected == "" then
			Library:Notify({
				Title = "Server",
				Description = "You haven't selected any server",
				Time = 3,
			})
			return
		end

		local selectedIndex

		for i, display in ipairs(serverListDisplay) do
			if display == selected then
				selectedIndex = i
				break
			end
		end

		if not selectedIndex then
			Library:Notify({
				Title = "Server",
				Description = "Selected server not found",
				Time = 3,
			})
			return
		end

		local serverData = serverList[selectedIndex]

		if serverData and serverData.id then
			TeleportService:TeleportToPlaceInstance(game.PlaceId, serverData.id, LocalPlayer)
		else
			Library:Notify({
				Title = "Server",
				Description = "Invalid server data",
				Time = 3,
			})
		end
	end,
	Risky = true,
})

ServerListGroup:AddButton({
	Text = "Server Hop",
	Func = function()
		local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" ..
		game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
		for _, server in pairs(servers.data) do
			if server.id ~= game.JobId then
				TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
				break
			end
		end
	end,
	Risky = true,
})

-- ============================================
-- MISC TAB
-- ============================================
local MiscGroup = Tabs.Misc:AddLeftGroupbox("Misc", "settings")

MiscGroup:AddToggle("AntiAFK", {
	Text = "Anti AFK",
	Default = false,
	Tooltip = "Prevent AFK kick",
})

-- Anti AFK
local antiAFKConnection
Toggles.AntiAFK:OnChanged(function()
	if Toggles.AntiAFK.Value then
		antiAFKConnection = RunService.Heartbeat:Connect(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	else
		if antiAFKConnection then
			antiAFKConnection:Disconnect()
			antiAFKConnection = nil
		end
	end
end)

-- ============================================
-- UI SETTINGS
-- ============================================
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible,
	Text = "Open Keybind Menu",
	Callback = function(value)
		Library.KeybindFrame.Visible = value
	end,
})

MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = true,
	Callback = function(Value)
		Library.ShowCustomCursor = Value
	end,
})

MenuGroup:AddDropdown("NotificationSide", {
	Values = { "Left", "Right" },
	Default = "Right",
	Text = "Notification Side",
	Callback = function(Value)
		Library:SetNotifySide(Value)
	end,
})

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind")
	:AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

MenuGroup:AddButton({
	Text = "Unload",
	Func = function()
		Library:Unload()
	end,
})

Library.ToggleKeybind = Options.MenuKeybind

-- Save Manager & Theme Manager
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("UniversalScript")
SaveManager:SetFolder("UniversalScript")

SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

SaveManager:LoadAutoloadConfig()

-- Cleanup
Library:OnUnload(function()
	-- Cleanup Aimbot FOV Circle
	if aimbotFOVCircle then
		aimbotFOVCircle.Visible = false
		pcall(function() aimbotFOVCircle:Remove() end)
		aimbotFOVCircle = nil
	end
	
	-- Cleanup ESP Drawing objects - ẩn trước rồi mới remove
	for player, data in pairs(espObjects) do
		if data then
			-- Ẩn tất cả trước
			if data.Box then data.Box.Visible = false end
			if data.Name then data.Name.Visible = false end
			if data.Tracer then data.Tracer.Visible = false end
			if data.HealthBar then data.HealthBar.Visible = false end
			if data.Skeleton then
				for _, line in ipairs(data.Skeleton) do
					if line then line.Visible = false end
				end
			end
			if data.Box3D then
				for _, line in ipairs(data.Box3D) do
					if line then line.Visible = false end
				end
			end
			-- Rồi mới remove
			if data.Box and data.Box.Remove then pcall(function() data.Box:Remove() end) end
			if data.Name and data.Name.Remove then pcall(function() data.Name:Remove() end) end
			if data.Tracer and data.Tracer.Remove then pcall(function() data.Tracer:Remove() end) end
			if data.HealthBar and data.HealthBar.Remove then pcall(function() data.HealthBar:Remove() end) end
			if data.Skeleton then
				for _, line in ipairs(data.Skeleton) do
					if line and line.Remove then pcall(function() line:Remove() end) end
				end
			end
			if data.Box3D then
				for _, line in ipairs(data.Box3D) do
					if line and line.Remove then pcall(function() line:Remove() end) end
				end
			end
		end
	end
	espObjects = {}

	-- Cleanup ESP Highlights từ bảng lưu trữ
	for player, highlight in pairs(espHighlights) do
		pcall(function() 
			if highlight and highlight.Parent then
				highlight:Destroy() 
			end
		end)
	end
	espHighlights = {}
	
	-- Cleanup tất cả Highlight instances còn sót trong game
	pcall(function()
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character then
				local highlight = player.Character:FindFirstChild("ESP_Highlight")
				if highlight then
					highlight:Destroy()
				end
			end
		end
	end)

	-- Cleanup Noclip
	if noclipConnection then
		noclipConnection:Disconnect()
		noclipConnection = nil
	end
	if character then
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = true
			end
		end
	end

	-- Cleanup HipHeight
	if hipHeightConnection then
		hipHeightConnection:Disconnect()
		hipHeightConnection = nil
	end
	if hipHeightCharConnection then
		hipHeightCharConnection:Disconnect()
		hipHeightCharConnection = nil
	end
	if humanoid and originalHipHeight ~= nil then
		humanoid.HipHeight = originalHipHeight
	end
	originalHipHeight = nil

	-- Cleanup Anti AFK
	if antiAFKConnection then
		antiAFKConnection:Disconnect()
		antiAFKConnection = nil
	end

	-- Reset Hitbox
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

	-- Reset Humanoid
	if humanoid then
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
	end

	if wsLoopConnection then
		wsLoopConnection:Disconnect()
		wsLoopConnection = nil
	end
	if wsCharAddedConnection then
		wsCharAddedConnection:Disconnect()
		wsCharAddedConnection = nil
	end

	if jpLoopConnection then
		jpLoopConnection:Disconnect()
		jpLoopConnection = nil
	end
	if jpCharAddedConnection then
		jpCharAddedConnection:Disconnect()
		jpCharAddedConnection = nil
	end

	-- Reset Lighting
	Lighting.Brightness = 1
	Lighting.Ambient = Color3.fromRGB(128, 128, 128)
	Lighting.FogEnd = 500
end)

Library:Notify({
	Title = "Universal Script",
	Description = "Loaded successfully!",
	Time = 5,
})
