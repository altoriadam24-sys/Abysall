
-- ABYSALL MAIN LOADER V2
-- Supports Bronx Streets and Andriivka
-- Keep the same Execute script

local BASE_URL =
    "https://raw.githubusercontent.com/" ..
    "altoriadam24-sys/Abysall/" ..
    "refs/heads/main/"

local GAMES = {
    [10763808155] = "MyGame",
    [10383565741] = "MyGame"
}

local ANDRIIVKA_ID = 10383565741
local BRONX_ID = 10763808155

local env = getgenv()
local currentGameId = game.GameId
local currentPlaceId = game.PlaceId

local function fetch(path)
    local success, result = pcall(function()
        return game:HttpGet(BASE_URL .. path)
    end)

    if not success then
        error(
            "[ABYSALL] Download failed: " ..
            path .. " | " .. tostring(result)
        )
    end

    return result
end

local function execute(source, name)
    local compiled, err = loadstring(source)

    if not compiled then
        error(
            "[ABYSALL] Compile error in " ..
            name .. ": " .. tostring(err)
        )
    end

    return compiled()
end

local function loadFile(path)
    return execute(fetch(path), path)
end

-- Cleanup the previous GUI
if _G.BronxHubCleanup then
    pcall(_G.BronxHubCleanup)
end

if _G.AndriivkaHubCleanup then
    pcall(_G.AndriivkaHubCleanup)
end

-- Initialize Abysall
env.Abysall = {
    Legit = true,
    LoadedGameId = currentGameId
}

local Abysall = env.Abysall

-- Required libraries
Abysall.Environment = loadFile(
    "Components/Environment.luau"
)

Abysall.ESPLibrary = loadFile(
    "Components/ESP.luau"
)

local function cloneReference(object)
    local environment = Abysall.Environment

    if environment and environment.cloneref then
        return environment.cloneref(object)
    end

    return object
end

local Services = setmetatable({}, {
    __index = function(_, name)
        return cloneReference(game:GetService(name))
    end
})

-- User settings
local environment = Abysall.Environment

if environment
    and environment.writefile
    and environment.readfile
    and environment.isfile then

    local path = "Abysall/UserData.json"

    if not environment.isfile(path) then
        if environment.makefolder then
            pcall(function()
                environment.makefolder("Abysall")
            end)
        end

        local initial = {
            TotalExecutions = 0,
            UILibrary = "Obsidian"
        }

        pcall(function()
            environment.writefile(
                path,
                Services.HttpService:JSONEncode(initial)
            )
        end)
    end

    local ok, data = pcall(function()
        local raw = environment.readfile(path)
        return Services.HttpService:JSONDecode(raw)
    end)

    if not ok or type(data) ~= "table" then
        data = {}
    end

    data.TotalExecutions =
        (tonumber(data.TotalExecutions) or 0) + 1

    data.UILibrary =
        data.UILibrary or "Obsidian"

    Abysall.TotalExecutions = data.TotalExecutions
    Abysall.UILibrary = data.UILibrary

    pcall(function()
        environment.writefile(
            path,
            Services.HttpService:JSONEncode(data)
        )
    end)
end

-- Shared interface components
Abysall.Interface = loadFile(
    "Components/Interface.luau"
)

Abysall.Analytics = loadFile(
    "Components/Analytics.luau"
)

print("================================")
print("ABYSALL LOADER V2")
print("Game ID:", currentGameId)
print("Place ID:", currentPlaceId)
print("================================")

local gameFolder = GAMES[currentGameId]

if gameFolder then
    local path =
        "Games/" .. gameFolder .. "/Loader.luau"

    local source = fetch(path)

    if currentGameId == ANDRIIVKA_ID then

        -- Adapt the old Game ID guard
        source = source:gsub(
            "game%.GameId%s*~=%s*" .. BRONX_ID,
            "game.GameId ~= " .. ANDRIIVKA_ID
        )

        -- Update displayed game identity
        source = source:gsub(
            "BRONX STREETS HUB",
            "ANDRIIVKA HUB"
        )

        source = source:gsub(
            "BRONX STREETS",
            "ANDRIIVKA"
        )

        source = source:gsub(
            '"BRONX"',
            '"ANDRIIVKA"'
        )

        source = source:gsub(
            '"STREETS"',
            '"MILITARY"'
        )

        -- Avoid discarding the right mouse
        -- input when Roblox marks it processed
        source = source:gsub(
            "if not processed and matchesKey%(input%) then",
            "if (not processed or " ..
            "input.UserInputType == " ..
            "Enum.UserInputType.MouseButton2) " ..
            "and matchesKey(input) then"
        )

        print(
            "[ABYSALL] Andriivka configuration loaded"
        )
    else
        print(
            "[ABYSALL] Bronx Streets configuration loaded"
        )
    end

    execute(source, path)
else
    print("[ABYSALL] Loading Universal menu")
    loadFile("Games/Universal/Loader.luau")
end

print("[ABYSALL] Loading complete")
