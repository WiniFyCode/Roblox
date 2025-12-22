--[[
    Teleport Module - Universal Script
    Tab Teleport - Teleport to player, Checkpoints
]]

local Teleport = {}
local Config = nil
local UI = nil

-- Variables
local checkpoints = {}
local checkpointNames = {}
local checkpointFolder = nil
local checkpointDropdown = nil
local checkpointCountLabel = nil
local checkpointFileName = nil
local clickTPConnection = nil

----------------------------------------------------------
-- 🔹 Initialize
function Teleport.init(config, ui)
	Config = config
	UI = ui
	checkpointFileName = "WiniFy_Checkpoints_" .. tostring(game.PlaceId) .. ".json"
end

----------------------------------------------------------
-- 🔹 Checkpoint Functions
local function createCheckpointVisual(cf, name, color)
	if not checkpointFolder or not checkpointFolder.Parent then
		checkpointFolder = Config.Workspace:FindFirstChild("WiniFy_Checkpoints") or Instance.new("Folder")
		checkpointFolder.Name = "WiniFy_Checkpoints"
		checkpointFolder.Parent = Config.Workspace
	end
	
	local checkpointColor = color or (UI.Options.CheckpointColor and UI.Options.CheckpointColor.Value) or Color3.fromRGB(0, 255, 255)
	
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
		
		local json = Config.HttpService:JSONEncode(dataToSave)
		writefile(checkpointFileName, json)
		return true
	end)
	
	if success then
		if showNotification ~= false then
			UI.Library:Notify({
				Title = "Checkpoint",
				Description = "Saved " .. tostring(#checkpoints) .. " checkpoint(s)",
				Time = 3,
			})
		end
		return true
	else
		if showNotification ~= false then
			UI.Library:Notify({
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
		
		local data = Config.HttpService:JSONDecode(fileContent)
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
			UI.Library:Notify({
				Title = "Checkpoint",
				Description = "Loaded " .. tostring(#checkpoints) .. " checkpoint(s)",
				Time = 3,
			})
		end
		return true
	else
		if showNotification ~= false and isfile(checkpointFileName) then
			UI.Library:Notify({
				Title = "Checkpoint",
				Description = "Failed to load checkpoints",
				Time = 3,
			})
		end
		return false
	end
end

local function addCheckpoint(name)
	-- Update character trước khi kiểm tra
	Config.getCharacter()
	
	if not Config.rootPart then
		UI.Library:Notify({
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
		UI.Library:Notify({
			Title = "Checkpoint",
			Description = "Checkpoint name already exists: " .. name,
			Time = 3,
		})
		return
	end
	
	local cf = Config.rootPart.CFrame
	local color = UI.Options.CheckpointColor and UI.Options.CheckpointColor.Value or Color3.fromRGB(0, 255, 255)
	local visual = createCheckpointVisual(cf, name, color)
	
	table.insert(checkpoints, { name = name, cf = cf, visual = visual, color = color })
	table.insert(checkpointNames, name)
	refreshCheckpointDropdown()
	
	-- Auto save (silent)
	saveCheckpointsToFile(false)
	
	UI.Library:Notify({
		Title = "Checkpoint",
		Description = "Saved checkpoint: " .. name,
		Time = 3,
	})
end

----------------------------------------------------------
-- 🔹 Create Tab
function Teleport.createTab()
	local TeleportGroup = UI.Tabs.Teleport:AddLeftGroupbox("Teleport", "map-pin")
	
	-- Teleport tới player khác
	TeleportGroup:AddDropdown("TeleportPlayer", {
		SpecialType = "Player",
		ExcludeLocalPlayer = true,
		Text = "Teleport To Player",
	})
	
	TeleportGroup:AddButton({
		Text = "Teleport To Player",
		Func = function()
			-- Update character trước khi kiểm tra
			Config.getCharacter()
			
			local targetPlayer = UI.Options.TeleportPlayer.Value
			if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
				if Config.rootPart then
					Config.rootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
					UI.Library:Notify({
						Title = "Teleported",
						Description = "Teleported to " .. targetPlayer.Name,
						Time = 3,
					})
				else
					UI.Library:Notify({
						Title = "Teleport",
						Description = "Could not find your character (rootPart = nil)",
						Time = 3,
					})
				end
			else
				UI.Library:Notify({
					Title = "Teleport",
					Description = "Không tìm thấy nhân vật của player",
					Time = 3,
				})
			end
		end,
	})
	
	TeleportGroup:AddDivider()
	
	-- Click TP
	TeleportGroup:AddToggle("ClickTPEnabled", {
		Text = "Click TP",
		Default = false,
		Tooltip = "Click chuột phải vào vị trí trên màn hình để teleport",
	})
	
	UI.Toggles.ClickTPEnabled:OnChanged(function()
		if UI.Toggles.ClickTPEnabled.Value then
			if clickTPConnection then
				clickTPConnection:Disconnect()
			end
			
			clickTPConnection = Config.UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if gameProcessed then return end
				
				-- Chỉ cần click chuột phải
				if input.UserInputType == Enum.UserInputType.MouseButton2 then
					Config.getCharacter()
					if not Config.rootPart then return end
					
					local mouse = Config.LocalPlayer:GetMouse()
					local ray = Config.Camera:ScreenPointToRay(mouse.X, mouse.Y)
					
					local rayParams = RaycastParams.new()
					rayParams.FilterType = Enum.RaycastFilterType.Exclude
					rayParams.FilterDescendantsInstances = {Config.character}
					
					local result = Config.Workspace:Raycast(ray.Origin, ray.Direction * 10000, rayParams)
					if result then
						local newCFrame = CFrame.new(result.Position)
						Config.rootPart.CFrame = newCFrame
						UI.Library:Notify({
							Title = "Click TP",
							Description = "Teleported!",
							Time = 2,
						})
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
	
	-- Checkpoint Group (Right)
	local CheckpointGroup = UI.Tabs.Teleport:AddRightGroupbox("Checkpoint", "bookmark")
	
	-- Folder chứa tất cả checkpoint trong Workspace
	checkpointFolder = Config.Workspace:FindFirstChild("WiniFy_Checkpoints")
	if not checkpointFolder then
		checkpointFolder = Instance.new("Folder")
		checkpointFolder.Name = "WiniFy_Checkpoints"
		checkpointFolder.Parent = Config.Workspace
	end
	
	CheckpointGroup:AddLabel("Checkpoint Color"):AddColorPicker("CheckpointColor", {
		Default = Color3.fromRGB(0, 255, 255),
		Title = "Checkpoint Color",
	})
	
	-- Update color for all checkpoints when color changes
	UI.Options.CheckpointColor:OnChanged(function(newColor)
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
			local name = UI.Options.CheckpointName and UI.Options.CheckpointName.Value or ""
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
	
	CheckpointGroup:AddButton({
		Text = "Teleport To Checkpoint",
		Func = function()
			-- Update character trước khi kiểm tra
			Config.getCharacter()
			
			if not Config.rootPart then
				UI.Library:Notify({
					Title = "Checkpoint",
					Description = "Could not find your character (rootPart = nil)",
					Time = 3,
				})
				return
			end
			
			local selected = UI.Options.CheckpointList and UI.Options.CheckpointList.Value or nil
			if not selected or selected == "" then
				UI.Library:Notify({
					Title = "Checkpoint",
					Description = "You haven't selected any checkpoint",
					Time = 3,
				})
				return
			end
			
			local index = findCheckpointIndexByName(selected)
			if not index then
				UI.Library:Notify({
					Title = "Checkpoint",
					Description = "Checkpoint does not exist (possibly just deleted)",
					Time = 3,
				})
				return
			end
			
			local cp = checkpoints[index]
			if cp and cp.cf then
				Config.rootPart.CFrame = cp.cf
				UI.Library:Notify({
					Title = "Checkpoint",
					Description = "Teleported to: " .. cp.name,
					Time = 3,
				})
			else
				UI.Library:Notify({
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
			local selected = UI.Options.CheckpointList and UI.Options.CheckpointList.Value or nil
			if not selected or selected == "" then
				UI.Library:Notify({
					Title = "Checkpoint",
					Description = "You haven't selected any checkpoint to delete",
					Time = 3,
				})
				return
			end
			
			local index = findCheckpointIndexByName(selected)
			if not index then
				UI.Library:Notify({
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
			
			UI.Library:Notify({
				Title = "Checkpoint",
				Description = "Deleted checkpoint: " .. selected,
				Time = 3,
			})
		end,
	})
	
	CheckpointGroup:AddButton({
		Text = "Rename Checkpoint",
		Func = function()
			local selected = UI.Options.CheckpointList and UI.Options.CheckpointList.Value or nil
			if not selected or selected == "" then
				UI.Library:Notify({
					Title = "Checkpoint",
					Description = "You haven't selected any checkpoint to rename",
					Time = 3,
				})
				return
			end
			
			local index = findCheckpointIndexByName(selected)
			if not index then
				UI.Library:Notify({
					Title = "Checkpoint",
					Description = "Checkpoint does not exist",
					Time = 3,
				})
				return
			end
			
			local newName = UI.Options.CheckpointName and UI.Options.CheckpointName.Value or ""
			if not newName or newName == "" then
				UI.Library:Notify({
					Title = "Checkpoint",
					Description = "Please enter a new name",
					Time = 3,
				})
				return
			end
			
			-- Check for duplicate name
			if findCheckpointIndexByName(newName) and newName ~= selected then
				UI.Library:Notify({
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
			
			UI.Library:Notify({
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
				UI.Library:Notify({
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
			
			UI.Library:Notify({
				Title = "Checkpoint",
				Description = "Deleted " .. tostring(count) .. " checkpoint(s)",
				Time = 3,
			})
		end,
		Risky = true,
	})
	
	-- Auto load checkpoints on startup
	task.wait(1) -- Wait a bit for character to load
	loadCheckpointsFromFile(false) -- Silent load
end

----------------------------------------------------------
-- 🔹 Cleanup
function Teleport.cleanup()
	-- Cleanup Click TP
	if clickTPConnection then
		clickTPConnection:Disconnect()
		clickTPConnection = nil
	end
	
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
end

return Teleport

