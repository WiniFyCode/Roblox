-- Auto Collect Cash + Auto Lock Base

-- ========== GLOBAL VARIABLES ==========
-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local event = ReplicatedStorage:WaitForChild("ncxyzero_bridgenet2-fork@1.1.5"):WaitForChild("dataRemoteEvent")
local player = Players.LocalPlayer

-- Settings
local collectInterval = 90 -- seconds
local lockInterval = 3 -- seconds

-- States
local lockBaseEnabled = true
local lockCountdown = 3

-- GUI Elements
local screenGui
local frame
local title
local toggleButton
local countdownLabel

-- ========== GUI CREATION ==========
screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoControlGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 380, 0, 80)
frame.Position = UDim2.new(1, -390, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0
frame.Parent = screenGui

title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundTransparency = 1
title.Text = "💰 Auto Collect + 🔒 Auto Lock"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16
title.Parent = frame

toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 180, 0, 25)
toggleButton.Position = UDim2.new(0, 5, 1, -30)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
toggleButton.Text = "🔒 Auto Lock: ON (3s)"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 14
toggleButton.Parent = frame

countdownLabel = Instance.new("TextLabel")
countdownLabel.Size = UDim2.new(0, 190, 0, 25)
countdownLabel.Position = UDim2.new(0, 190, 1, -30)
countdownLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
countdownLabel.BackgroundTransparency = 0.5
countdownLabel.Text = "⏱️ Đếm ngược: 90s"
countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
countdownLabel.Font = Enum.Font.SourceSansBold
countdownLabel.TextSize = 14
countdownLabel.Parent = frame

-- ========== FUNCTIONS ==========
-- Hàm lock base ngay lập tức
local function lockBaseNow()
	local base = workspace:FindFirstChild("Base")
	if base and base:FindFirstChild("Lasers") then
		local button = base.Lasers:FindFirstChild("LockgateButton") and base.Lasers.LockgateButton:FindFirstChild("Button")
		if button then
			local args = { { button, "\t" } }
			event:FireServer(unpack(args))
		end
	end
end

-- Hàm collect cash từ tất cả ClaimButton
local function collectAllCash()
	for _, base in pairs(workspace:GetChildren()) do
		if base:FindFirstChild("Buttons") and base.Buttons:FindFirstChild("Plots") then
			for _, claim in pairs(base.Buttons.Plots:GetChildren()) do
				if claim.Name == "ClaimButton" then
					local gui = claim:FindFirstChild("CollectCashBGUI")
					if gui and gui:FindFirstChild("Main") and gui.Main:FindFirstChild("Money") then
						local moneyText = gui.Main.Money.Text
						if moneyText ~= "" and moneyText ~= "$0" then
							local button = claim:FindFirstChild("Button")
							if button then
								local args = { { button, "\a" } }
								event:FireServer(unpack(args))
								task.wait(0.2)
							end
						end
					end
				end
			end
		end
	end
end

-- ========== EVENT HANDLERS ==========
-- Xử lý sự kiện click toggle
toggleButton.MouseButton1Click:Connect(function()
	lockBaseEnabled = not lockBaseEnabled
	if lockBaseEnabled then
		toggleButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
		toggleButton.Text = "🔒 Auto Lock: ON (3s)"
		-- Lock ngay lập tức khi bật
		lockBaseNow()
		lockCountdown = lockInterval -- Reset countdown
	else
		toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		toggleButton.Text = "🔓 Auto Lock: OFF"
	end
end)

-- ========== MAIN LOOPS ==========
-- Auto collect cash với đếm ngược
task.spawn(function()
	while true do
		-- Chạy collect cash
		collectAllCash()
		
		-- Đếm ngược collectInterval giây
		for i = collectInterval, 1, -1 do
			countdownLabel.Text = "⏱️ Thu tiền tiếp theo sau: " .. i .. "s"
			task.wait(1)
		end
	end
end)

-- Auto lock base với countdown
task.spawn(function()
	while true do
		if lockBaseEnabled then
			-- Đếm ngược cho lock base
			for i = lockInterval, 1, -1 do
				if not lockBaseEnabled then break end
				lockCountdown = i
				toggleButton.Text = "🔒 Auto Lock: ON (" .. i .. "s)"
				task.wait(1)
			end
			
			-- Lock base nếu vẫn enabled
			if lockBaseEnabled then
				lockBaseNow()
				toggleButton.Text = "🔒 Auto Lock: ON (" .. lockInterval .. "s)"
			end
		else
			task.wait(1)
		end
	end
end)

-- ========== INITIALIZATION ==========
print("🟢 Auto Collect + Auto Lock Script đã khởi động thành công.")