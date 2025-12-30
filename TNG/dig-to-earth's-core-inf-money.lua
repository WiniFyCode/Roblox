
_G.SpinEnabled = false-- Đổi thành false để tắt

while task.wait(1) do
	if not _G.SpinEnabled then break end

	-- SpinPrizeEvent
	local args = {5}
	game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SpinPrizeEvent"):FireServer(unpack(args))
	task.wait(0.2)

	-- TreasureEvent - Pumpkin
	local args = {"Pumpkin"}
	game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("TreasureEvent"):FireServer(unpack(args))
	task.wait(0.2)

	-- TreasureEvent - LightShard
	local args = {"LightShard"}
	game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("TreasureEvent"):FireServer(unpack(args))
	task.wait(0.2)

	-- TreasureEvent - Chest3
	local args = {"Chest3"}
	game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("TreasureEvent"):FireServer(unpack(args))
end
