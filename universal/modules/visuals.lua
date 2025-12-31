--[[
    Visuals Module - Universal Script
    Tab Visuals - FullBright, NoFog, ESP system
]]

local Visuals = {}
local Config = nil
local UI = nil

-- Variables
local espObjects = {}
local espHighlights = {}
local hasDrawingAPI = false
local highlightUpdateTick = 0
local espRenderConnection = nil

----------------------------------------------------------
-- 🔹 Initialize
function Visuals.init(config, ui)
	Config = config
	UI = ui
end

----------------------------------------------------------
-- 🔹 Check Drawing API
local function checkDrawingAPI()
	if not hasDrawingAPI then
		local ok, obj = pcall(function()
			return Drawing.new("Square")
		end)
		if ok and obj then
			hasDrawingAPI = true
			obj:Remove()
		end
	end
	return hasDrawingAPI
end

----------------------------------------------------------
-- 🔹 ESP Functions
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
				local screenPos, onScreen = Config.Camera:WorldToViewportPoint(corner)
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
		local screenPos, onScreen = Config.Camera:WorldToViewportPoint(worldPos)
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
	if not UI.Toggles.ESPHighlight.Value then return end
	local char = player.Character
	if not char or espHighlights[player] then return end
	
	local isEnemy = UI.Toggles.ESPTeamCheck.Value and player.Team ~= Config.LocalPlayer.Team
	local color = isEnemy and UI.Options.ESPEnemyColor.Value or UI.Options.ESPColor.Value
	
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
	for _, player in ipairs(Config.Players:GetPlayers()) do
		if player ~= Config.LocalPlayer then
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local hasAnyPart = char and char:FindFirstChildWhichIsA("BasePart")
			local isAlive = hum and hum.Health > 0
			
			if char and (isAlive or hasAnyPart) then
				if UI.Toggles.PlayerESP.Value and UI.Toggles.ESPHighlight.Value then
					if UI.Toggles.ESPTeamCheck.Value and player.Team == Config.LocalPlayer.Team then
						removeHighlight(player)
					else
						-- Update color if highlight exists
						if espHighlights[player] then
							local isEnemy = UI.Toggles.ESPTeamCheck.Value and player.Team ~= Config.LocalPlayer.Team
							local color = isEnemy and UI.Options.ESPEnemyColor.Value or UI.Options.ESPColor.Value
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
	if not hasDrawingAPI or not UI.Toggles.PlayerESP.Value then
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
	local isEnemy = UI.Toggles.ESPTeamCheck.Value and player.Team ~= Config.LocalPlayer.Team
	local baseColor = isEnemy and UI.Options.ESPEnemyColor.Value or UI.Options.ESPColor.Value
	local screenCenter = Vector2.new(Config.Camera.ViewportSize.X / 2, Config.Camera.ViewportSize.Y)
	
	local hp = hum and hum.Health or 0
	local maxHp = hum and hum.MaxHealth or 100
	local rawRatio = maxHp > 0 and hp / maxHp or 0
	local ratio = math.min(math.max(rawRatio, 0), 1)
	
	-- 2D Box
	if UI.Toggles.ESPBoxes.Value then
		data.Box.Visible = true
		data.Box.Position = Vector2.new(slimX, minY)
		data.Box.Size = Vector2.new(slimWidth, boxHeight)
		data.Box.Color = baseColor
	else
		data.Box.Visible = false
	end
	
	-- 3D Box (6 body parts - balanced detail vs performance)
	if UI.Toggles.ESP3DBox and UI.Toggles.ESP3DBox.Value then
		ensure3DBoxLines(data) -- Lazy load - chỉ tạo khi bật
		draw3DBoxes(data, player.Character, baseColor)
	elseif data.Box3D then
		hide3DBox(data)
	end
	
	-- Name
	if UI.Toggles.ESPNames.Value then
		data.Name.Visible = true
		data.Name.Text = string.format("%s [%d]", player.Name, math.floor(hp))
		data.Name.Position = Vector2.new(slimX + slimWidth / 2, minY - 18)
		data.Name.Color = baseColor
	else
		data.Name.Visible = false
	end
	
	-- Tracer
	if UI.Toggles.ESPTracers.Value then
		data.Tracer.Visible = true
		data.Tracer.From = screenCenter
		data.Tracer.To = Vector2.new(slimX + slimWidth / 2, maxY)
		data.Tracer.Color = baseColor
	else
		data.Tracer.Visible = false
	end
	
	-- Health Bar
	if UI.Toggles.ESPHealth.Value then
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
		if UI.Toggles.ESPSkeleton and UI.Toggles.ESPSkeleton.Value then
			local char = player.Character
			if char then
				local bones = getSkeletonBones(char)
				local lineIndex = 1
				for _, bone in ipairs(bones) do
					local part0 = char:FindFirstChild(bone[1])
					local part1 = char:FindFirstChild(bone[2])
					if part0 and part1 then
						local p0 = Config.Camera:WorldToViewportPoint(part0.Position)
						local p1 = Config.Camera:WorldToViewportPoint(part1.Position)
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
	if checkDrawingAPI() then
		Config.Players.PlayerRemoving:Connect(function(player)
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
	if not UI.Toggles.PlayerESP.Value then
		for _, data in pairs(espObjects) do
			hideESP(data)
		end
		return
	end
	
	for _, player in ipairs(Config.Players:GetPlayers()) do
		if player ~= Config.LocalPlayer then
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local hasAnyPart = char and char:FindFirstChildWhichIsA("BasePart")
			local isAlive = hum and hum.Health > 0
			
			if char and (isAlive or hasAnyPart) then
				-- Team check - ẩn ESP cho teammate nếu bật
				if UI.Toggles.ESPTeamCheck.Value and player.Team == Config.LocalPlayer.Team then
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

----------------------------------------------------------
-- 🔹 Create Tab
function Visuals.createTab()
	local VisualsGroup = UI.Tabs.Visuals:AddLeftGroupbox("Visuals", "sun")
	
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
	local ESPGroup = UI.Tabs.Visuals:AddRightGroupbox("Player ESP", "eye")
	
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
	UI.Toggles.FullBright:OnChanged(function()
		if UI.Toggles.FullBright.Value then
			Config.Lighting.Brightness = 2
			Config.Lighting.Ambient = Color3.fromRGB(255, 255, 255)
		else
			Config.Lighting.Brightness = 1
			Config.Lighting.Ambient = Color3.fromRGB(128, 128, 128)
		end
	end)
	
	-- No Fog
	UI.Toggles.NoFog:OnChanged(function()
		if UI.Toggles.NoFog.Value then
			Config.Lighting.FogEnd = 9e9
		else
			Config.Lighting.FogEnd = 500
		end
	end)
	
	-- Initialize ESP
	initializeESP()
	
	-- ESP Update Loop
	espRenderConnection = Config.RunService.RenderStepped:Connect(function()
		updateESP()
		
		-- Highlight update mỗi 10 frames (giảm tải)
		highlightUpdateTick = highlightUpdateTick + 1
		if highlightUpdateTick >= 10 then
			highlightUpdateTick = 0
			if UI.Toggles.PlayerESP.Value and UI.Toggles.ESPHighlight.Value then
				updateHighlights()
			end
		end
	end)
	
	-- ESP Toggle handlers
	UI.Toggles.PlayerESP:OnChanged(function()
		if not UI.Toggles.PlayerESP.Value then
			for _, data in pairs(espObjects) do
				hideESP(data)
			end
			for player, _ in pairs(espHighlights) do
				removeHighlight(player)
			end
		end
	end)
	
	UI.Toggles.ESPHighlight:OnChanged(function()
		if not UI.Toggles.ESPHighlight.Value then
			for player, _ in pairs(espHighlights) do
				removeHighlight(player)
			end
		end
	end)
end

----------------------------------------------------------
-- 🔹 Cleanup
function Visuals.cleanup()
	-- Disconnect ESP render loop
	if espRenderConnection then
		espRenderConnection:Disconnect()
		espRenderConnection = nil
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
		for _, player in ipairs(Config.Players:GetPlayers()) do
			if player ~= Config.LocalPlayer and player.Character then
				local highlight = player.Character:FindFirstChild("ESP_Highlight")
				if highlight then
					highlight:Destroy()
				end
			end
		end
	end)
	
	-- Reset Lighting
	Config.Lighting.Brightness = 1
	Config.Lighting.Ambient = Color3.fromRGB(128, 128, 128)
	Config.Lighting.FogEnd = 500
end

return Visuals

