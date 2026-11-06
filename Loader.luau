
-- ABYSALL LOADER
-- ANDRIIVKA + BRONX STREETS
-- One-file Game ID update

local NEW_GAME_ID = 10383565741
local NEW_PLACE_ID = 81748781442029
local OLD_GAME_ID = 10763808155

local BaseUrl =
    "https://raw.githubusercontent.com/" ..
    "altoriadam24-sys/Abysall/" ..
    "refs/heads/main/"

local GameList = {
    [NEW_GAME_ID] = "MyGame",
    [OLD_GAME_ID] = "MyGame"
}

local env = getgenv()

if env.Abysall and env.Abysall.LoadedGameId == game.GameId then
    warn("Abysall already loaded for this game")
    return
end

local function fetch(path)
    return game:HttpGet(BaseUrl .. path)
end

local function loadModule(path)
    local source = fetch(path)
    local compiled, err = loadstring(source)

    if not compiled then
        error("Failed to compile " .. path .. ": " .. tostring(err))
    end

    return compiled()
end

env.Abysall = {
    Legit = true,
    LoadedGameId = game.GameId
}

local Abysall = env.Abysall

-- Load shared components
Abysall.Environment = loadModule(
    "Components/Environment.luau"
)

Abysall.ESPLibrary = loadModule(
    "Components/ESP.luau"
)

local function CloneReference(object)
    if Abysall.Environment
        and Abysall.Environment.cloneref then

        return Abysall.Environment.cloneref(object)
    end

    return object
end

local Services = setmetatable({}, {
    __index = function(self, name)
        return CloneReference(game:GetService(name))
    end
})

-- Preserve existing user data
local environment = Abysall.Environment

if environment.writefile
    and environment.readfile
    and environment.isfile then

    local filePath = "Abysall/UserData.json"

    if not environment.isfile(filePath) then
        local data = {
            TotalExecutions = 0,
            UILibrary = "Obsidian"
        }

        environment.writefile(
            filePath,
            Services.HttpService:JSONEncode(data)
        )
    end

    local success, decoded = pcall(function()
        return Services.HttpService:JSONDecode(
            environment.readfile(filePath)
        )
    end)

    if not success or type(decoded) ~= "table" then
        decoded = {}
    end

    decoded.TotalExecutions =
        (tonumber(decoded.TotalExecutions) or 0) + 1

    decoded.UILibrary =
        decoded.UILibrary or "Obsidian"

    Abysall.TotalExecutions =
        decoded.TotalExecutions

    Abysall.UILibrary =
        decoded.UILibrary

    environment.writefile(
        filePath,
        Services.HttpService:JSONEncode(decoded)
    )
end

-- Load interface and analytics
Abysall.Interface = loadModule(
    "Components/Interface.luau"
)

Abysall.Analytics = loadModule(
    "Components/Analytics.luau"
)

-- Game identification
local currentGameId = game.GameId
local currentPlaceId = game.PlaceId

print("========== ABYSALL ==========")
print("Game ID:", currentGameId)
print("Place ID:", currentPlaceId)
print("=============================")

local currentGame = GameList[currentGameId]

if currentGame then
    local path =
        "Games/" .. currentGame .. "/Loader.luau"

    local source = fetch(path)

    -- Adapt the existing MyGame ID guard
    -- when running the new Andriivka game.
    if currentGameId == NEW_GAME_ID then
        source = source:gsub(
            "game.GameId ~= " .. OLD_GAME_ID,
            "game.GameId ~= " .. NEW_GAME_ID
        )

        print("Andriivka game detected")
    end

    local compiled, err = loadstring(source)

    if not compiled then
        error("Game loader error: " .. tostring(err))
    end

    compiled()
else
    loadModule("Games/Universal/Loader.luau")
end

print("Abysall loader finished")
