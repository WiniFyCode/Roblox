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
local flyBodyVelocity, flyBodyGyro
local noclipConnection
local espObjects = {}
local hitboxOriginals = {}
local highlightObjects = {}
local wsLoopConnection
local wsCharAddedConnection
local jpLoopConnection
local jpCharAddedConnection

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

MovementGroup:AddToggle("Fly", {
	Text = "Fly",
	Default = false,
	Tooltip = "Fly in the air",
})

MovementGroup:AddSlider("FlySpeed", {
	Text = "Fly Speed",
	Default = 50,
	Min = 1,
	Max = 200,
	Rounding = 0,
})

MovementGroup:AddLabel("Fly Keybind"):AddKeyPicker("FlyKeybind", {
	Default = "E",
	Mode = "Toggle",
	NoUI = false,
	Text = "Fly Keybind",
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

-- Fly
local function startFly()
	if not rootPart then return end
	
	flyBodyVelocity = Instance.new("BodyVelocity")
	flyBodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
	flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
	flyBodyVelocity.Parent = rootPart
	
	flyBodyGyro = Instance.new("BodyGyro")
	flyBodyGyro.MaxTorque = Vector3.new(4000, 4000, 4000)
	flyBodyGyro.CFrame = rootPart.CFrame
	flyBodyGyro.Parent = rootPart
end

local function stopFly()
	if flyBodyVelocity then
		flyBodyVelocity:Destroy()
		flyBodyVelocity = nil
	end
	if flyBodyGyro then
		flyBodyGyro:Destroy()
		flyBodyGyro = nil
	end
end

Toggles.Fly:OnChanged(function()
	if Toggles.Fly.Value then
		startFly()
	else
		stopFly()
	end
end)

Options.FlyKeybind:OnClick(function()
	Toggles.Fly:SetValue(not Toggles.Fly.Value)
end)

-- Fly Movement
RunService.Heartbeat:Connect(function()
	if Toggles.Fly.Value and flyBodyVelocity and flyBodyGyro and rootPart then
		local cam = Camera
		local moveVector = Vector3.new(0, 0, 0)
		
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			moveVector = moveVector + cam.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			moveVector = moveVector - cam.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			moveVector = moveVector - cam.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			moveVector = moveVector + cam.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			moveVector = moveVector + Vector3.new(0, 1, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			moveVector = moveVector - Vector3.new(0, 1, 0)
		end
		
		flyBodyVelocity.Velocity = moveVector * Options.FlySpeed.Value
		flyBodyGyro.CFrame = cam.CFrame
	end
end)

Options.FlySpeed:OnChanged(function()
	-- Speed updated in heartbeat
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
			for _, name in ipairs({"Head", "HumanoidRootPart", "UpperTorso"}) do
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

-- ============================================
-- COMBAT TAB - AIMBOT
-- ============================================
local AimbotGroup = Tabs.Combat:AddRightGroupbox("Aimbot", "crosshair")

AimbotGroup:AddToggle("Aimbot", {
	Text = "Aimbot",
	Default = false,
	Tooltip = "Automatically aim at targets",
	Risky = true,
})

AimbotGroup:AddToggle("AimbotShowFOV", {
	Text = "Show FOV",
	Default = true,
	Tooltip = "Show FOV circle",
})

AimbotGroup:AddSlider("AimbotFOV", {
	Text = "FOV Size",
	Default = 100,
	Min = 10,
	Max = 500,
	Rounding = 0,
})

AimbotGroup:AddSlider("AimbotSmoothness", {
	Text = "Smoothness",
	Default = 10,
	Min = 1,
	Max = 50,
	Rounding = 0,
})

AimbotGroup:AddDropdown("AimbotTarget", {
	Values = { "Players", "NPCs", "All" },
	Default = 1,
	Text = "Target Type",
})

AimbotGroup:AddDropdown("AimbotPart", {
	Values = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso" },
	Default = 1,
	Text = "Aim Part",
})

AimbotGroup:AddToggle("AimbotTeamCheck", {
	Text = "Team Check",
	Default = false,
	Tooltip = "Only aim at enemies",
})

AimbotGroup:AddLabel("FOV Color"):AddColorPicker("AimbotFOVColor", {
	Default = Color3.fromRGB(255, 255, 255),
	Title = "FOV Color",
})

AimbotGroup:AddLabel("Aimbot Keybind"):AddKeyPicker("AimbotKeybind", {
	Default = "Q",
	Mode = "Hold",
	NoUI = false,
	Text = "Aimbot Keybind",
})

-- Aimbot Variables
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = false
fovCircle.Transparency = 1
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Thickness = 2
fovCircle.Filled = false
fovCircle.NumSides = 100

-- Get Aimbot Targets
local function getAimbotTargets()
	local targets = {}
	local mode = Options.AimbotTarget and Options.AimbotTarget.Value or "Players"
	
	if mode == "Players" or mode == "All" then
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character then
				local hum = player.Character:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					-- Team check
					local shouldAdd = true
					if Toggles.AimbotTeamCheck and Toggles.AimbotTeamCheck.Value then
						local isEnemy = false
						if LocalPlayer.Team and player.Team then
							isEnemy = player.Team ~= LocalPlayer.Team
						elseif LocalPlayer.TeamColor and player.TeamColor then
							isEnemy = player.TeamColor ~= LocalPlayer.TeamColor
						else
							isEnemy = true
						end
						shouldAdd = isEnemy
					end
					
					if shouldAdd then
						table.insert(targets, player.Character)
					end
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

-- Get closest target within FOV
local function getClosestTargetInFOV()
	if not rootPart or not Camera then return nil end
	
	local targets = getAimbotTargets()
	local closestTarget = nil
	local closestDistance = math.huge
	local aimPart = Options.AimbotPart and Options.AimbotPart.Value or "Head"
	local fovRadius = Options.AimbotFOV and Options.AimbotFOV.Value or 100
	local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	
	for _, character in ipairs(targets) do
		local targetPart = character:FindFirstChild(aimPart)
		if not targetPart then
			targetPart = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
		end
		
		if targetPart then
			local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
			if onScreen then
				local screenPoint = Vector2.new(screenPos.X, screenPos.Y)
				local distance = (screenPoint - screenCenter).Magnitude
				
				if distance <= fovRadius and distance < closestDistance then
					closestDistance = distance
					closestTarget = targetPart
				end
			end
		end
	end
	
	return closestTarget, closestDistance
end

-- Smooth aim function
local function smoothAim(targetPart)
	if not targetPart or not Camera or not rootPart then return end
	
	local targetPosition = targetPart.Position
	local currentCFrame = Camera.CFrame
	local targetCFrame = CFrame.lookAt(currentCFrame.Position, targetPosition)
	
	local smoothness = Options.AimbotSmoothness and Options.AimbotSmoothness.Value or 10
	local smoothFactor = math.max(1, smoothness)
	
	local newCFrame = currentCFrame:Lerp(targetCFrame, 1 / smoothFactor)
	Camera.CFrame = newCFrame
end

-- Update FOV Circle
local function updateFOVCircle()
	if not Toggles.Aimbot.Value or not Toggles.AimbotShowFOV.Value then
		fovCircle.Visible = false
		return
	end
	
	fovCircle.Visible = true
	fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	fovCircle.Radius = Options.AimbotFOV and Options.AimbotFOV.Value or 100
	if Options.AimbotFOVColor then
		fovCircle.Color = Options.AimbotFOVColor.Value
	end
end

-- Aimbot Main Loop
RunService.Heartbeat:Connect(function()
	updateFOVCircle()
	
	if Toggles.Aimbot.Value and Options.AimbotKeybind:GetState() then
		local targetPart = getClosestTargetInFOV()
		if targetPart then
			smoothAim(targetPart)
		end
	end
end)

-- Aimbot Toggle
Toggles.Aimbot:OnChanged(function()
	if not Toggles.Aimbot.Value then
		fovCircle.Visible = false
	end
end)

Toggles.AimbotShowFOV:OnChanged(function()
	updateFOVCircle()
end)

Options.AimbotFOV:OnChanged(function()
	updateFOVCircle()
end)

Options.AimbotFOVColor:OnChanged(function()
	updateFOVCircle()
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
	
	espObjects[player] = espData
end

local function removeESP(player)
	local espData = espObjects[player]
	if espData then
		if espData.box then espData.box:Remove() end
		if espData.tracer then espData.tracer:Remove() end
		if espData.label then espData.label:Remove() end
		if espData.healthBar then espData.healthBar:Remove() end
		espObjects[player] = nil
	end
end

local function createHighlight(player)
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
	-- Parent vào CoreGui để đảm bảo luôn render trên mọi thứ (xuyên tường)
	highlight.Parent = CoreGui
	
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
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local humanoidRootPart = player.Character.HumanoidRootPart
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			local size = humanoidRootPart.Size + Vector3.new(2, 3, 1)
			local points, allVisible = getBoxScreenPoints(humanoidRootPart.CFrame, size)
			
			if espData then
				if not allVisible or #points == 0 then
					if espData.box then espData.box.Visible = false end
					if espData.tracer then espData.tracer.Visible = false end
					if espData.label then espData.label.Visible = false end
					if espData.healthBar then espData.healthBar.Visible = false end
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
									table.insert(parts, string.format("%s [%d]", player.Name, math.floor(humanoid.Health)))
								else
									table.insert(parts, player.Name)
								end
							end
							if Toggles.ESPDistance.Value and rootPart then
								local distance = math.floor((rootPart.Position - humanoidRootPart.Position).Magnitude)
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

TeleportGroup:AddToggle("ClickTP", {
	Text = "Click Teleport",
	Default = false,
	Tooltip = "Click to teleport",
})

TeleportGroup:AddLabel("Click TP Keybind"):AddKeyPicker("ClickTPKeybind", {
	Default = "T",
	Mode = "Toggle",
	NoUI = false,
	Text = "Click TP Keybind",
})

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

-- Click TP
local clickTPConnection
Toggles.ClickTP:OnChanged(function()
	if Toggles.ClickTP.Value then
		clickTPConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 and Options.ClickTPKeybind:GetState() then
				local mouse = LocalPlayer:GetMouse()
				if rootPart then
					rootPart.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
				end
			end
		end)
	else
		if clickTPConnection then
			clickTPConnection:Disconnect()
			clickTPConnection = nil
		end
	end
end)

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
			return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
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
				local display = string.format("%d/%s|ping: %s|fps: %s|%s", currentPlayers, maxPlayers, tostring(ping), tostring(fps), shortId)
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
		local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
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
	-- Cleanup ESP
	for player, _ in pairs(espObjects) do
		removeESP(player)
	end
	for player, _ in pairs(highlightObjects) do
		removeHighlight(player)
	end
	
	-- Cleanup Aimbot FOV
	if fovCircle then
		fovCircle:Remove()
		fovCircle = nil
	end
	
	-- Cleanup Fly
	stopFly()
	
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
	
	-- Cleanup Click TP
	if clickTPConnection then
		clickTPConnection:Disconnect()
		clickTPConnection = nil
	end
	
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

