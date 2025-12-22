--[[
    Universal Script - Main Entry Point
    Modular version - Load từng modules để giảm lag
]]

----------------------------------------------------------
-- 🔹 Hybrid Loading Function (GitHub only)
local function loadModule(moduleName)
	local githubPath = "https://raw.githubusercontent.com/WiniFyCode/Roblox/refs/heads/main/universal/modules/" .. moduleName .. ".lua"
	return loadstring(game:HttpGet(githubPath))()
end

----------------------------------------------------------
-- 🔹 Load Modules
local Config, UI, Movement, Combat, Visuals, Teleport, Server, Misc

-- 1. Load Config (Services, Variables, Helpers)
Config = loadModule("config")

-- 2. Load UI (Library, Window, Tabs)
UI = loadModule("ui")
UI.init(Config)
UI.setup()

-- 3. Load Movement (Tab Main)
Movement = loadModule("movement")
Movement.init(Config, UI)
Movement.createTab()

-- 4. Load Combat (Tab Combat)
Combat = loadModule("combat")
Combat.init(Config, UI)
Combat.createTab()

-- 5. Load Visuals (Tab Visuals)
Visuals = loadModule("visuals")
Visuals.init(Config, UI)
Visuals.createTab()

-- 6. Load Teleport (Tab Teleport)
Teleport = loadModule("teleport")
Teleport.init(Config, UI)
Teleport.createTab()

-- 7. Load Server (Tab Server)
Server = loadModule("server")
Server.init(Config, UI)
Server.createTab()

-- 8. Load Misc (Tab Misc)
Misc = loadModule("misc")
Misc.init(Config, UI)
Misc.createTab()

----------------------------------------------------------
-- 🔹 Cleanup on Unload
if UI and UI.Library then
	UI.Library:OnUnload(function()
		-- Cleanup Movement
		if Movement and Movement.cleanup then
			Movement.cleanup()
		end
		
		-- Cleanup Combat
		if Combat and Combat.cleanup then
			Combat.cleanup()
		end
		
		-- Cleanup Visuals
		if Visuals and Visuals.cleanup then
			Visuals.cleanup()
		end
		
		-- Cleanup Teleport
		if Teleport and Teleport.cleanup then
			Teleport.cleanup()
		end
		
		-- Cleanup Server
		if Server and Server.cleanup then
			Server.cleanup()
		end
		
		-- Cleanup Misc
		if Misc and Misc.cleanup then
			Misc.cleanup()
		end
		
		-- Cleanup UI (handled by Library:Unload())
		if UI and UI.cleanup then
			UI.cleanup()
		end
	end)
end

