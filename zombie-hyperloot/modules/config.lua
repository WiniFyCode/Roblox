--[[
    Config Module - Zombie Hyperloot
    Tất cả biến cấu hình cho script
]]

local Config = {}

-- Services
Config.Players = game:GetService("Players")
Config.RunService = game:GetService("RunService")
Config.Workspace = game:GetService("Workspace")
Config.UserInputService = game:GetService("UserInputService")

Config.localPlayer = Config.Players.LocalPlayer
Config.entityFolder = Config.Workspace:WaitForChild("Entity")
Config.fxFolder = Config.Workspace:WaitForChild("FX")
Config.mapModel = Config.Workspace:WaitForChild("Map")

-- Global unload flag
Config.scriptUnloaded = false

-- ESP Colors
Config.espColorZombie = Color3.fromRGB(180, 110, 255) -- Màu tím cho zombie
Config.espColorChest = Color3.fromRGB(255, 255, 0) -- Màu vàng cho chest
Config.espColorPlayer = Color3.fromRGB(100, 200, 255) -- Màu xanh dương cho player
Config.espColorEnemy = Color3.fromRGB(255, 50, 50) -- Màu đỏ cho enemy

-- Hitbox
Config.hitboxSize = Vector3.new(4, 4, 4)
Config.hitboxEnabled = false

-- ESP Toggle States
Config.espZombieEnabled = true
Config.espChestEnabled = true
Config.espPlayerEnabled = true

-- ESP Zombie Configuration
Config.espZombieBoxes = true
Config.espZombieTracers = false
Config.espZombieNames = true
Config.espZombieHealth = true

-- ESP Player Configuration
Config.espPlayerBoxes = true
Config.espPlayerTracers = false
Config.espPlayerNames = true
Config.espPlayerHealth = true
Config.espPlayerTeamCheck = false

-- Teleport Keys
Config.teleportKey = Enum.KeyCode.T
Config.cameraTeleportKey = Enum.KeyCode.X
Config.hipHeightToggleKey = Enum.KeyCode.M

-- Teleport Settings
Config.teleportEnabled = true
Config.cameraTeleportEnabled = true
Config.cameraTeleportActive = false
Config.teleportToLastZombie = false
Config.cameraTeleportStartPosition = nil
Config.cameraTeleportWaveDelay = 5
Config.cameraTargetMode = "Nearest"


-- Camera Offset
Config.cameraOffsetX = 0
Config.cameraOffsetY = 5
Config.cameraOffsetZ = -2

-- Anti-Zombie (HipHeight)
Config.antiZombieEnabled = false
Config.hipHeightValue = 10
Config.originalHipHeight = nil

-- NoClip & Speed
Config.noClipEnabled = false
Config.speedEnabled = false
Config.speedValue = 16

-- Noclip Cam
Config.noclipCamEnabled = true

-- Auto BulletBox
Config.autoBulletBoxEnabled = true

-- Auto Skill
Config.autoSkillEnabled = true
Config.skill1010Interval = 15
Config.skill1002Interval = 20

-- TrigerSkill Dupe
Config.trigerSkillDupeEnabled = true
Config.trigerSkillDupeCount = 5

-- Aimbot Configuration
Config.aimbotEnabled = true
Config.aimbotHoldMouse2 = false
Config.aimbotSmoothness = 0.1
Config.aimbotPrediction = 0.1
Config.aimbotFOVEnabled = true
Config.aimbotFOVRadius = 50
Config.aimbotTargetMode = "Zombies"
Config.aimbotAimPart = "Head"
Config.savedAimbotState = nil

-- Map Selection
Config.selectedWorldId = 1001
Config.selectedDifficulty = 1
Config.selectedMaxCount = 4
Config.selectedFriendOnly = false

-- Auto Replay
Config.autoReplayEnabled = false

return Config
