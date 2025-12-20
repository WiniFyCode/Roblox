-- WiniFy Main Loader
-- Automatically loads the correct script based on game PlaceId

local targetGameId = 77595602575472 -- Zombie HyperLoot game ID

if game.PlaceId == targetGameId then
	-- Load Zombie HyperLoot script
	loadstring(game:HttpGet('https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/zombie-hyperloot/main.lua'))()
else
	-- Load Universal script for all other games
	loadstring(game:HttpGet('https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/universal/universal.lua'))()
end

