-- Remote Logger Script - Call Once
-- Gọi 4 hàm remote 1 lần và log kết quả ra file

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ===== CONFIG =====
local LOG_FILE = "remote_character_pool_log.lua"

-- ===== SERIALIZE FUNCTION =====
local function serialize(value, indentLevel, visited)
    local valueType = typeof(value)
    indentLevel = indentLevel or 0
    visited = visited or {}

    local function makeIndent(level)
        return string.rep("    ", level)
    end

    if valueType == "string" then
        return string.format("%q", value)
    elseif valueType == "number" or valueType == "boolean" or valueType == "nil" then
        return tostring(value)
    elseif valueType == "Vector3" then
        return string.format("Vector3.new(%s, %s, %s)", value.X, value.Y, value.Z)
    elseif valueType == "Vector2" then
        return string.format("Vector2.new(%s, %s)", value.X, value.Y)
    elseif valueType == "CFrame" then
        local components = { value:GetComponents() }
        return "CFrame.new(" .. table.concat(components, ", ") .. ")"
    elseif valueType == "Color3" then
        return string.format("Color3.fromRGB(%d, %d, %d)", value.R * 255, value.G * 255, value.B * 255)
    elseif valueType == "table" then
        if visited[value] then
            return '"<recursive table>"'
        end
        visited[value] = true

        local indent = makeIndent(indentLevel)
        local childIndent = makeIndent(indentLevel + 1)
        local isArray = #value > 0
        local lines = { "{\n" }

        if isArray then
            for _, element in ipairs(value) do
                lines[#lines + 1] = childIndent .. serialize(element, indentLevel + 1, visited) .. ",\n"
            end
        else
            for key, element in pairs(value) do
                local keyRep
                local keyType = typeof(key)
                if keyType == "string" and key:match("^[%a_][%w_]*$") then
                    keyRep = key .. " = "
                else
                    keyRep = "[" .. serialize(key, 0, visited) .. "] = "
                end

                lines[#lines + 1] = childIndent .. keyRep .. serialize(element, indentLevel + 1, visited) .. ",\n"
            end
        end

        lines[#lines + 1] = indent .. "}"
        visited[value] = nil

        return table.concat(lines)
    else
        return '"' .. tostring(valueType) .. '"'
    end
end

-- ===== LOG FUNCTION =====
local function logToFile(content)
    pcall(function()
        appendfile(LOG_FILE, content)
    end)
end

-- ===== INITIALIZE LOG FILE =====
local function initializeLogFile()
    local placeId = game.PlaceId
    local gameName = "Unknown Game"

    pcall(function()
        gameName = game:GetService("MarketplaceService"):GetProductInfo(placeId).Name
    end)

    local header = 
        "-- ======================================\n" ..
        "-- REMOTE LOGGER: characterDic, PoolData, CraftData, TitleData\n" ..
        "-- GAME: " .. gameName .. "\n" ..
        "-- PLACE ID: " .. placeId .. "\n" ..
        "-- SESSION START: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n" ..
        "-- ======================================\n\n"

    if isfile(LOG_FILE) then
        appendfile(LOG_FILE, header)
    else
        writefile(LOG_FILE, header)
    end
end

-- ===== REMOTE CALL FUNCTION =====
local function callRemote(remoteId, remoteName)
    print("📞 Calling " .. remoteName .. " (ID: " .. remoteId .. ")...")
    
    local success, result = pcall(function()
        local remote = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("RemoteFunction")
        local args = {
            remoteId,
            remoteName
        }
        return remote:InvokeServer(unpack(args))
    end)

    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local logEntry = 
        "-- [" .. timestamp .. "] Call to " .. remoteName .. " (ID: " .. remoteId .. ")\n" ..
        "local args = {\n" ..
        "    " .. remoteId .. ",\n" ..
        "    " .. serialize(remoteName) .. "\n" ..
        "}\n"

    if success then
        logEntry = logEntry .. 
            "-- SUCCESS: Result received\n" ..
            "local result = " .. serialize(result) .. "\n" ..
            "-- Raw args: game:GetService('ReplicatedStorage'):WaitForChild('Remote'):WaitForChild('RemoteFunction'):InvokeServer(unpack(args))\n\n"
        
        print("✅ " .. remoteName .. " - SUCCESS!")
        print("📄 Result saved to file")
    else
        logEntry = logEntry .. 
            "-- ERROR: " .. tostring(result) .. "\n" ..
            "-- Raw args: game:GetService('ReplicatedStorage'):WaitForChild('Remote'):WaitForChild('RemoteFunction'):InvokeServer(unpack(args))\n\n"
        
        print("❌ " .. remoteName .. " - ERROR: " .. tostring(result))
    end

    logToFile(logEntry)
    
    return success, result
end

-- ===== MAIN EXECUTION =====
local function main()
    initializeLogFile()
    print("🚀 Remote Logger started!")
    print("📁 Log file: " .. LOG_FILE)
    
    -- Gọi characterDic
    local result1 = callRemote(857483751, "characterDic")
    
    -- Chờ 1 chút rồi gọi PoolData  
    task.wait(1)
    local result2 = callRemote(3949991157, "PoolData")
    
    -- Chờ 1 chút rồi gọi CraftData
    task.wait(1)
    local result3 = callRemote(3949991157, "CraftData")
    
    -- Chờ 1 chút rồi gọi TitleData
    task.wait(1)
    local result4 = callRemote(3949991157, "TitleData")
    
    -- Chờ 1 chút rồi gọi custom remote (2498358147, 1195944203)
    task.wait(1)
    local result5 = callRemote(2498358147, 1195944203)
    
    print("🎉 Logging completed!")
    print("📋 Results:")
    print("   characterDic: " .. (result1 and "✅ Success" or "❌ Error"))
    print("   PoolData: " .. (result2 and "✅ Success" or "❌ Error"))
    print("   CraftData: " .. (result3 and "✅ Success" or "❌ Error"))
    print("   TitleData: " .. (result4 and "✅ Success" or "❌ Error"))
    print("   Custom(2498358147,1195944203): " .. (result5 and "✅ Success" or "❌ Error"))
end

-- Chạy main
main()

-- Export cho global scope nếu cần gọi lại
_G.RemoteLogger = {
    callCharacterDic = function() return callRemote(857483751, "characterDic") end,
    callPoolData = function() return callRemote(3949991157, "PoolData") end,
    callCraftData = function() return callRemote(3949991157, "CraftData") end,
    callTitleData = function() return callRemote(3949991157, "TitleData") end,
    callCustomRemote = function() return callRemote(2498358147, 1195944203) end,
    callAll = function() 
        local r1 = callRemote(857483751, "characterDic")
        task.wait(1)
        local r2 = callRemote(3949991157, "PoolData")
        task.wait(1)
        local r3 = callRemote(3949991157, "CraftData")
        task.wait(1)
        local r4 = callRemote(3949991157, "TitleData")
        task.wait(1)
        local r5 = callRemote(2498358147, 1195944203)
        return r1, r2, r3, r4, r5
    end
}
