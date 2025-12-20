-- WiniFy Main Loader
-- Automatically loads the correct script based on game PlaceId

local zombieHyperLootGames = {
	77595602575472,  -- Zombie HyperLoot game ID
	100822312246972, -- Zombie HyperLoot game ID (alternative)
}

-- Check if current game is a Zombie HyperLoot game
local isZombieHyperLoot = false
for _, gameId in ipairs(zombieHyperLootGames) do
	if game.PlaceId == gameId then
		isZombieHyperLoot = true
		break
	end
end

if isZombieHyperLoot then
	-- Load Zombie HyperLoot script
	loadstring(game:HttpGet('https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/main.lua'))()
else
	-- Load Universal script for all other games
	loadstring(game:HttpGet('https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/universal/universal.lua'))()
end

