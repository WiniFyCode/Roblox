local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local collectiblesFolder = Workspace:WaitForChild("Collectibles")

local tpEnabled = true
local visitedNames = {}
local totalCount = #collectiblesFolder:GetChildren()

-- 🧮 GUI hiển thị đếm
local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local counterLabel = Instance.new("TextLabel")
counterLabel.Size = UDim2.new(0, 250, 0, 40)
counterLabel.Position = UDim2.new(0.5, -125, 0, 20)
counterLabel.BackgroundTransparency = 0.3
counterLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
counterLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
counterLabel.TextScaled = true
counterLabel.Font = Enum.Font.GothamBold
counterLabel.Text = "💎 0 / " .. totalCount
counterLabel.Parent = screenGui

local function updateCounter()
	local visitedCount = 0
	for _, v in pairs(visitedNames) do
		if v then visitedCount += 1 end
	end
	counterLabel.Text = string.format("💎 %d / %d", visitedCount, totalCount)
end

-- Toggle bằng T
UserInputService.InputBegan:Connect(function(input, gp)
	if input.KeyCode == Enum.KeyCode.T then
		tpEnabled = not tpEnabled
		print("Auto TP:", tpEnabled and "ON" or "OFF")
	end
end)

-- ESP
local function createESP(part, name)
	if not part or part:FindFirstChild("ESP_Highlight") then return end

	local highlight = Instance.new("Highlight")
	highlight.Name = "ESP_Highlight"
	highlight.Adornee = part
	highlight.FillColor = Color3.fromRGB(0, 255, 0)
	highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
	highlight.FillTransparency = 0.5
	highlight.Parent = part

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ESP_Label"
	billboard.Size = UDim2.new(0, 120, 0, 30)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = part

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.fromRGB(255, 255, 0)
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.Text = "💎 " .. name
	text.Parent = billboard
end

-- Xóa ESP
local function removeESP(part)
	if not part then return end
	local highlight = part:FindFirstChild("ESP_Highlight")
	if highlight then highlight:Destroy() end
	local billboard = part:FindFirstChild("ESP_Label")
	if billboard then billboard:Destroy() end
end

-- Teleport
local function teleportTo(part)
	local character = localPlayer.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if hrp and part then
		hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
	end
end

-- Handle collectible
local function handleCollectible(collectible)
	if not collectible:IsA("Model") then return end
	local part = collectible:FindFirstChild("DetectionPart")
	if not part then return end

	if not visitedNames[collectible.Name] then
		createESP(part, collectible.Name)
	end

	if visitedNames[collectible.Name] then return end
	if not tpEnabled then return end

	print("Teleporting to:", collectible.Name)
	teleportTo(part)
	visitedNames[collectible.Name] = true
	removeESP(part)
	updateCounter()
	task.wait(0.8)
end

-- Xử lý có sẵn
for _, collectible in pairs(collectiblesFolder:GetChildren()) do
	handleCollectible(collectible)
end
updateCounter()

-- Khi spawn mới
collectiblesFolder.ChildAdded:Connect(function(collectible)
	task.wait(0.5)
	totalCount = #collectiblesFolder:GetChildren()
	handleCollectible(collectible)
	updateCounter()
end)

collectiblesFolder.ChildRemoved:Connect(function()
	task.wait(0.2)
	totalCount = #collectiblesFolder:GetChildren()
	updateCounter()
end)

print("✅ ESP + Auto TP Collectibles đang chạy (RightShift để bật/tắt)")
