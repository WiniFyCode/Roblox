local args = {
	{
		Price = 10000000000,
		Weight = 50,
		Name = "Trashbag",
		Position = vector.create(-12.580909729003906, -59.550716400146484, 321.6824951171875)
	}
}
game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("TrashCollected"):FireServer(unpack(args))


local args = {
	"ChestMythical", -- ChestRare
	"Normal"
}
game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("OpenChest"):InvokeServer(unpack(args))
