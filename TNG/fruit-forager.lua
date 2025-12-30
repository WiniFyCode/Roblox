-- Fruit forager

_G.Fruits = {
	common = { pickup = false },
	uncommon = { pickup = false },
	rare = { pickup = true },
	epic = { pickup = true },
	mythic = { pickup = true },
	legendary = { pickup = true },
}

loadstring(game:HttpGet("https://raw.githubusercontent.com/EIonv/RBXScripts/refs/heads/main/FruitForagerNoUI.luau"))()
