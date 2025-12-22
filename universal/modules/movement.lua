--[[
    Movement Module - Universal Script
    Tab Main - Speed, Jump, Noclip, Fly, HipHeight
]]

local Movement = {}
local Config = nil
local UI = nil

-- Variables
local noclipConnection
local wsLoopConnection
local wsCharAddedConnection
local jpLoopConnection
local jpCharAddedConnection
local flyBV
local flyGyro
local flyConnection
local hipHeightOriginal
local hipHeightConnection

----------------------------------------------------------
-- 🔹 Initialize
function Movement.init(config, ui)
	Config = config
	UI = ui
end

----------------------------------------------------------
-- 🔹 Create Tab
function Movement.createTab()
	local MovementGroup = UI.Tabs.Main:AddLeftGroupbox("Movement", "move")
	
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
		if Config.humanoid and UI.Toggles.SpeedHack.Value then
			Config.humanoid.WalkSpeed = UI.Options.SpeedValue.Value
		end
	end
	
	local function setupWalkSpeedLoop()
		if not Config.humanoid then return end
		
		if wsLoopConnection then
			wsLoopConnection:Disconnect()
			wsLoopConnection = nil
		end
		
		wsLoopConnection = Config.humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
			if UI.Toggles.SpeedHack.Value then
				applyWalkSpeed()
			end
		end)
		
		if wsCharAddedConnection then
			wsCharAddedConnection:Disconnect()
			wsCharAddedConnection = nil
		end
		
		wsCharAddedConnection = Config.LocalPlayer.CharacterAdded:Connect(function()
			Config.getCharacter()
			applyWalkSpeed()
			if Config.humanoid then
				if wsLoopConnection then
					wsLoopConnection:Disconnect()
					wsLoopConnection = nil
				end
				wsLoopConnection = Config.humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
					if UI.Toggles.SpeedHack.Value then
						applyWalkSpeed()
					end
				end)
			end
		end)
	end
	
	UI.Toggles.SpeedHack:OnChanged(function()
		if UI.Toggles.SpeedHack.Value then
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
			if Config.humanoid then
				Config.humanoid.WalkSpeed = 16
			end
		end
	end)
	
	UI.Options.SpeedValue:OnChanged(function()
		if UI.Toggles.SpeedHack.Value then
			applyWalkSpeed()
		end
	end)
	
	-- Jump Power (loop style giống SpeedHack)
	local function applyJumpPower()
		if Config.humanoid and UI.Toggles.JumpPower.Value then
			Config.humanoid.JumpPower = UI.Options.JumpValue.Value
		end
	end
	
	local function setupJumpPowerLoop()
		if not Config.humanoid then return end
		
		if jpLoopConnection then
			jpLoopConnection:Disconnect()
			jpLoopConnection = nil
		end
		
		jpLoopConnection = Config.humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
			if UI.Toggles.JumpPower.Value then
				applyJumpPower()
			end
		end)
		
		if jpCharAddedConnection then
			jpCharAddedConnection:Disconnect()
			jpCharAddedConnection = nil
		end
		
		jpCharAddedConnection = Config.LocalPlayer.CharacterAdded:Connect(function()
			Config.getCharacter()
			applyJumpPower()
			if Config.humanoid then
				if jpLoopConnection then
					jpLoopConnection:Disconnect()
					jpLoopConnection = nil
				end
				jpLoopConnection = Config.humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
					if UI.Toggles.JumpPower.Value then
						applyJumpPower()
					end
				end)
			end
		end)
	end
	
	UI.Toggles.JumpPower:OnChanged(function()
		if UI.Toggles.JumpPower.Value then
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
			if Config.humanoid then
				Config.humanoid.JumpPower = 50
			end
		end
	end)
	
	UI.Options.JumpValue:OnChanged(function()
		if UI.Toggles.JumpPower.Value then
			applyJumpPower()
		end
	end)
	
	-- Noclip
	UI.Toggles.Noclip:OnChanged(function()
		if UI.Toggles.Noclip.Value then
			if noclipConnection then
				noclipConnection:Disconnect()
			end
			noclipConnection = Config.RunService.Stepped:Connect(function()
				if Config.character then
					for _, part in pairs(Config.character:GetDescendants()) do
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
			if Config.character then
				for _, part in pairs(Config.character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = true
					end
				end
			end
		end
	end)
	
	-- Infinite Jump
	Config.UserInputService.JumpRequest:Connect(function()
		if UI.Toggles.InfiniteJump.Value and Config.humanoid then
			Config.humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
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
		if Config.humanoid then
			Config.humanoid.PlatformStand = false
		end
		if Config.rootPart then
			-- Reset lại hướng đứng cho thẳng, giữ nguyên góc quay theo trục Y
			local cf = Config.rootPart.CFrame
			local pos = cf.Position
			local _, y, _ = cf:ToEulerAnglesYXZ()
			Config.rootPart.CFrame = CFrame.new(pos) * CFrame.Angles(0, y, 0)
			-- Xoá vận tốc còn sót để không bị drift
			pcall(function()
				Config.rootPart.AssemblyLinearVelocity = Vector3.new()
				Config.rootPart.AssemblyAngularVelocity = Vector3.new()
			end)
		end
	end
	
	local function startFly()
		Config.getCharacter()
		if not Config.rootPart or not Config.humanoid then
			UI.Library:Notify({
				Title = "Fly",
				Description = "Could not find your character",
				Time = 3,
			})
			if UI.Toggles.FlyEnabled then
				UI.Toggles.FlyEnabled:SetValue(false)
			end
			return
		end
		
		stopFly()
		
		flyBV = Instance.new("BodyVelocity")
		flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
		flyBV.P = 9e4
		flyBV.Velocity = Vector3.new()
		flyBV.Parent = Config.rootPart
		
		flyGyro = Instance.new("BodyGyro")
		flyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
		flyGyro.P = 9e4
		flyGyro.CFrame = Config.rootPart.CFrame
		flyGyro.Parent = Config.rootPart
		
		flyConnection = Config.RunService.RenderStepped:Connect(function()
			if not Config.rootPart or not Config.humanoid then
				stopFly()
				return
			end
			
			Config.humanoid.PlatformStand = true
			
			-- Giữ hướng ổn định bằng BodyGyro
			if flyGyro then
				flyGyro.CFrame = CFrame.new(Config.rootPart.Position, Config.rootPart.Position + Config.Camera.CFrame.LookVector)
			end
			
			local moveDir = Vector3.new(0, 0, 0)
			local camCF = Config.Camera.CFrame
			
			if Config.UserInputService:IsKeyDown(Enum.KeyCode.W) then
				moveDir = moveDir + camCF.LookVector
			end
			if Config.UserInputService:IsKeyDown(Enum.KeyCode.S) then
				moveDir = moveDir - camCF.LookVector
			end
			if Config.UserInputService:IsKeyDown(Enum.KeyCode.A) then
				moveDir = moveDir - camCF.RightVector
			end
			if Config.UserInputService:IsKeyDown(Enum.KeyCode.D) then
				moveDir = moveDir + camCF.RightVector
			end
			if Config.UserInputService:IsKeyDown(Enum.KeyCode.Space) then
				moveDir = moveDir + Vector3.new(0, 1, 0)
			end
			if Config.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
				moveDir = moveDir + Vector3.new(0, -1, 0)
			end
			
			if moveDir.Magnitude > 0 then
				moveDir = moveDir.Unit
			end
			
			local speed = (UI.Options.FlySpeed and UI.Options.FlySpeed.Value) or 80
			flyBV.Velocity = moveDir * speed
		end)
	end
	
	UI.Toggles.FlyEnabled:OnChanged(function()
		if UI.Toggles.FlyEnabled.Value then
			startFly()
		else
			stopFly()
		end
	end)
	
	UI.Options.FlySpeed:OnChanged(function()
		if flyBV and UI.Toggles.FlyEnabled and UI.Toggles.FlyEnabled.Value then
			local speed = (UI.Options.FlySpeed and UI.Options.FlySpeed.Value) or 80
			local currentDir = flyBV.Velocity.Magnitude > 0 and flyBV.Velocity.Unit or Vector3.new()
			flyBV.Velocity = currentDir * speed
		end
	end)
	
	-- Hip Height (walk in air)
	local function applyHipHeight()
		if Config.humanoid and UI.Toggles.HipHeightEnabled and UI.Toggles.HipHeightEnabled.Value then
			local value = (UI.Options.HipHeightValue and UI.Options.HipHeightValue.Value) or Config.humanoid.HipHeight
			Config.humanoid.HipHeight = value
		end
	end
	
	UI.Toggles.HipHeightEnabled:OnChanged(function()
		if UI.Toggles.HipHeightEnabled.Value then
			if Config.humanoid then
				hipHeightOriginal = Config.humanoid.HipHeight
			end
			
			if hipHeightConnection then
				hipHeightConnection:Disconnect()
				hipHeightConnection = nil
			end
			
			applyHipHeight()
			
			-- Giữ HipHeight ổn định khi game cố đổi
			if Config.humanoid then
				if hipHeightConnection then
					hipHeightConnection:Disconnect()
					hipHeightConnection = nil
				end
				hipHeightConnection = Config.humanoid:GetPropertyChangedSignal("HipHeight"):Connect(function()
					if UI.Toggles.HipHeightEnabled and UI.Toggles.HipHeightEnabled.Value then
						applyHipHeight()
					end
				end)
			end
		else
			if hipHeightConnection then
				hipHeightConnection:Disconnect()
				hipHeightConnection = nil
			end
			
			if Config.humanoid and hipHeightOriginal ~= nil then
				Config.humanoid.HipHeight = hipHeightOriginal
			end
		end
	end)
	
	UI.Options.HipHeightValue:OnChanged(function()
		if UI.Toggles.HipHeightEnabled and UI.Toggles.HipHeightEnabled.Value then
			applyHipHeight()
		end
	end)
end

----------------------------------------------------------
-- 🔹 Cleanup
function Movement.cleanup()
	-- Noclip
	if noclipConnection then
		noclipConnection:Disconnect()
		noclipConnection = nil
	end
	if Config.character then
		for _, part in pairs(Config.character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = true
			end
		end
	end
	
	-- Speed Hack
	if wsLoopConnection then
		wsLoopConnection:Disconnect()
		wsLoopConnection = nil
	end
	if wsCharAddedConnection then
		wsCharAddedConnection:Disconnect()
		wsCharAddedConnection = nil
	end
	if Config.humanoid then
		Config.humanoid.WalkSpeed = 16
	end
	
	-- Jump Power
	if jpLoopConnection then
		jpLoopConnection:Disconnect()
		jpLoopConnection = nil
	end
	if jpCharAddedConnection then
		jpCharAddedConnection:Disconnect()
		jpCharAddedConnection = nil
	end
	if Config.humanoid then
		Config.humanoid.JumpPower = 50
	end
	
	-- Fly
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
	if Config.humanoid then
		Config.humanoid.PlatformStand = false
	end
	
	-- HipHeight
	if hipHeightConnection then
		hipHeightConnection:Disconnect()
		hipHeightConnection = nil
	end
	if Config.humanoid and hipHeightOriginal ~= nil then
		Config.humanoid.HipHeight = hipHeightOriginal
	end
end

return Movement

