
local Players = game:GetService("Players")
local player = Players.LocalPlayer

print("MyGame Loaded!")
print("Player:", player.Name)
print("GameId:", game.GameId)

if game.GameId ~= 10763808155 then
    warn("This menu is for a different game!")
    return
end

local gui = Instance.new("ScreenGui")
gui.Name = "MyGameHub"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(320, 220)
frame.Position = UDim2.fromScale(0.35, 0.3)
frame.BackgroundColor3 = Color3.fromRGB(35, 25, 55)
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundTransparency = 1
title.Text = "MY GAME HUB"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true
title.Parent = frame

local button = Instance.new("TextButton")
button.Name = "ESPButton"
button.Size = UDim2.fromOffset(260, 45)
button.Position = UDim2.fromOffset(30, 75)
button.BackgroundColor3 = Color3.fromRGB(100, 50, 180)
button.TextColor3 = Color3.new(1, 1, 1)
button.TextScaled = true
button.Text = "ESP: OFF"
button.Parent = frame


local Players = game:GetService("Players")
local espEnabled = false
local highlights = {}

local function updateESP()
    for _, highlight in pairs(highlights) do
        highlight:Destroy()
    end
    table.clear(highlights)

    if not espEnabled then
        return
    end

    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= Players.LocalPlayer then
            local character = target.Character
            if character then
                local highlight = Instance.new("Highlight")
                highlight.Name = "MyGameESP"
                highlight.Adornee = character
                highlight.FillColor = Color3.fromRGB(255, 0, 0)
                highlight.FillTransparency = 0.5
                highlight.OutlineColor = Color3.new(1, 1, 1)
                highlight.DepthMode =
                    Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Parent = character
                table.insert(highlights, highlight)
            end
        end
    end
end

button.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    button.Text = espEnabled and "ESP: ON" or "ESP: OFF"
    updateESP()
end)

Players.PlayerAdded:Connect(function(target)
    target.CharacterAdded:Connect(function()
        if espEnabled then
            task.wait(0.5)
            updateESP()
        end
    end)
end)

