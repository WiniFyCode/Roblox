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

local flyBV
local flyGyro
local flyConnection

local hipHeightOriginal
local hipHeightConnection
local airWalkPart
local airWalkConnection
local airBaseY
local airGroundY

local checkpoints = {}
local checkpointNames = {}

-- ESP Variables
local espObjects = {}
local espHighlights = {}
local hasDrawingAPI = false
local highlightUpdateTick = 0

-- Aimbot/Tâm Ảo Variables
local autoShootConnection
local lastAutoShootTime = 0
local crosshairLines = {}
local crosshairDot = nil


-- Get Character
local function getCharacter()
	character = LocalPlayer.Character
	if character then
		humanoid = character:FindFirstChildOfClass("Humanoid")
		rootPart = character:FindFirstChild("HumanoidRootPart")
	end
	return character, humanoid, rootPart
end

-- Helper function để simulate mouse click
local function mouse1click()
	-- Simulate mouse click bằng cách fire các connections
	local mouse = LocalPlayer:GetMouse()
	if mouse then
		-- Fire Button1Down event
		for _, connection in pairs(getconnections(mouse.Button1Down)) do
			pcall(function()
				connection:Fire()
			end)
		end
		-- Fire Button1Up event
		task.wait(0.01)
		for _, connection in pairs(getconnections(mouse.Button1Up)) do
			pcall(function()
				connection:Fire()
			end)
		end
	end
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

MovementGroup:AddToggle("FlyEnabled", {
	Text = "Fly",
	Default = false,
	Tooltip = "Fly freely in air",
})

MovementGroup:AddSlider("FlySpeed", {
	Text = "Fly Speed",
	Default = 80,
	Min = 10,
	Max = 300,
	Rounding = 0,
})

MovementGroup:AddToggle("HipHeightEnabled", {
	Text = "Hip Height (Walk In Air)",
	Default = false,
	Tooltip = "Raise hip height to walk above ground",
})

MovementGroup:AddSlider("HipHeightValue", {
	Text = "Hip Height",
	Default = 5,
	Min = 0,
	Max = 50,
	Rounding = 1,
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

-- Fly
local function stopFly()
	if flyConnection then
		flyConnection:Disconnect()
		flyConnection = nil
	end
	if flyBV then
		pcall(function()
			flyBV:Destroy()
		end)
		flyBV = nil
	end
	if flyGyro then
		pcall(function()
			flyGyro:Destroy()
		end)
		flyGyro = nil
    end
if humanoid then
		humanoid.PlatformStand = false
	end
	if rootPart then
		-- Reset lại hướng đứng cho thẳng, giữ nguyên góc quay theo trục Y
		local cf = rootPart.CFrame
		local pos = cf.Position
		local _, y, _ = cf:ToEulerAnglesYXZ()
		rootPart.CFrame = CFrame.new(pos) * CFrame.Angles(0, y, 0)
		-- Xoá vận tốc còn sót để không bị drift
		pcall(function()
			rootPart.AssemblyLinearVelocity = Vector3.new()
			rootPart.AssemblyAngularVelocity = Vector3.new()
		end)
	end
end

local function startFly()
	getCharacter()
	if not rootPart or not humanoid then
		Library:Notify({
			Title = "Fly",
			Description = "Could not find your character",
			Time = 3,
		})
		if Toggles.FlyEnabled then
			Toggles.FlyEnabled:SetValue(false)
		end
		return
	end

	stopFly()

	flyBV = Instance.new("BodyVelocity")
	flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	flyBV.P = 9e4
	flyBV.Velocity = Vector3.new()
	flyBV.Parent = rootPart

	flyGyro = Instance.new("BodyGyro")
	flyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
	flyGyro.P = 9e4
	flyGyro.CFrame = rootPart.CFrame
	flyGyro.Parent = rootPart

	flyConnection = RunService.RenderStepped:Connect(function()
		if not rootPart or not humanoid then
			stopFly()
			return
		end

		humanoid.PlatformStand = true

		-- Giữ hướng ổn định bằng BodyGyro
		if flyGyro then
			flyGyro.CFrame = CFrame.new(rootPart.Position, rootPart.Position + Camera.CFrame.LookVector)
		end

		local moveDir = Vector3.new(0, 0, 0)
		local camCF = Camera.CFrame

		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			moveDir = moveDir + camCF.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			moveDir = moveDir - camCF.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			moveDir = moveDir - camCF.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			moveDir = moveDir + camCF.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			moveDir = moveDir + Vector3.new(0, 1, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			moveDir = moveDir + Vector3.new(0, -1, 0)
		end

		if moveDir.Magnitude > 0 then
			moveDir = moveDir.Unit
		end

		local speed = (Options.FlySpeed and Options.FlySpeed.Value) or 80
		flyBV.Velocity = moveDir * speed
	end)
end

if Toggles.FlyEnabled then
	Toggles.FlyEnabled:OnChanged(function()
		if Toggles.FlyEnabled.Value then
			startFly()
		else
			stopFly()
		end
	end)
end

if Options.FlySpeed then
	Options.FlySpeed:OnChanged(function()
		if flyBV and Toggles.FlyEnabled and Toggles.FlyEnabled.Value then
			local speed = (Options.FlySpeed and Options.FlySpeed.Value) or 80
			local currentDir = flyBV.Velocity.Magnitude > 0 and flyBV.Velocity.Unit or Vector3.new()
			flyBV.Velocity = currentDir * speed
		end
	end)
end

-- Hip Height (walk in air)
local function applyHipHeight()
	if humanoid and Toggles.HipHeightEnabled and Toggles.HipHeightEnabled.Value then
		local value = (Options.HipHeightValue and Options.HipHeightValue.Value) or humanoid.HipHeight
		humanoid.HipHeight = value
	end
end

if Toggles.HipHeightEnabled then
	Toggles.HipHeightEnabled:OnChanged(function()
		if Toggles.HipHeightEnabled.Value then
			if humanoid then
				hipHeightOriginal = humanoid.HipHeight
			end

			if hipHeightConnection then
				hipHeightConnection:Disconnect()
				hipHeightConnection = nil
			end

			applyHipHeight()

			-- Giữ HipHeight ổn định khi game cố đổi
			if humanoid then
				if hipHeightConnection then
					hipHeightConnection:Disconnect()
					hipHeightConnection = nil
				end
				hipHeightConnection = humanoid:GetPropertyChangedSignal("HipHeight"):Connect(function()
					if Toggles.HipHeightEnabled and Toggles.HipHeightEnabled.Value then
						applyHipHeight()
					end
				end)
			end
		else
			if hipHeightConnection then
				hipHeightConnection:Disconnect()
				hipHeightConnection = nil
			end

			if humanoid and hipHeightOriginal ~= nil then
				humanoid.HipHeight = hipHeightOriginal
			end
		end
	end)
end

if Options.HipHeightValue then
	Options.HipHeightValue:OnChanged(function()
		if Toggles.HipHeightEnabled and Toggles.HipHeightEnabled.Value then
			applyHipHeight()
		end
	end)
end

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
					if not (Toggles.AimbotTeamCheck.Value and player.Team == LocalPlayer.Team) then
						table.insert(targets, {char = player.Character, isPlayer = true, player = player})
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
	if Toggles.Hitbox.Value then
		applyHitbox()
	end
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
		Box3D = nil -- Lazy load - chỉ tạo khi cần
	}
	-- Pre-create skeleton lines (max 14 for R15)
	for i = 1, 14 do
		elements.Skeleton[i] = newDrawing("Line", {Visible = false, Thickness = 1.5, Color = Color3.fromRGB(0, 255, 0)})
	end
	return elements
end

-- Lazy create 3D box lines khi cần
local function ensure3DBoxLines(data)
	if data.Box3D then return end
	data.Box3D = {}
	for i = 1, 72 do
		data.Box3D[i] = newDrawing("Line", {Visible = false, Thickness = 1, Color = Color3.fromRGB(0, 255, 0)})
	end
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

-- 6 body parts chính cho 3D box (giảm từ 15 xuống 6)
local bodyParts3D_R15 = {"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg"}
local bodyParts3D_R6 = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}

local function getBodyParts3D(char)
	if char:FindFirstChild("UpperTorso") then
		return bodyParts3D_R15
	else
		return bodyParts3D_R6
	end
end

-- Draw 3D box for a single part
local function drawPart3DBox(part, lines, startIndex, color)
	if not part or not part:IsA("BasePart") then
		for i = startIndex, startIndex + 11 do
			if lines[i] then lines[i].Visible = false end
		end
		return startIndex + 12
	end
	
	local corners = get3DBoxCorners(part.CFrame, part.Size)
	
	for i, edge in ipairs(box3DEdges) do
		local line = lines[startIndex + i - 1]
		if line then
			local c1, c2 = corners[edge[1]], corners[edge[2]]
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

-- Draw 3D boxes for character body parts
local function draw3DBoxes(data, char, color)
	if not data.Box3D or not char then return end
	
	local bodyParts = getBodyParts3D(char)
	local lineIndex = 1
	
	for _, partName in ipairs(bodyParts) do
		local part = char:FindFirstChild(partName)
		lineIndex = drawPart3DBox(part, data.Box3D, lineIndex, color)
	end
	
	-- Hide unused lines
	for i = lineIndex, #data.Box3D do
		if data.Box3D[i] then data.Box3D[i].Visible = false end
	end
end

local function hide3DBox(data)
	if not data.Box3D then return end
	for _, line in ipairs(data.Box3D) do
		line.Visible = false
	end
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

	-- Tạo ESP elements nếu chưa có (on-demand như Ryzex)
	if not espObjects[player] then
		espObjects[player] = createESPElements()
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
	local rawRatio = maxHp > 0 and hp / maxHp or 0
	local ratio = math.min(math.max(rawRatio, 0), 1)

	-- 2D Box
	if Toggles.ESPBoxes.Value then
		data.Box.Visible = true
		data.Box.Position = Vector2.new(slimX, minY)
		data.Box.Size = Vector2.new(slimWidth, boxHeight)
		data.Box.Color = baseColor
	else
		data.Box.Visible = false
	end

	-- 3D Box (6 body parts - balanced detail vs performance)
	if Toggles.ESP3DBox and Toggles.ESP3DBox.Value then
		ensure3DBoxLines(data) -- Lazy load - chỉ tạo khi bật
		draw3DBoxes(data, player.Character, baseColor)
	elseif data.Box3D then
		hide3DBox(data)
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

-- Crosshair (Tâm Ảo) - Vẽ crosshair ở giữa màn hình
local function createCrosshair()
	if not hasDrawingAPI then return end
	
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
	if not Toggles.CrosshairEnabled or not Toggles.CrosshairEnabled.Value then
		for _, line in ipairs(crosshairLines) do
			if line then line.Visible = false end
		end
		if crosshairDot then crosshairDot.Visible = false end
		return
	end
	
	if not hasDrawingAPI then
		createCrosshair()
		return
	end
	
	local screenSize = Camera.ViewportSize
	local centerX = screenSize.X / 2
	local centerY = screenSize.Y / 2
	
	local size = Options.CrosshairSize and Options.CrosshairSize.Value or 10
	local thickness = Options.CrosshairThickness and Options.CrosshairThickness.Value or 1
	local color = Options.CrosshairColor and Options.CrosshairColor.Value or Color3.fromRGB(255, 255, 255)
	
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
		crosshairDot.Visible = Toggles.CrosshairDot and Toggles.CrosshairDot.Value or false
		crosshairDot.Position = Vector2.new(centerX, centerY)
		crosshairDot.Color = color
	end
end

-- Initialize crosshair
createCrosshair()

-- ESP Update Loop
local mainRenderConnection
mainRenderConnection = RunService.RenderStepped:Connect(function()
	updateESP()
	
	-- Highlight update mỗi 10 frames (giảm tải)
	highlightUpdateTick = highlightUpdateTick + 1
	if highlightUpdateTick >= 10 then
		highlightUpdateTick = 0
		if Toggles.PlayerESP.Value and Toggles.ESPHighlight.Value then
			updateHighlights()
		end
	end
	
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
					alpha = math.min(math.max(alpha, 0.01), 1)
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
	
	-- Trigger Bot Logic
	if Toggles.TriggerBotEnabled and Toggles.TriggerBotEnabled.Value then
		local mousePos = UserInputService:GetMouseLocation()
		local targetChar, targetPart = getClosestAimbotTarget()
		
		if targetChar and targetPart then
			local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
			if onScreen and screenPos.Z > 0 then
				local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
				-- Nếu crosshair gần target (trong vòng 20 pixels)
				if dist < 20 then
					local delay = Options.TriggerBotDelay and Options.TriggerBotDelay.Value or 50
					task.spawn(function()
						task.wait(delay / 1000)
						pcall(mouse1click)
					end)
				end
			end
		end
	end
	
	-- Update Crosshair (Tâm Ảo)
	updateCrosshair()
end)

-- Auto Shoot Logic
if Toggles.AutoShootEnabled then
	Toggles.AutoShootEnabled:OnChanged(function()
		if Toggles.AutoShootEnabled.Value then
			autoShootConnection = RunService.Heartbeat:Connect(function()
				local currentTime = tick()
				local delay = Options.AutoShootDelay and Options.AutoShootDelay.Value or 100
				
				if currentTime - lastAutoShootTime >= (delay / 1000) then
					local targetChar, targetPart = getClosestAimbotTarget()
					
					if targetChar and targetPart then
						-- Kiểm tra FOV
						local fov = Options.AimbotFOV and Options.AimbotFOV.Value or 150
						local mousePos = UserInputService:GetMouseLocation()
						local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
						
						if onScreen and screenPos.Z > 0 then
							local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
							if dist <= fov then
								-- Auto shoot
								pcall(mouse1click)
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

-- Teleport tới player khác
TeleportGroup:AddDropdown("TeleportPlayer", {
	SpecialType = "Player",
	ExcludeLocalPlayer = true,
	Text = "Teleport To Player",
})

TeleportGroup:AddButton({
	Text = "Teleport To Player",
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
		else
			Library:Notify({
				Title = "Teleport",
				Description = "Không tìm thấy nhân vật của player",
				Time = 3,
			})
		end
	end,
})

-- Checkpoint Group (Right)
local CheckpointGroup = Tabs.Teleport:AddRightGroupbox("Checkpoint", "bookmark")

-- Checkpoint system (already defined above, just need dropdown)
local checkpointDropdown

-- Folder chứa tất cả checkpoint trong Workspace
local checkpointFolder = Workspace:FindFirstChild("WiniFy_Checkpoints")
if not checkpointFolder then
	checkpointFolder = Instance.new("Folder")
	checkpointFolder.Name = "WiniFy_Checkpoints"
	checkpointFolder.Parent = Workspace
end

local function createCheckpointVisual(cf, name, color)
	if not checkpointFolder or not checkpointFolder.Parent then
		checkpointFolder = Workspace:FindFirstChild("WiniFy_Checkpoints") or Instance.new("Folder")
		checkpointFolder.Name = "WiniFy_Checkpoints"
		checkpointFolder.Parent = Workspace
	end

	local checkpointColor = color or (Options.CheckpointColor and Options.CheckpointColor.Value) or Color3.fromRGB(0, 255, 255)

	local container = Instance.new("Folder")
	container.Name = "Checkpoint_" .. (name or "Unknown")
	container.Parent = checkpointFolder

	-- Base hình hộp (khối neon)
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Anchored = true
	base.CanCollide = false
	base.Size = Vector3.new(3, 4, 3) -- hình hộp đứng, dễ nhìn
	base.Material = Enum.Material.Neon
	base.Color = checkpointColor
	base.CFrame = cf
	base.Parent = container

	-- Highlight (viền sáng quanh hình hộp)
	local hl = Instance.new("Highlight")
	hl.Name = "CheckpointHighlight"
	hl.Adornee = base
	hl.FillColor = checkpointColor
	hl.OutlineColor = checkpointColor
	hl.FillTransparency = 0.8
	hl.OutlineTransparency = 0
	hl.Parent = container

	-- Particles nhẹ cho đẹp
	local attach = Instance.new("Attachment")
	attach.Name = "ParticleAttachment"
	attach.Parent = base

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "CheckpointParticles"
	emitter.Rate = 8
	emitter.Lifetime = NumberRange.new(1, 2)
	emitter.Speed = NumberRange.new(0.5, 1.5)
	emitter.VelocitySpread = 45
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.LightEmission = 1
	emitter.Texture = "rbxassetid://2418769698"
	emitter.Color = ColorSequence.new(checkpointColor)
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = attach

	-- Bảng tên nổi (BillboardGui)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "CheckpointBillboard"
	billboard.Adornee = base
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.new(0, 200, 0, 40)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 0) -- nổi phía trên hộp
	billboard.Parent = container

	local label = Instance.new("TextLabel")
	label.Name = "NameLabel"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = name or "Checkpoint"
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.TextColor3 = checkpointColor
	label.TextStrokeTransparency = 0.3
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.Parent = billboard

	return {
		container = container,
		base = base,
		highlight = hl,
		emitter = emitter,
		label = label,
	}
end

local function updateCheckpointColor(cp, color)
	if not cp or not cp.visual then return end
	local visual = cp.visual
	
	if visual.base then
		visual.base.Color = color
	end
	if visual.highlight then
		visual.highlight.FillColor = color
		visual.highlight.OutlineColor = color
	end
	if visual.emitter then
		visual.emitter.Color = ColorSequence.new(color)
	end
	if visual.label then
		visual.label.TextColor3 = color
	end
end

local function destroyCheckpointVisual(cp)
	if cp and cp.visual and cp.visual.container then
		pcall(function()
			cp.visual.container:Destroy()
		end)
	end
end

local function findCheckpointIndexByName(name)
	for i, n in ipairs(checkpointNames) do
		if n == name then
			return i
		end
	end
	return nil
end

local checkpointCountLabel = nil -- Will be initialized later

local function updateCheckpointCount()
	if checkpointCountLabel then
		checkpointCountLabel:SetText("Checkpoints: " .. tostring(#checkpoints))
	end
end

local function refreshCheckpointDropdown()
	if checkpointDropdown then
		checkpointDropdown:SetValues(checkpointNames)
	end
	updateCheckpointCount()
end

-- Save/Load Checkpoints
local checkpointFileName = "WiniFy_Checkpoints_" .. tostring(game.PlaceId) .. ".json"

local function saveCheckpointsToFile(showNotification)
        local success, result = pcall(function()
            local dataToSave = {}
		for _, cp in ipairs(checkpoints) do
			-- Convert CFrame to serializable format
			local cf = cp.cf
			local pos = cf.Position
			local x, y, z = cf:ToEulerAnglesXYZ()
			
			table.insert(dataToSave, {
				name = cp.name,
				position = {X = pos.X, Y = pos.Y, Z = pos.Z},
				rotation = {X = x, Y = y, Z = z},
				color = {R = cp.color.R, G = cp.color.G, B = cp.color.B}
			})
		end
		
		local json = HttpService:JSONEncode(dataToSave)
		writefile(checkpointFileName, json)
		return true
	end)
	
        if success then
            if showNotification ~= false then
			Library:Notify({
				Title = "Checkpoint",
				Description = "Saved " .. tostring(#checkpoints) .. " checkpoint(s)",
				Time = 3,
			})
		end
		return true
	else
		if showNotification ~= false then
			Library:Notify({
				Title = "Checkpoint",
				Description = "Failed to save checkpoints",
				Time = 3,
			})
		end
		return false
	end
end

local function loadCheckpointsFromFile(showNotification)
        local success, result = pcall(function()
            if not isfile(checkpointFileName) then
			return false
		end
		
		local fileContent = readfile(checkpointFileName)
		if not fileContent or fileContent == "" then
			return false
		end
		
		local data = HttpService:JSONDecode(fileContent)
		if not data or type(data) ~= "table" then
			return false
		end
		
		-- Clear existing checkpoints
		for _, cp in ipairs(checkpoints) do
			destroyCheckpointVisual(cp)
		end
		checkpoints = {}
		checkpointNames = {}
		
		-- Load checkpoints
		for _, savedCp in ipairs(data) do
			local pos = Vector3.new(savedCp.position.X, savedCp.position.Y, savedCp.position.Z)
			local color = Color3.new(savedCp.color.R, savedCp.color.G, savedCp.color.B)
			
			-- Handle CFrame - try to use rotation if available, otherwise just position
			local cf
			if savedCp.rotation then
				cf = CFrame.new(pos) * CFrame.Angles(savedCp.rotation.X, savedCp.rotation.Y, savedCp.rotation.Z)
			else
				cf = CFrame.new(pos)
			end
			
			local visual = createCheckpointVisual(cf, savedCp.name, color)
			table.insert(checkpoints, { name = savedCp.name, cf = cf, visual = visual, color = color })
			table.insert(checkpointNames, savedCp.name)
		end
		
		refreshCheckpointDropdown()
		return true
	end)
	
	if success and result then
		if showNotification ~= false then
			Library:Notify({
				Title = "Checkpoint",
				Description = "Loaded " .. tostring(#checkpoints) .. " checkpoint(s)",
				Time = 3,
			})
		end
		return true
	else
		if showNotification ~= false and isfile(checkpointFileName) then
			Library:Notify({
				Title = "Checkpoint",
				Description = "Failed to load checkpoints",
				Time = 3,
			})
		end
		return false
	end
end

local function addCheckpoint(name)
	if not rootPart then
		Library:Notify({
			Title = "Checkpoint",
			Description = "Could not find your character (rootPart = nil)",
			Time = 3,
		})
		return
	end

	if not name or name == "" then
		name = "Checkpoint " .. tostring(#checkpoints + 1)
	end

	-- Check for duplicate name
	if findCheckpointIndexByName(name) then
		Library:Notify({
			Title = "Checkpoint",
			Description = "Checkpoint name already exists: " .. name,
			Time = 3,
		})
		return
	end

	local cf = rootPart.CFrame
	local color = Options.CheckpointColor and Options.CheckpointColor.Value or Color3.fromRGB(0, 255, 255)
	local visual = createCheckpointVisual(cf, name, color)

	table.insert(checkpoints, { name = name, cf = cf, visual = visual, color = color })
	table.insert(checkpointNames, name)
	refreshCheckpointDropdown()
	
	-- Auto save (silent)
	saveCheckpointsToFile(false)

	Library:Notify({
		Title = "Checkpoint",
		Description = "Saved checkpoint: " .. name,
		Time = 3,
	})
end

CheckpointGroup:AddLabel("Checkpoint Color"):AddColorPicker("CheckpointColor", {
	Default = Color3.fromRGB(0, 255, 255),
	Title = "Checkpoint Color",
})

-- Update color for all checkpoints when color changes
Options.CheckpointColor:OnChanged(function(newColor)
	for _, cp in ipairs(checkpoints) do
		updateCheckpointColor(cp, newColor)
		cp.color = newColor
	end
end)

CheckpointGroup:AddInput("CheckpointName", {
	Text = "Checkpoint Name",
	Default = "",
	Placeholder = "Leave empty = auto name",
})

CheckpointGroup:AddButton({
	Text = "Save Checkpoint",
	Func = function()
		local name = Options.CheckpointName and Options.CheckpointName.Value or ""
		addCheckpoint(name)
	end,
})

-- Checkpoint count label
checkpointCountLabel = CheckpointGroup:AddLabel("Checkpoints: 0")
updateCheckpointCount() -- Initialize count

checkpointDropdown = CheckpointGroup:AddDropdown("CheckpointList", {
	Values = {},
	Text = "Saved Checkpoints",
})

local function updateCheckpointCount()
	if checkpointCountLabel then
		checkpointCountLabel:SetText("Checkpoints: " .. tostring(#checkpoints))
	end
end

CheckpointGroup:AddButton({
	Text = "Teleport To Checkpoint",
	Func = function()
		if not rootPart then
			Library:Notify({
				Title = "Checkpoint",
				Description = "Could not find your character (rootPart = nil)",
				Time = 3,
			})
			return
		end

		local selected = Options.CheckpointList and Options.CheckpointList.Value or nil
		if not selected or selected == "" then
			Library:Notify({
				Title = "Checkpoint",
				Description = "You haven't selected any checkpoint",
				Time = 3,
			})
			return
		end

		local index = findCheckpointIndexByName(selected)
		if not index then
			Library:Notify({
				Title = "Checkpoint",
				Description = "Checkpoint does not exist (possibly just deleted)",
				Time = 3,
			})
			return
		end

		local cp = checkpoints[index]
		if cp and cp.cf then
			rootPart.CFrame = cp.cf
			Library:Notify({
				Title = "Checkpoint",
				Description = "Teleported to: " .. cp.name,
				Time = 3,
			})
		else
			Library:Notify({
				Title = "Checkpoint",
				Description = "Invalid checkpoint data",
				Time = 3,
			})
		end
	end,
})

CheckpointGroup:AddButton({
	Text = "Delete Checkpoint",
	Func = function()
		local selected = Options.CheckpointList and Options.CheckpointList.Value or nil
		if not selected or selected == "" then
			Library:Notify({
				Title = "Checkpoint",
				Description = "You haven't selected any checkpoint to delete",
				Time = 3,
			})
			return
		end

		local index = findCheckpointIndexByName(selected)
		if not index then
			Library:Notify({
				Title = "Checkpoint",
				Description = "Checkpoint does not exist",
				Time = 3,
			})
			return
		end

		local cp = checkpoints[index]
		destroyCheckpointVisual(cp)

		table.remove(checkpoints, index)
		table.remove(checkpointNames, index)
		refreshCheckpointDropdown()
		
		-- Auto save (silent)
		saveCheckpointsToFile(false)

		Library:Notify({
			Title = "Checkpoint",
			Description = "Deleted checkpoint: " .. selected,
			Time = 3,
		})
	end,
})

CheckpointGroup:AddButton({
	Text = "Rename Checkpoint",
	Func = function()
		local selected = Options.CheckpointList and Options.CheckpointList.Value or nil
		if not selected or selected == "" then
			Library:Notify({
				Title = "Checkpoint",
				Description = "You haven't selected any checkpoint to rename",
				Time = 3,
			})
			return
		end

		local index = findCheckpointIndexByName(selected)
		if not index then
			Library:Notify({
				Title = "Checkpoint",
				Description = "Checkpoint does not exist",
				Time = 3,
			})
			return
		end

		local newName = Options.CheckpointName and Options.CheckpointName.Value or ""
		if not newName or newName == "" then
			Library:Notify({
				Title = "Checkpoint",
				Description = "Please enter a new name",
				Time = 3,
			})
			return
		end

		-- Check for duplicate name
		if findCheckpointIndexByName(newName) and newName ~= selected then
			Library:Notify({
				Title = "Checkpoint",
				Description = "Checkpoint name already exists: " .. newName,
				Time = 3,
			})
			return
		end

		local cp = checkpoints[index]
		cp.name = newName
		checkpointNames[index] = newName
		
		-- Update visual label
		if cp.visual and cp.visual.label then
			cp.visual.label.Text = newName
		end
		
		refreshCheckpointDropdown()
		
		-- Update dropdown selection
		if checkpointDropdown then
			checkpointDropdown:SetValue(newName)
		end
		
		-- Auto save (silent)
		saveCheckpointsToFile(false)

		Library:Notify({
			Title = "Checkpoint",
			Description = "Renamed to: " .. newName,
			Time = 3,
		})
	end,
})

CheckpointGroup:AddButton({
	Text = "Delete All Checkpoints",
	Func = function()
		if #checkpoints == 0 then
			Library:Notify({
				Title = "Checkpoint",
				Description = "No checkpoints to delete",
				Time = 3,
			})
			return
		end

		for _, cp in ipairs(checkpoints) do
			destroyCheckpointVisual(cp)
		end

		local count = #checkpoints
		checkpoints = {}
		checkpointNames = {}
		refreshCheckpointDropdown()
		
		-- Auto save (silent)
		saveCheckpointsToFile(false)

		Library:Notify({
			Title = "Checkpoint",
			Description = "Deleted " .. tostring(count) .. " checkpoint(s)",
			Time = 3,
		})
	end,
	Risky = true,
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

-- Auto load checkpoints on startup
task.wait(1) -- Wait a bit for character to load
loadCheckpointsFromFile(false) -- Silent load

-- Cleanup
Library:OnUnload(function()
	-- Disconnect main render loop FIRST
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

	-- Cleanup Fly
	stopFly()

	-- Cleanup HipHeight / AirWalk
	if airWalkConnection then
		airWalkConnection:Disconnect()
		airWalkConnection = nil
	end
	if airWalkPart then
		pcall(function()
			airWalkPart:Destroy()
		end)
		airWalkPart = nil
	end
	if humanoid and hipHeightOriginal ~= nil then
		humanoid.HipHeight = hipHeightOriginal
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

	-- Cleanup checkpoints & visuals
	if checkpoints then
		for _, cp in ipairs(checkpoints) do
			destroyCheckpointVisual(cp)
		end
	end
	checkpoints = {}
	checkpointNames = {}

	if checkpointFolder and checkpointFolder.Parent then
		pcall(function()
			checkpointFolder:Destroy()
		end)
	end
end)

Library:Notify({
	Title = "Universal Script",
	Description = "Loaded successfully!",
	Time = 5,
})
