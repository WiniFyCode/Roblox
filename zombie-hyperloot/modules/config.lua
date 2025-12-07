--[[
    Config Module - Zombie Hyperloot
    Tất cả biến cấu hình cho script
]]

local Config = {}

----------------------------------------------------------
-- 🔹 Services
Config.Players = game:GetService("Players")
Config.RunService = game:GetService("RunService")
Config.Workspace = game:GetService("Workspace")
Config.UserInputService = game:GetService("UserInputService")
Config.ReplicatedStorage = game:GetService("ReplicatedStorage")
Config.VirtualUser = game:GetService("VirtualUser")
Config.VirtualInputManager = game:GetService("VirtualInputManager")

----------------------------------------------------------
-- 🔹 Game Objects
Config.localPlayer = Config.Players.LocalPlayer
Config.entityFolder = Config.Workspace:WaitForChild("Entity")
Config.fxFolder = Config.Workspace:WaitForChild("FX")
Config.mapModel = Config.Workspace:WaitForChild("Map")

----------------------------------------------------------
-- 🔹 Global Flags
Config.scriptUnloaded = false

----------------------------------------------------------
-- 🔹 ESP Colors
Config.espColorZombie = Color3.fromRGB(180, 110, 255) -- Màu tím cho zombie
Config.espColorChest = Color3.fromRGB(255, 255, 0) -- Màu vàng cho chest
Config.espColorPlayer = Color3.fromRGB(100, 200, 255) -- Màu xanh dương cho player
Config.espColorEnemy = Color3.fromRGB(255, 50, 50) -- Màu đỏ cho enemy

----------------------------------------------------------
-- 🔹 Hitbox
Config.hitboxSize = Vector3.new(4, 4, 4)
Config.hitboxEnabled = false

----------------------------------------------------------
-- 🔹 ESP Toggle States
Config.espZombieEnabled = true
Config.espChestEnabled = true
Config.espPlayerEnabled = true

----------------------------------------------------------
-- 🔹 ESP Zombie Configuration
Config.espZombieBoxes = true
Config.espZombieTracers = false
Config.espZombieNames = true
Config.espZombieHealth = true
Config.espZombieHighlight = true

----------------------------------------------------------
-- 🔹 ESP Player Configuration
Config.espPlayerBoxes = true
Config.espPlayerTracers = false
Config.espPlayerNames = true
Config.espPlayerHealth = true
Config.espPlayerTeamCheck = false
Config.espPlayerHighlight = true

----------------------------------------------------------
-- 🔹 Keybinds
Config.teleportKey = Enum.KeyCode.T -- Mở chest
Config.cameraTeleportKey = Enum.KeyCode.X -- Camera teleport
Config.hipHeightToggleKey = Enum.KeyCode.M -- Toggle Anti-Zombie
Config.noclipCamToggleKey = Enum.KeyCode.N -- Toggle Noclip Cam
Config.unloadKey = Enum.KeyCode.End -- Unload script

----------------------------------------------------------
-- 🔹 Teleport Settings
Config.teleportEnabled = true
Config.cameraTeleportEnabled = true
Config.cameraTeleportActive = false
Config.teleportToLastZombie = false
Config.cameraTeleportStartPosition = nil
Config.cameraTeleportWaveDelay = 5
Config.cameraTargetMode = "Nearest" -- "LowestHealth" hoặc "Nearest"

----------------------------------------------------------
-- 🔹 Camera Offset (cho Camera Teleport)
Config.cameraOffsetX = 0
Config.cameraOffsetY = 10 -- Giống file gốc
Config.cameraOffsetZ = -2

----------------------------------------------------------
-- 🔹 Anti-Zombie (HipHeight)
Config.antiZombieEnabled = false
Config.hipHeightValue = 10
Config.originalHipHeight = nil

----------------------------------------------------------
-- 🔹 NoClip
Config.noClipEnabled = false

----------------------------------------------------------
-- 🔹 Speed
Config.speedEnabled = false
Config.speedValue = 16
Config.originalWalkSpeed = nil

----------------------------------------------------------
-- 🔹 Noclip Cam
Config.noclipCamEnabled = true

----------------------------------------------------------
-- 🔹 Auto BulletBox & Item Magnet
Config.autoBulletBoxEnabled = true

----------------------------------------------------------
-- 🔹 Auto Skill
Config.autoSkillEnabled = true
Config.skill1010Interval = 15
Config.skill1002Interval = 20

----------------------------------------------------------
-- 🔹 TrigerSkill Dupe (GunFire)
Config.trigerSkillDupeEnabled = true
Config.trigerSkillDupeCount = 5

----------------------------------------------------------
-- 🔹 Aimbot Configuration
Config.aimbotEnabled = true
Config.aimbotHoldMouse2 = false -- Giữ chuột phải để aim
Config.aimbotSmoothness = 0.1 -- 0 = instant, 1 = very slow
Config.aimbotPrediction = 0.1 -- Dự đoán chuyển động
Config.aimbotFOVEnabled = true
Config.aimbotFOVRadius = 50
Config.aimbotTargetMode = "Zombies" -- "Zombies", "Players", "All"
Config.aimbotAimPart = "Head" -- "Head", "UpperTorso", "HumanoidRootPart"
Config.savedAimbotState = nil -- Lưu trạng thái aimbot khi camera teleport

----------------------------------------------------------
-- 🔹 Map Selection
Config.selectedWorldId = 1001 -- Exclusion
Config.selectedDifficulty = 1 -- 1 = Normal, 2 = Hard, 3 = Nightmare
Config.selectedMaxCount = 4
Config.selectedFriendOnly = false

----------------------------------------------------------
-- 🔹 Auto Replay
Config.autoReplayEnabled = false

----------------------------------------------------------
-- 🔹 Supply ESP
Config.supplyESPEnabled = true
Config.supplyESPPosition = "Left" -- "Left" hoặc "Right"

----------------------------------------------------------
-- 🔹 Visuals
Config.removeFogEnabled = false
Config.fullbrightEnabled = false
Config.customTimeEnabled = false
Config.customTimeValue = 14 -- 14 = day, 0 = midnight

----------------------------------------------------------
-- 🔹 Effects
Config.removeEffectsEnabled = true -- Tự động xóa effects khi dupe lần đầu

----------------------------------------------------------
-- 🔹 Connection Storage (để cleanup)
Config.connections = {}

return Config
