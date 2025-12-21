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
local espObjects = {}
local hitboxOriginals = {}
local highlightObjects = {}
local wsLoopConnection
local wsCharAddedConnection
local jpLoopConnection
local jpCharAddedConnection

-- Aimbot / Visual helpers
local FOVCircle
local CrosshairLines = {}
local aimbotHoldingMouse2 = false

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



-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
	if Toggles.InfiniteJump.Value and humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

-- ============================================
-- COMBAT TAB
-- ============================================
local CombatGroup = Tabs.Combat:AddLeftGroupbox("Hitbox", "target")

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

local AimbotGroup = Tabs.Combat:AddRightGroupbox("Aimbot", "crosshair")

AimbotGroup:AddToggle("AimbotEnabled", {
	Text = "Aimbot",
	Default = false,
	Tooltip = "Smooth camera aimbot",
})

AimbotGroup:AddToggle("AimbotHoldMouse2", {
	Text = "Hold Mouse 2",
	Default = true,
	Tooltip = "Only aim while holding right mouse button",
})

AimbotGroup:AddToggle("AimbotTeamCheck", {
	Text = "Team Check (players)",
	Default = false,
	Tooltip = "Ignore teammates when aiming at players",
})


AimbotGroup:AddDropdown("AimbotAimPart", {
	Values = { "Head", "UpperTorso", "HumanoidRootPart" },
	Default = 1,
	Text = "Aim Part",
})

AimbotGroup:AddToggle("AimbotFOVEnabled", {
	Text = "FOV Enabled",
	Default = true,
})

AimbotGroup:AddSlider("AimbotFOVRadius", {
	Text = "FOV Radius",
	Default = 150,
	Min = 40,
	Max = 400,
	Rounding = 0,
})

AimbotGroup:AddSlider("AimbotSmoothness", {
	Text = "Smoothness",
	Default = 0.20,
	Min = 0,
	Max = 1,
	Rounding = 2,
})

AimbotGroup:AddSlider("AimbotPrediction", {
	Text = "Prediction",
	Default = 0.08,
	Min = 0,
	Max = 0.3,
	Rounding = 2,
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

-- Aimbot helpers
local function getAimbotTargets()
	local targets = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local hum = player.Character:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				if not (Toggles.AimbotTeamCheck and Toggles.AimbotTeamCheck.Value) or player.Team ~= LocalPlayer.Team then
					table.insert(targets, player.Character)
				end
			end
		end
	end

	return targets
end

local function getClosestAimbotTarget()
	local mousePos = UserInputService:GetMouseLocation()
	local closestChar, closestPart
	local closestDist = math.huge

	local aimPartName = Options.AimbotAimPart and Options.AimbotAimPart.Value or "Head"
	local fovEnabled = Toggles.AimbotFOVEnabled and Toggles.AimbotFOVEnabled.Value
	local fovRadius = (Options.AimbotFOVRadius and Options.AimbotFOVRadius.Value) or 150

	for _, char in ipairs(getAimbotTargets()) do
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			local part = char:FindFirstChild(aimPartName)
			if not part then
				part = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Head")
			end

			if part then
				local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
				if onScreen and screenPos.Z > 0 then
					local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
					if (not fovEnabled) or dist <= fovRadius then
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

-- Mouse2 state for aimbot
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		aimbotHoldingMouse2 = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		aimbotHoldingMouse2 = false
	end
end)

-- Aimbot + FOV + Crosshair loop
RunService.RenderStepped:Connect(function()
	local mousePos = UserInputService:GetMouseLocation()

	-- FOV circle
	if FOVCircle then
		FOVCircle.Position = mousePos
		FOVCircle.Radius = (Options.AimbotFOVRadius and Options.AimbotFOVRadius.Value) or 150
		FOVCircle.Color = (Options.ESPColor and Options.ESPColor.Value) or Color3.fromRGB(255, 255, 255)
		FOVCircle.Visible = Toggles.AimbotEnabled and Toggles.AimbotEnabled.Value and (Toggles.AimbotFOVEnabled and Toggles.AimbotFOVEnabled.Value)
	end

	-- Crosshair
	if #CrosshairLines > 0 then
		local cx, cy = mousePos.X, mousePos.Y
		local size = 6
		local show = Toggles.Crosshair and Toggles.Crosshair.Value or false

		for _, l in ipairs(CrosshairLines) do
			l.Visible = show
		end

		if show then
			CrosshairLines[1].From = Vector2.new(cx - size, cy)
			CrosshairLines[1].To = Vector2.new(cx - 1, cy)
			CrosshairLines[2].From = Vector2.new(cx + 1, cy)
			CrosshairLines[2].To = Vector2.new(cx + size, cy)
			CrosshairLines[3].From = Vector2.new(cx, cy - size)
			CrosshairLines[3].To = Vector2.new(cx, cy - 1)
			CrosshairLines[4].From = Vector2.new(cx, cy + 1)
			CrosshairLines[4].To = Vector2.new(cx, cy + size)
		end
	end

	-- Aimbot
	if Toggles.AimbotEnabled and Toggles.AimbotEnabled.Value then
		local active = true
		if Toggles.AimbotHoldMouse2 and Toggles.AimbotHoldMouse2.Value and not aimbotHoldingMouse2 then
			active = false
		end

		if active then
			local char, part = getClosestAimbotTarget()
			if char and part then
				local targetPos = part.Position
				local prediction = (Options.AimbotPrediction and Options.AimbotPrediction.Value) or 0
				if prediction > 0 then
					local vel = part.AssemblyLinearVelocity or part.Velocity or Vector3.new()
					targetPos = targetPos + (vel * prediction)
				end

				local cf = Camera.CFrame
				local desired = CFrame.new(cf.Position, targetPos)
				local smoothness = (Options.AimbotSmoothness and Options.AimbotSmoothness.Value) or 0

				if smoothness > 0 then
					Camera.CFrame = cf:Lerp(desired, smoothness)
				else
					Camera.CFrame = desired
				end
			end
		end
	end
end)

-- ============================================
-- VISUALS TAB - ESP
-- ============================================
local ESPGroup = Tabs.Visuals:AddLeftGroupbox("ESP", "eye")

ESPGroup:AddToggle("PlayerESP", {
	Text = "Player ESP",
	Default = false,
	Tooltip = "Show ESP for players",
})

ESPGroup:AddToggle("ESPBoxes", {
	Text = "Boxes",
	Default = true,
})

ESPGroup:AddToggle("ESPTracers", {
	Text = "Tracers",
	Default = true,
})

ESPGroup:AddToggle("ESPNames", {
	Text = "Names",
	Default = true,
})

ESPGroup:AddToggle("ESPDistance", {
	Text = "Distance",
	Default = true,
})

ESPGroup:AddToggle("ESPHealth", {
	Text = "Health Bar",
	Default = false,
})

ESPGroup:AddToggle("ESPSkeleton", {
	Text = "Skeleton",
	Default = false,
	Tooltip = "Draw skeleton lines on players",
})

ESPGroup:AddLabel("ESP Color"):AddColorPicker("ESPColor", {
	Default = Color3.fromRGB(0, 255, 0),
	Title = "ESP Color",
})

ESPGroup:AddLabel("Enemy ESP Color"):AddColorPicker("EnemyESPColor", {
	Default = Color3.fromRGB(255, 0, 0),
	Title = "Enemy ESP Color",
})

ESPGroup:AddToggle("ESPTeamCheck", {
	Text = "Team Check",
	Default = false,
	Tooltip = "Color ESP by team",
})

ESPGroup:AddToggle("HighlightESP", {
	Text = "Highlight ESP",
	Default = false,
	Tooltip = "Show outline around players",
})

ESPGroup:AddLabel("Highlight Color"):AddColorPicker("HighlightColor", {
	Default = Color3.fromRGB(0, 255, 0),
	Title = "Highlight Color",
})

-- ESP Functions

-- Setup aimbot visuals (FOV circle + crosshair lines)
do
	local success, circle = pcall(function()
		return Drawing.new("Circle")
	end)
	if success and circle then
		FOVCircle = circle
		FOVCircle.NumSides = 64
		FOVCircle.Thickness = 1.5
		FOVCircle.Filled = false
		FOVCircle.Color = (Options.ESPColor and Options.ESPColor.Value) or Color3.fromRGB(255, 255, 255)
		FOVCircle.Visible = false
	end

	for i = 1, 4 do
		local line = Drawing.new("Line")
		line.Visible = false
		line.Thickness = 1.5
		line.Color = Color3.fromRGB(255, 255, 255)
		CrosshairLines[i] = line
	end
end

-- Skeleton bones cho R15
local skeletonBonesR15 = {
	{ "Head", "UpperTorso" },
	{ "UpperTorso", "LowerTorso" },

	{ "LowerTorso", "LeftUpperLeg" },
	{ "LeftUpperLeg", "LeftLowerLeg" },
	{ "LeftLowerLeg", "LeftFoot" },

	{ "LowerTorso", "RightUpperLeg" },
	{ "RightUpperLeg", "RightLowerLeg" },
	{ "RightLowerLeg", "RightFoot" },

	{ "UpperTorso", "LeftUpperArm" },
	{ "LeftUpperArm", "LeftLowerArm" },
	{ "LeftLowerArm", "LeftHand" },

	{ "UpperTorso", "RightUpperArm" },
	{ "RightUpperArm", "RightLowerArm" },
	{ "RightLowerArm", "RightHand" },
}

-- Skeleton bones cho R6
local skeletonBonesR6 = {
	{ "Head", "Torso" },
	{ "Torso", "Left Arm" },
	{ "Torso", "Right Arm" },
	{ "Torso", "Left Leg" },
	{ "Torso", "Right Leg" },
}

-- Hàm detect R6 hay R15
local function getSkeletonBones(character)
	if character:FindFirstChild("UpperTorso") then
		return skeletonBonesR15
	else
		return skeletonBonesR6
	end
end

local function createESP(player)
	if player == LocalPlayer then return end
	if not player.Character then return end

	local character = player.Character
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	local espData = {
		player = player,
		character = character,
		box = nil,
		tracer = nil,
		label = nil,
		healthBar = nil,
		skeleton = {},
	}

	-- Box (luôn tạo, bật/tắt bằng toggle trong updateESP)
	local box = Drawing.new("Square")
	box.Visible = false
	box.Color = Options.ESPColor.Value
	box.Thickness = 2
	box.Filled = false
	box.Transparency = 1
	espData.box = box

	-- Tracer
	local tracer = Drawing.new("Line")
	tracer.Visible = false
	tracer.Color = Options.ESPColor.Value
	tracer.Thickness = 2
	espData.tracer = tracer

	-- Label
	local label = Drawing.new("Text")
	label.Visible = false
	label.Color = Options.ESPColor.Value
	label.Size = 14
	label.Center = true
	label.Outline = true
	label.Font = 2
	espData.label = label

	-- Health bar
	local bar = Drawing.new("Line")
	bar.Visible = false
	bar.Thickness = 2
	bar.Color = Color3.fromRGB(0, 255, 0)
	espData.healthBar = bar

	-- Skeleton lines (pre-create a pool to reuse) - tạo đủ cho cả R15 (14 bones)
	for i = 1, 14 do
		local line = Drawing.new("Line")
		line.Visible = false
		line.Thickness = 1.5
		line.Color = Options.ESPColor.Value
		espData.skeleton[i] = line
	end

	espObjects[player] = espData
end

local function removeESP(player)
	local espData = espObjects[player]
	if espData then
		if espData.box then espData.box:Remove() end
		if espData.tracer then espData.tracer:Remove() end
		if espData.label then espData.label:Remove() end
		if espData.healthBar then espData.healthBar:Remove() end
		if espData.skeleton then
			for _, line in ipairs(espData.skeleton) do
				pcall(function()
					line:Remove()
				end)
			end
		end
		espObjects[player] = nil
	end
end

local function createHighlight(player)
	if player == LocalPlayer then return end
	if not player.Character then return end

	local character = player.Character
	local highlight = highlightObjects[player]

	if highlight and highlight.Parent then
		highlight.Adornee = character
		return
	end

	highlight = Instance.new("Highlight")
	highlight.FillColor = (Options.HighlightColor and Options.HighlightColor.Value) or Color3.fromRGB(0, 255, 0)
	highlight.OutlineColor = highlight.FillColor
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Adornee = character
	-- Parent vào character thay vì CoreGui để Highlight hoạt động đúng
	highlight.Parent = character

	highlightObjects[player] = highlight
end

local function removeHighlight(player)
	local highlight = highlightObjects[player]
	if highlight then
		highlight:Destroy()
		highlightObjects[player] = nil
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

local function updateESP()
	if not Toggles.PlayerESP.Value then return end
	
	for player, espData in pairs(espObjects) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		
		if character and humanoid and humanoid.Health > 0 then
			local rootPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
			if not rootPart then
				if espData and espData.box then espData.box.Visible = false end
				if espData and espData.tracer then espData.tracer.Visible = false end
				if espData and espData.label then espData.label.Visible = false end
				if espData and espData.healthBar then espData.healthBar.Visible = false end
			else
				local size = rootPart.Size + Vector3.new(2, 3, 1)
				local points, allVisible = getBoxScreenPoints(rootPart.CFrame, size)
				
				if espData then
					if not allVisible or #points == 0 then
						if espData.box then espData.box.Visible = false end
						if espData.tracer then espData.tracer.Visible = false end
						if espData.label then espData.label.Visible = false end
						if espData.healthBar then espData.healthBar.Visible = false end
						if espData.skeleton then
							for _, line in ipairs(espData.skeleton) do
								line.Visible = false
							end
						end
					else
						local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
						for _, pt in ipairs(points) do
							minX = math.min(minX, pt.X)
							minY = math.min(minY, pt.Y)
							maxX = math.max(maxX, pt.X)
							maxY = math.max(maxY, pt.Y)
						end
						
						local boxWidth, boxHeight = maxX - minX, maxY - minY
						if boxWidth <= 3 or boxHeight <= 4 then
							if espData.box then espData.box.Visible = false end
							if espData.tracer then espData.tracer.Visible = false end
							if espData.label then espData.label.Visible = false end
							if espData.healthBar then espData.healthBar.Visible = false end
							if espData.skeleton then
								for _, line in ipairs(espData.skeleton) do
									line.Visible = false
								end
							end
						else
							local slimWidth = boxWidth * 0.7
							local slimX = minX + (boxWidth - slimWidth) / 2
							local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
							
							local isEnemy = false
							if Toggles.ESPTeamCheck and Toggles.ESPTeamCheck.Value then
								if LocalPlayer.Team and player.Team then
									isEnemy = player.Team ~= LocalPlayer.Team
								elseif LocalPlayer.TeamColor and player.TeamColor then
									isEnemy = player.TeamColor ~= LocalPlayer.TeamColor
								else
									-- Nếu game không dùng team, coi tất cả người chơi khác là enemy
									isEnemy = player ~= LocalPlayer
								end
							end
							
							local baseColor = Options.ESPColor and Options.ESPColor.Value or Color3.fromRGB(255, 255, 255)
							if isEnemy and Options.EnemyESPColor then
								baseColor = Options.EnemyESPColor.Value
							end
							
							-- Box
							if espData.box and Toggles.ESPBoxes.Value then
								espData.box.Visible = true
								espData.box.Position = Vector2.new(slimX, minY)
								espData.box.Size = Vector2.new(slimWidth, boxHeight)
								espData.box.Color = baseColor
							elseif espData.box then
								espData.box.Visible = false
							end
							
							-- Name + distance
							if espData.label then
								local parts = {}
								if Toggles.ESPNames.Value then
									if humanoid then
										table.insert(parts,
											string.format("%s [%d]", player.Name, math.floor(humanoid.Health)))
									else
										table.insert(parts, player.Name)
									end
								end
								if Toggles.ESPDistance.Value and rootPart and character.PrimaryPart then
									local distance = math.floor((rootPart.Position - character.PrimaryPart.Position).Magnitude)
									table.insert(parts, tostring(distance) .. " studs")
								end
								local text = table.concat(parts, " | ")
								if text ~= "" then
									espData.label.Visible = true
									espData.label.Text = text
									espData.label.Position = Vector2.new(slimX + slimWidth / 2, minY - 18)
									espData.label.Color = baseColor
								else
									espData.label.Visible = false
								end
							end
							
							-- Tracer
							if espData.tracer and Toggles.ESPTracers.Value then
								espData.tracer.Visible = true
								espData.tracer.From = screenCenter
								espData.tracer.To = Vector2.new(slimX + slimWidth / 2, maxY)
								espData.tracer.Color = baseColor
							elseif espData.tracer then
								espData.tracer.Visible = false
							end
							
							-- Health bar
							if espData.healthBar and Toggles.ESPHealth.Value and humanoid and humanoid.MaxHealth > 0 then
								local hp = humanoid.Health
								local maxHp = humanoid.MaxHealth
								local ratio = math.clamp(hp / maxHp, 0, 1)
								local barHeight = boxHeight * ratio
								espData.healthBar.Visible = true
								espData.healthBar.From = Vector2.new(slimX - 5, maxY)
								espData.healthBar.To = Vector2.new(slimX - 5, maxY - barHeight)
								espData.healthBar.Color = Color3.fromRGB((1 - ratio) * 255, ratio * 255, 0)
							elseif espData.healthBar then
								espData.healthBar.Visible = false
							end

							-- Skeleton
							if espData.skeleton then
								if Toggles.ESPSkeleton and Toggles.ESPSkeleton.Value then
									local bones = getSkeletonBones(character)
									local lineIndex = 1
									for _, bone in ipairs(bones) do
										local part0 = character:FindFirstChild(bone[1])
										local part1 = character:FindFirstChild(bone[2])
										if part0 and part1 then
											local p0, v0 = Camera:WorldToViewportPoint(part0.Position)
											local p1, v1 = Camera:WorldToViewportPoint(part1.Position)
											if v0 and v1 and p0.Z > 0 and p1.Z > 0 then
												local line = espData.skeleton[lineIndex]
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
									for i = lineIndex, #espData.skeleton do
										local line = espData.skeleton[i]
										if line then
											line.Visible = false
										end
									end
								else
									for _, line in ipairs(espData.skeleton) do
										line.Visible = false
									end
								end
							end
						end
					end
				end
			end
		else
			removeESP(player)
		end
	end
end

-- ESP Toggle
Toggles.PlayerESP:OnChanged(function()
	if Toggles.PlayerESP.Value then
		for _, player in pairs(Players:GetPlayers()) do
			createESP(player)
		end
	else
		-- Tắt toàn bộ ESP khi PlayerESP off
		for player, _ in pairs(espObjects) do
			removeESP(player)
		end
		for player, _ in pairs(highlightObjects) do
			removeHighlight(player)
		end
		-- Đồng bộ always: PlayerESP off thì HighlightESP cũng off
		if Toggles.HighlightESP and Toggles.HighlightESP.Value then
			Toggles.HighlightESP:SetValue(false)
		end
	end
end)

Toggles.HighlightESP:OnChanged(function()
	if Toggles.HighlightESP.Value then
		for _, player in pairs(Players:GetPlayers()) do
			createHighlight(player)
			player.CharacterAdded:Connect(function()
				createHighlight(player)
			end)
		end
	else
		for player, _ in pairs(highlightObjects) do
			removeHighlight(player)
		end
	end
end)

-- ESP Color Update
Options.ESPColor:OnChanged(function()
	for _, espData in pairs(espObjects) do
		if espData.box then espData.box.Color = Options.ESPColor.Value end
		if espData.tracer then espData.tracer.Color = Options.ESPColor.Value end
		if espData.label then espData.label.Color = Options.ESPColor.Value end
		if espData.skeleton then
			for _, line in ipairs(espData.skeleton) do
				line.Color = Options.ESPColor.Value
			end
		end
	end
end)

Options.HighlightColor:OnChanged(function()
	for _, highlight in pairs(highlightObjects) do
		if highlight then
			highlight.FillColor = Options.HighlightColor.Value
			highlight.OutlineColor = Options.HighlightColor.Value
		end
	end
end)

-- ESP Update Loop
RunService.RenderStepped:Connect(updateESP)

-- Player Added/Removed
Players.PlayerAdded:Connect(function(player)
	if Toggles.PlayerESP.Value then
		createESP(player)
	end
	if Toggles.HighlightESP and Toggles.HighlightESP.Value then
		createHighlight(player)
	end
	player.CharacterAdded:Connect(function()
		if Toggles.HighlightESP and Toggles.HighlightESP.Value then
			createHighlight(player)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	removeESP(player)
	removeHighlight(player)
end)

-- Visuals - Other
local VisualsGroup = Tabs.Visuals:AddRightGroupbox("Visuals", "sun")

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

VisualsGroup:AddToggle("Crosshair", {
	Text = "Crosshair",
	Default = false,
	Tooltip = "Show simple crosshair at mouse position",
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

MiscGroup:AddToggle("Freecam", {
	Text = "Freecam",
	Default = false,
	Tooltip = "Free camera movement (WASD + Q/E + Shift)",
})

MiscGroup:AddSlider("FreecamSpeed", {
	Text = "Freecam Speed",
	Default = 1,
	Min = 0.1,
	Max = 5,
	Rounding = 1,
})

-- Freecam variables
local freecamActive = false
local freecamConnection = nil
local freecamPos = nil
local freecamCF = nil
local originalCameraType = nil
local originalCameraSubject = nil

-- Freecam
local function startFreecam()
	if freecamActive then return end
	freecamActive = true
	
	-- Lưu trạng thái camera gốc
	originalCameraType = Camera.CameraType
	originalCameraSubject = Camera.CameraSubject
	freecamCF = Camera.CFrame
	
	-- Đặt camera thành Scriptable
	Camera.CameraType = Enum.CameraType.Scriptable
	
	-- Highlight bản thân khi freecam
	if character then
		local selfHighlight = character:FindFirstChildOfClass("Highlight")
		if not selfHighlight then
			selfHighlight = Instance.new("Highlight")
			selfHighlight.Name = "FreecamHighlight"
			selfHighlight.FillColor = (Options.HighlightColor and Options.HighlightColor.Value) or Color3.fromRGB(0, 255, 0)
			selfHighlight.OutlineColor = selfHighlight.FillColor
			selfHighlight.FillTransparency = 0.5
			selfHighlight.OutlineTransparency = 0
			selfHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			selfHighlight.Parent = character
		end
	end
	
	freecamConnection = RunService.RenderStepped:Connect(function(dt)
		if not freecamActive then return end
		
		local speed = (Options.FreecamSpeed and Options.FreecamSpeed.Value or 1) * 50 * dt
		local moveDir = Vector3.new()
		
		-- Tăng tốc khi giữ Shift
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			speed = speed * 3
		end
		
		-- Di chuyển WASD
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			moveDir = moveDir + freecamCF.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			moveDir = moveDir - freecamCF.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			moveDir = moveDir - freecamCF.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			moveDir = moveDir + freecamCF.RightVector
		end
		
		-- Lên xuống Q/E
		if UserInputService:IsKeyDown(Enum.KeyCode.E) then
			moveDir = moveDir + Vector3.new(0, 1, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
			moveDir = moveDir - Vector3.new(0, 1, 0)
		end
		
		-- Cập nhật vị trí
		if moveDir.Magnitude > 0 then
			moveDir = moveDir.Unit * speed
			freecamCF = freecamCF + moveDir
		end
		
		-- Xoay camera theo chuột
		local mouseDelta = UserInputService:GetMouseDelta()
		local sensitivity = 0.3
		
		if mouseDelta.Magnitude > 0 then
			local rotX = CFrame.Angles(0, -mouseDelta.X * sensitivity * dt * 10, 0)
			local rotY = CFrame.Angles(-mouseDelta.Y * sensitivity * dt * 10, 0, 0)
			
			-- Giới hạn góc nhìn lên/xuống
			local _, currentY, _ = freecamCF:ToEulerAnglesYXZ()
			local newY = currentY - mouseDelta.Y * sensitivity * dt * 10
			newY = math.clamp(newY, -math.rad(80), math.rad(80))
			
			freecamCF = CFrame.new(freecamCF.Position) * rotX * freecamCF.Rotation
			freecamCF = CFrame.new(freecamCF.Position) * CFrame.Angles(0, select(2, freecamCF:ToEulerAnglesYXZ()), 0) * CFrame.Angles(newY, 0, 0)
		end
		
		Camera.CFrame = freecamCF
	end)
	
	-- Lock mouse
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end

local function stopFreecam()
	if not freecamActive then return end
	freecamActive = false
	
	if freecamConnection then
		freecamConnection:Disconnect()
		freecamConnection = nil
	end
	
	-- Khôi phục camera
	if originalCameraType then
		Camera.CameraType = originalCameraType
	end
	if originalCameraSubject then
		Camera.CameraSubject = originalCameraSubject
	elseif humanoid then
		Camera.CameraSubject = humanoid
	end
	
	-- Xóa highlight bản thân
	if character then
		local selfHighlight = character:FindFirstChild("FreecamHighlight")
		if selfHighlight then
			selfHighlight:Destroy()
		end
	end
	
	-- Unlock mouse
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

Toggles.Freecam:OnChanged(function()
	if Toggles.Freecam.Value then
		startFreecam()
	else
		stopFreecam()
	end
end)

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
	-- Cleanup ESP
	for player, _ in pairs(espObjects) do
		removeESP(player)
	end
	for player, _ in pairs(highlightObjects) do
		removeHighlight(player)
	end

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

	-- Cleanup Anti AFK
	if antiAFKConnection then
		antiAFKConnection:Disconnect()
		antiAFKConnection = nil
	end

	-- Cleanup Freecam
	stopFreecam()

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

	-- Cleanup aimbot drawings
	if FOVCircle then
		pcall(function()
			FOVCircle.Visible = false
			FOVCircle:Remove()
		end)
		FOVCircle = nil
	end

	for i, line in ipairs(CrosshairLines) do
		if line then
			pcall(function()
				line.Visible = false
				line:Remove()
			end)
			CrosshairLines[i] = nil
		end
	end
end)

Library:Notify({
	Title = "Universal Script",
	Description = "Loaded successfully!",
	Time = 5,
})
